// AI / Steen 2025
// Fused Multiply-Add for 8x8 Matrix of 8-bit values with Memory Interface
// Verilog-2001 compliant - uses flat packed arrays instead of unpacked arrays
// Reads matrix B from memory, uses input matrix A, accumulates to C
// Triggered by start_fma signal

/* 
For full SET/GET commands and testbench:


for simple FMA only testing:
iverilog -o ualink_fma.vvp ualink_fma.v
vvp ualink_fma.vvp
gtkwave.exe matrix_fma_8x8.vcd

*/
module matrix_fma_8x8 #(
    parameter WIDTH = 8,
    parameter ACCUMULATOR_WIDTH = 24
)(
    input  wire                                 clk,
    input  wire                                 rst_n,
    
    // Control
    input  wire                                 start_fma,
    input wire [7:0]                            addr_base,
    output reg                                  done_fma,

    // Matrix B memory interface (read-only)
    output reg  [7:0]                           addr_b,
    input  wire [63:0]                          dout_b,  // out from memory
 //   output  reg [63:0]                         din_b,
    output  reg                                 we_b

);

    // Matrix A input (64 elements, 8 bits each = 512 bits total)
    // Layout: mat_a[511:504] = A[0][0], mat_a[503:496] = A[0][1], etc.
    //Keep static identity for now.
    reg signed [511:0]                  mat_a = 512'h0123456789ABCDEF00000000000000000;

    // Matrix C accumulator input (64 elements, 24 bits each = 1536 bits)
    //keep zero for now
    reg signed [1535:0]                 mat_c = 1536'h00000000000000000000000000000000000000000000;
    
    // Matrix output (64 elements, 24 bits each = 1536 bits)
    //only writing out first 64B=512bits for now
    reg  signed [1535:0]                 mat_out;
    reg [63:0] din_b = 64'h0000000000000000; 
    // FSM states
    localparam IDLE         = 3'd0;
    localparam LOAD_B       = 3'd1;
    localparam MULTIPLY     = 3'd2;
    localparam ACCUMULATE   = 3'd3;
    localparam DONE         = 3'd4;
    
    reg [2:0] state, next_state;
    reg [3:0] load_counter;     // Count 0-7 for loading 8 rows
    reg [7:0] addr_b_base = 8'h20;

    // Matrix B storage (64 elements × 8 bits = 512 bits)
    reg signed [511:0] mat_b;
    
    // Pipeline registers
    // Stage 1: products (64 output elements × 8 products each × 16 bits = 8192 bits)
    reg signed [8191:0] products;
    
    // Stage 2: dot products (64 elements × 19 bits = 1216 bits)
    reg signed [1215:0] dot_products;
    reg signed [1535:0] mat_c_pipe;
    
    reg valid_multiply;
    reg valid_accumulate;
    
    integer i, j, k;
    integer idx_a, idx_b, idx_c, idx_prod, idx_dot;
    
    // Helper function to access matrix A element A[row][col]
    function signed [WIDTH-1:0] get_mat_a;
        input [2:0] row;
        input [2:0] col;
        integer offset;
        begin
            offset = (row * 8 + col) * WIDTH;
            get_mat_a = mat_a[offset +: WIDTH];
        end
    endfunction
    
    // Helper function to access matrix B element B[row][col]
    function signed [WIDTH-1:0] get_mat_b;
        input [2:0] row;
        input [2:0] col;
        integer offset;
        begin
            offset = (row * 8 + col) * WIDTH;
            get_mat_b = mat_b[offset +: WIDTH];
        end
    endfunction
    
    // Helper function to set matrix B element B[row][col]
    task set_mat_b;
        input [2:0] row;
        input [2:0] col;
        input signed [WIDTH-1:0] value;
        integer offset;
        begin
            offset = (row * 8 + col) * WIDTH;
            mat_b[offset +: WIDTH] = value;
        end
    endtask

    // Helper function to output matrix out element mat_out[row][col]
    task set_mat_outmem;
        input [2:0] row;
        input [2:0] col;
        input signed [WIDTH-1:0] value;
        integer offset;
        begin
            offset = (row * 8 + col) * WIDTH;
            din_b = mat_out[offset +: WIDTH];
        end
    endtask
    
    // Helper function to access matrix C element C[row][col]
    function signed [ACCUMULATOR_WIDTH-1:0] get_mat_c;
        input [2:0] row;
        input [2:0] col;
        integer offset;
        begin
            offset = (row * 8 + col) * ACCUMULATOR_WIDTH;
            get_mat_c = mat_c[offset +: ACCUMULATOR_WIDTH];
        end
    endfunction
    
    // Helper function to access product[i][j][k]
    function signed [15:0] get_product;
        input [2:0] i;
        input [2:0] j;
        input [2:0] k;
        integer offset;
        begin
            offset = ((i * 64) + (j * 8) + k) * 16;
            get_product = products[offset +: 16];
        end
    endfunction
    
    // Helper task to set product[i][j][k]
    task set_product;
        input [2:0] i;
        input [2:0] j;
        input [2:0] k;
        input signed [15:0] value;
        integer offset;
        begin
            offset = ((i * 64) + (j * 8) + k) * 16;
            products[offset +: 16] = value;
        end
    endtask
    
    // Helper function to access dot_product[i][j]
    function signed [18:0] get_dot_product;
        input [2:0] i;
        input [2:0] j;
        integer offset;
        begin
            offset = (i * 8 + j) * 19;
            get_dot_product = dot_products[offset +: 19];
        end
    endfunction
    
    // Helper task to set dot_product[i][j]
    task set_dot_product;
        input [2:0] i;
        input [2:0] j;
        input signed [18:0] value;
        integer offset;
        begin
            offset = (i * 8 + j) * 19;
            dot_products[offset +: 19] = value;
        end
    endtask
    
    // Helper task to set mat_out[i][j]
    task set_mat_out;
        input [2:0] i;
        input [2:0] j;
        input signed [ACCUMULATOR_WIDTH-1:0] value;
        integer offset;
        begin
            offset = (i * 8 + j) * ACCUMULATOR_WIDTH;
            mat_out[offset +: ACCUMULATOR_WIDTH] = value;
        end
    endtask
    
    // FSM - State transitions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // FSM - Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start_fma)  begin
                    next_state = LOAD_B;
                end
            end
            
            LOAD_B: begin
                if (load_counter == 7)
                    next_state = MULTIPLY;
            end
            
            MULTIPLY: begin
                next_state = ACCUMULATE;
            end
            
            ACCUMULATE: begin
                    next_state = DONE;
            end
            
            DONE: begin 
             if (load_counter == 7) 
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Memory address generation and matrix B loading
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_b <= 8'd0;
            load_counter <= 4'd0;
            mat_b <= 512'd0;
            we_b <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    we_b <= 1'b0;
                    if (start_fma) begin
                        addr_b_base <= addr_base;
                        addr_b <= addr_b_base;
                        load_counter <= 4'd0;
                    end
                end
                
                MULTIPLY: begin
                    we_b <= 1'b0;
                        load_counter <= 4'd0;
                end
                
                LOAD_B: begin
                    we_b <= 1'b0;
                    // Load one row per cycle (8 elements from 64-bit memory)
                    case (load_counter)
                        4'd0: begin
                            mat_b[0*64 + 0*8 +: 8] <= dout_b[7:0];
                            mat_b[0*64 + 1*8 +: 8] <= dout_b[15:8];
                            mat_b[0*64 + 2*8 +: 8] <= dout_b[23:16];
                            mat_b[0*64 + 3*8 +: 8] <= dout_b[31:24];
                            mat_b[0*64 + 4*8 +: 8] <= dout_b[39:32];
                            mat_b[0*64 + 5*8 +: 8] <= dout_b[47:40];
                            mat_b[0*64 + 6*8 +: 8] <= dout_b[55:48];
                            mat_b[0*64 + 7*8 +: 8] <= dout_b[63:56];
                        end
                        4'd1: begin
                            mat_b[1*64 + 0*8 +: 8] <= dout_b[7:0];
                            mat_b[1*64 + 1*8 +: 8] <= dout_b[15:8];
                            mat_b[1*64 + 2*8 +: 8] <= dout_b[23:16];
                            mat_b[1*64 + 3*8 +: 8] <= dout_b[31:24];
                            mat_b[1*64 + 4*8 +: 8] <= dout_b[39:32];
                            mat_b[1*64 + 5*8 +: 8] <= dout_b[47:40];
                            mat_b[1*64 + 6*8 +: 8] <= dout_b[55:48];
                            mat_b[1*64 + 7*8 +: 8] <= dout_b[63:56];
                        end
                        4'd2: begin
                            mat_b[2*64 + 0*8 +: 8] <= dout_b[7:0];
                            mat_b[2*64 + 1*8 +: 8] <= dout_b[15:8];
                            mat_b[2*64 + 2*8 +: 8] <= dout_b[23:16];
                            mat_b[2*64 + 3*8 +: 8] <= dout_b[31:24];
                            mat_b[2*64 + 4*8 +: 8] <= dout_b[39:32];
                            mat_b[2*64 + 5*8 +: 8] <= dout_b[47:40];
                            mat_b[2*64 + 6*8 +: 8] <= dout_b[55:48];
                            mat_b[2*64 + 7*8 +: 8] <= dout_b[63:56];
                        end
                        4'd3: begin
                            mat_b[3*64 + 0*8 +: 8] <= dout_b[7:0];
                            mat_b[3*64 + 1*8 +: 8] <= dout_b[15:8];
                            mat_b[3*64 + 2*8 +: 8] <= dout_b[23:16];
                            mat_b[3*64 + 3*8 +: 8] <= dout_b[31:24];
                            mat_b[3*64 + 4*8 +: 8] <= dout_b[39:32];
                            mat_b[3*64 + 5*8 +: 8] <= dout_b[47:40];
                            mat_b[3*64 + 6*8 +: 8] <= dout_b[55:48];
                            mat_b[3*64 + 7*8 +: 8] <= dout_b[63:56];
                        end
                        4'd4: begin
                            mat_b[4*64 + 0*8 +: 8] <= dout_b[7:0];
                            mat_b[4*64 + 1*8 +: 8] <= dout_b[15:8];
                            mat_b[4*64 + 2*8 +: 8] <= dout_b[23:16];
                            mat_b[4*64 + 3*8 +: 8] <= dout_b[31:24];
                            mat_b[4*64 + 4*8 +: 8] <= dout_b[39:32];
                            mat_b[4*64 + 5*8 +: 8] <= dout_b[47:40];
                            mat_b[4*64 + 6*8 +: 8] <= dout_b[55:48];
                            mat_b[4*64 + 7*8 +: 8] <= dout_b[63:56];
                        end
                        4'd5: begin
                            mat_b[5*64 + 0*8 +: 8] <= dout_b[7:0];
                            mat_b[5*64 + 1*8 +: 8] <= dout_b[15:8];
                            mat_b[5*64 + 2*8 +: 8] <= dout_b[23:16];
                            mat_b[5*64 + 3*8 +: 8] <= dout_b[31:24];
                            mat_b[5*64 + 4*8 +: 8] <= dout_b[39:32];
                            mat_b[5*64 + 5*8 +: 8] <= dout_b[47:40];
                            mat_b[5*64 + 6*8 +: 8] <= dout_b[55:48];
                            mat_b[5*64 + 7*8 +: 8] <= dout_b[63:56];
                        end
                        4'd6: begin
                            mat_b[6*64 + 0*8 +: 8] <= dout_b[7:0];
                            mat_b[6*64 + 1*8 +: 8] <= dout_b[15:8];
                            mat_b[6*64 + 2*8 +: 8] <= dout_b[23:16];
                            mat_b[6*64 + 3*8 +: 8] <= dout_b[31:24];
                            mat_b[6*64 + 4*8 +: 8] <= dout_b[39:32];
                            mat_b[6*64 + 5*8 +: 8] <= dout_b[47:40];
                            mat_b[6*64 + 6*8 +: 8] <= dout_b[55:48];
                            mat_b[6*64 + 7*8 +: 8] <= dout_b[63:56];
                        end
                        4'd7: begin
                            mat_b[7*64 + 0*8 +: 8] <= dout_b[7:0];
                            mat_b[7*64 + 1*8 +: 8] <= dout_b[15:8];
                            mat_b[7*64 + 2*8 +: 8] <= dout_b[23:16];
                            mat_b[7*64 + 3*8 +: 8] <= dout_b[31:24];
                            mat_b[7*64 + 4*8 +: 8] <= dout_b[39:32];
                            mat_b[7*64 + 5*8 +: 8] <= dout_b[47:40];
                            mat_b[7*64 + 6*8 +: 8] <= dout_b[55:48];
                            mat_b[7*64 + 7*8 +: 8] <= dout_b[63:56];
                        end
                    endcase
                    
                    if (load_counter < 7) begin
                        load_counter <= load_counter + 1;
                        addr_b <= addr_b + 1;
                    end
                end

                ACCUMULATE: begin
                    we_b <= 1'b0;
                end

                DONE: begin
                    we_b <= 1'b1;

                    case (load_counter)
                        4'd0: begin
                            din_b[7:0]   = mat_out[(0*8 + 0)*24 +: 8];
                            din_b[15:8]  = mat_out[(0*8 + 1)*24 +: 8];
                            din_b[23:16] = mat_out[(0*8 + 2)*24 +: 8];
                            din_b[31:24] = mat_out[(0*8 + 3)*24 +: 8];
                            din_b[39:32] = mat_out[(0*8 + 4)*24 +: 8];
                            din_b[47:40] = mat_out[(0*8 + 5)*24 +: 8];
                            din_b[55:48] = mat_out[(0*8 + 6)*24 +: 8];
                            din_b[63:56] = mat_out[(0*8 + 7)*24 +: 8];
                        end
                        4'd1: begin
                            din_b[7:0]   = mat_out[(1*8 + 0)*24 +: 8];
                            din_b[15:8]  = mat_out[(1*8 + 1)*24 +: 8];
                            din_b[23:16] = mat_out[(1*8 + 2)*24 +: 8];
                            din_b[31:24] = mat_out[(1*8 + 3)*24 +: 8];
                            din_b[39:32] = mat_out[(1*8 + 4)*24 +: 8];
                            din_b[47:40] = mat_out[(1*8 + 5)*24 +: 8];
                            din_b[55:48] = mat_out[(1*8 + 6)*24 +: 8];
                            din_b[63:56] = mat_out[(1*8 + 7)*24 +: 8];
                        end
                        4'd2: begin
                            din_b[7:0]   = mat_out[(2*8 + 0)*24 +: 8];
                            din_b[15:8]  = mat_out[(2*8 + 1)*24 +: 8];
                            din_b[23:16] = mat_out[(2*8 + 2)*24 +: 8];
                            din_b[31:24] = mat_out[(2*8 + 3)*24 +: 8];
                            din_b[39:32] = mat_out[(2*8 + 4)*24 +: 8];
                            din_b[47:40] = mat_out[(2*8 + 5)*24 +: 8];
                            din_b[55:48] = mat_out[(2*8 + 6)*24 +: 8];
                            din_b[63:56] = mat_out[(2*8 + 7)*24 +: 8];
                        end
                        4'd3: begin
                            din_b[7:0]   = mat_out[(3*8 + 0)*24 +: 8];
                            din_b[15:8]  = mat_out[(3*8 + 1)*24 +: 8];
                            din_b[23:16] = mat_out[(3*8 + 2)*24 +: 8];
                            din_b[31:24] = mat_out[(3*8 + 3)*24 +: 8];
                            din_b[39:32] = mat_out[(3*8 + 4)*24 +: 8];
                            din_b[47:40] = mat_out[(3*8 + 5)*24 +: 8];
                            din_b[55:48] = mat_out[(3*8 + 6)*24 +: 8];
                            din_b[63:56] = mat_out[(3*8 + 7)*24 +: 8];
                        end
                        4'd4: begin
                            din_b[7:0]   = mat_out[(4*8 + 0)*24 +: 8];
                            din_b[15:8]  = mat_out[(4*8 + 1)*24 +: 8];
                            din_b[23:16] = mat_out[(4*8 + 2)*24 +: 8];
                            din_b[31:24] = mat_out[(4*8 + 3)*24 +: 8];
                            din_b[39:32] = mat_out[(4*8 + 4)*24 +: 8];
                            din_b[47:40] = mat_out[(4*8 + 5)*24 +: 8];
                            din_b[55:48] = mat_out[(4*8 + 6)*24 +: 8];
                            din_b[63:56] = mat_out[(4*8 + 7)*24 +: 8];
                        end
                        4'd5: begin
                            din_b[7:0]   = mat_out[(5*8 + 0)*24 +: 8];
                            din_b[15:8]  = mat_out[(5*8 + 1)*24 +: 8];
                            din_b[23:16] = mat_out[(5*8 + 2)*24 +: 8];
                            din_b[31:24] = mat_out[(5*8 + 3)*24 +: 8];
                            din_b[39:32] = mat_out[(5*8 + 4)*24 +: 8];
                            din_b[47:40] = mat_out[(5*8 + 5)*24 +: 8];
                            din_b[55:48] = mat_out[(5*8 + 6)*24 +: 8];
                            din_b[63:56] = mat_out[(5*8 + 7)*24 +: 8];
                        end
                        4'd6: begin
                            din_b[7:0]   = mat_out[(6*8 + 0)*24 +: 8];
                            din_b[15:8]  = mat_out[(6*8 + 1)*24 +: 8];
                            din_b[23:16] = mat_out[(6*8 + 2)*24 +: 8];
                            din_b[31:24] = mat_out[(6*8 + 3)*24 +: 8];
                            din_b[39:32] = mat_out[(6*8 + 4)*24 +: 8];
                            din_b[47:40] = mat_out[(6*8 + 5)*24 +: 8];
                            din_b[55:48] = mat_out[(6*8 + 6)*24 +: 8];
                            din_b[63:56] = mat_out[(6*8 + 7)*24 +: 8];
                        end
                        4'd7: begin
                            din_b[7:0]   = mat_out[(7*8 + 0)*24 +: 8];
                            din_b[15:8]  = mat_out[(7*8 + 1)*24 +: 8];
                            din_b[23:16] = mat_out[(7*8 + 2)*24 +: 8];
                            din_b[31:24] = mat_out[(7*8 + 3)*24 +: 8];
                            din_b[39:32] = mat_out[(7*8 + 4)*24 +: 8];
                            din_b[47:40] = mat_out[(7*8 + 5)*24 +: 8];
                            din_b[55:48] = mat_out[(7*8 + 6)*24 +: 8];
                            din_b[63:56] = mat_out[(7*8 + 7)*24 +: 8];
                        end
                    endcase

                    if (load_counter < 7) begin
                        load_counter <= load_counter + 1;
                        addr_b <= addr_b + 1;
                    end
                end
                
                default: begin
                    we_b <= 1'b0;
                end
            endcase
        end
    end
    
    // Pipeline Stage 1: Multiply
    generate
        genvar gi, gj, gk;
        for (gi = 0; gi < 8; gi = gi + 1) begin : gen_mult_i
            for (gj = 0; gj < 8; gj = gj + 1) begin : gen_mult_j
                for (gk = 0; gk < 8; gk = gk + 1) begin : gen_mult_k
                    always @(posedge clk or negedge rst_n) begin
                        if (!rst_n) begin
                            products[((gi * 64) + (gj * 8) + gk) * 16 +: 16] <= 16'd0;
                        end else if (state == MULTIPLY) begin
                            products[((gi * 64) + (gj * 8) + gk) * 16 +: 16] <= 
                                mat_a[((gi * 8 + gk) * 8) +: 8] * mat_b[((gk * 8 + gj) * 8) +: 8];
                        end
                    end
                end
            end
        end
    endgenerate
    
    // Pipeline Stage 2: Sum products (dot product) and propagate C
    generate
        genvar gi_acc, gj_acc;
        for (gi_acc = 0; gi_acc < 8; gi_acc = gi_acc + 1) begin : gen_acc_i
            for (gj_acc = 0; gj_acc < 8; gj_acc = gj_acc + 1) begin : gen_acc_j
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        dot_products[(gi_acc * 8 + gj_acc) * 19 +: 19] <= 19'd0;
                    end else if (valid_multiply) begin
                        dot_products[(gi_acc * 8 + gj_acc) * 19 +: 19] <= 
                            products[((gi_acc * 64) + (gj_acc * 8) + 0) * 16 +: 16] +
                            products[((gi_acc * 64) + (gj_acc * 8) + 1) * 16 +: 16] +
                            products[((gi_acc * 64) + (gj_acc * 8) + 2) * 16 +: 16] +
                            products[((gi_acc * 64) + (gj_acc * 8) + 3) * 16 +: 16] +
                            products[((gi_acc * 64) + (gj_acc * 8) + 4) * 16 +: 16] +
                            products[((gi_acc * 64) + (gj_acc * 8) + 5) * 16 +: 16] +
                            products[((gi_acc * 64) + (gj_acc * 8) + 6) * 16 +: 16] +
                            products[((gi_acc * 64) + (gj_acc * 8) + 7) * 16 +: 16];
                    end
                end
            end
        end
    endgenerate
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_accumulate <= 1'b0;
            mat_c_pipe <= 1536'd0;
        end else begin
            valid_accumulate <= valid_multiply;
            if (valid_multiply) begin
                mat_c_pipe <= mat_c;
            end
        end
    end
    
    // Pipeline Stage 3: Add to accumulator and output
    generate
        genvar gi_out, gj_out;
        for (gi_out = 0; gi_out < 8; gi_out = gi_out + 1) begin : gen_out_i
            for (gj_out = 0; gj_out < 8; gj_out = gj_out + 1) begin : gen_out_j
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        mat_out[((gi_out * 8 + gj_out) * 24) +: 24] <= 24'd0;
                    end else if (valid_accumulate) begin
                        mat_out[((gi_out * 8 + gj_out) * 24) +: 24] <= 
                            dot_products[(gi_out * 8 + gj_out) * 19 +: 19] + 
                            mat_c_pipe[((gi_out * 8 + gj_out) * 24) +: 24];
                    end
                end
            end
        end
    endgenerate
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_fma <= 1'b0;
        end else begin
            done_fma <= (state == DONE);
        end
    end

endmodule

// Testbench perhaps split to separate file, but included here for completeness
// two fma ops, 1=identity, 2=2x3+10
module matrix_fma_8x8_tb;
    parameter WIDTH = 8;
    parameter ACCUMULATOR_WIDTH = 24;
    
    reg clk, rst_n, start_fma;
    wire done_fma;
    
    reg signed [511:0] mat_a;
    reg [7:0] addr_base;
    reg [63:0] dout_b;
   // reg [63:0] din_b;
    reg signed [1535:0] mat_c;
    wire signed [1535:0] mat_out;
    
    // Simple memory model for matrix B
    reg [63:0] memory [0:255];
    
    // Memory read logic
    always @(*) begin
        dout_b = memory[addr_base];
    end
    
    // Instantiate DUT
    matrix_fma_8x8 #(
        .WIDTH(WIDTH),
        .ACCUMULATOR_WIDTH(ACCUMULATOR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_fma(start_fma),
        .done_fma(done_fma),
        .addr_base(addr_base),
        .dout_b(dout_b),
     //   .din_b(din_b),
        .we_b(we_b)
        );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    integer i, j;
    integer offset;
    
    // Helper task to set mat_a[row][col]
    task set_mat_a;
        input [2:0] row;
        input [2:0] col;
        input signed [WIDTH-1:0] value;
        begin
            offset = (row * 8 + col) * WIDTH;
            mat_a[offset +: WIDTH] = value;
        end
    endtask
    
    // Helper task to set mat_c[row][col]
    task set_mat_c;
        input [2:0] row;
        input [2:0] col;
        input signed [ACCUMULATOR_WIDTH-1:0] value;
        begin
            offset = (row * 8 + col) * ACCUMULATOR_WIDTH;
            mat_c[offset +: ACCUMULATOR_WIDTH] = value;
        end
    endtask
    
    // Helper function to get mat_out[row][col]
    function signed [ACCUMULATOR_WIDTH-1:0] get_mat_out;
        input [2:0] row;
        input [2:0] col;
        begin
            offset = (row * 8 + col) * ACCUMULATOR_WIDTH;
            get_mat_out = mat_out[offset +: ACCUMULATOR_WIDTH];
        end
    endfunction
    
    initial begin
        $dumpfile("matrix_fma_8x8.vcd");
        $dumpvars(0, matrix_fma_8x8_tb);
        
        // Initialize
        rst_n = 0;
        start_fma = 0;
        addr_base = 8'h20;
        mat_a = 512'd0;
        mat_c = 1536'd0;
        
        // Initialize memory with zeros
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = 64'h0123456789ABCDEF;
        end
        
        #20 rst_n = 1;
        #20;
        
        // Test 1: Simple identity-like test
        $display("\nTest 1: A=identity, B=5s, C=0");
        
        // Matrix A = identity
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                if (i == j)
                    set_mat_a(i[2:0], j[2:0], 8'd1);
                else
                    set_mat_a(i[2:0], j[2:0], 8'd0);
                set_mat_c(i[2:0], j[2:0], 24'd0);
            end
        end
        
        // Matrix B = all 5s (stored in memory)
        for (i = 0; i < 8; i = i + 1) begin
            memory[i] = 64'h0505050505050505;
        end
        
        // Start operation
        start_fma = 1;
        #10 start_fma = 0;
        
        // Wait for completion
        wait(done_fma);
        #10;
        
        $display("Result[0][0] = %d (expected 5)", get_mat_out(3'd0, 3'd0));
        $display("Result[1][1] = %d (expected 5)", get_mat_out(3'd1, 3'd1));
        $display("Result[0][1] = %d (expected 0)", get_mat_out(3'd0, 3'd1));
        
        // Test 2: 2x2 multiplication with accumulator
        #250;
        $display("\nTest 2: A=2s, B=3s, C=10");
        
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                set_mat_a(i[2:0], j[2:0], 8'd2);
                set_mat_c(i[2:0], j[2:0], 24'd10);
            end
        end
        
        for (i = 0; i < 8; i = i + 1) begin
            memory[i] = 64'h0303030303030303;
        end
        
        start_fma = 1;
        #10 start_fma = 0;
        
        wait(done_fma);
        #10;
        
        // Expected: sum of (2*3) for 8 elements = 48, plus accumulator 10 = 58
        $display("Result[0][0] = %d (expected 58 = 2*3*8 + 10)", get_mat_out(3'd0, 3'd0));
        $display("Result[3][5] = %d (expected 58)", get_mat_out(3'd3, 3'd5));
        
        #100;
        $display("\nTests completed");
        $finish;
    end
    
    // Timeout
    initial begin
        #10000;
        $display("Timeout!");
        $finish;
    end

endmodule
