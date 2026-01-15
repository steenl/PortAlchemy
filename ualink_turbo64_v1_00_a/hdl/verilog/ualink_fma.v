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
    output  wire                                we_b

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
        end else begin
            case (state)
                IDLE: begin
                    if (start_fma) begin
                        addr_b_base <= addr_base;
                        addr_b <= addr_b_base;
                        load_counter <= 4'd0;
                    end
                end
                
                MULTIPLY: begin
                        load_counter <= 4'd0;
                end
                
                LOAD_B: begin
                    // Load one row per cycle (8 elements from 64-bit memory)
                    for (j = 0; j < 8; j = j + 1) begin
                        set_mat_b(load_counter[2:0], j[2:0], dout_b[j*8 +: 8]);
                    end
                    
                    if (load_counter < 7) begin
                        load_counter <= load_counter + 1;
                        addr_b <= addr_b + 1;
                    end
                end

                DONE: begin

                    if (load_counter < 7) begin
                        load_counter <= load_counter + 1;
                        addr_b <= addr_b + 1;
                    end
                   //Write one row per cycle (8 elements from 64-bit memory)
                    for (j = 0; j < 8; j = j + 1) begin
                        set_mat_outmem(load_counter[2:0], j[2:0], din_b[j*8 +: 8]);
                    end
                end
                
                DONE: begin
                    load_counter <= 4'd0;
                end
            endcase
        end
    end
    
    // Pipeline Stage 1: Multiply
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_multiply <= 1'b0;
            products <= 8192'd0;
        end else begin
            valid_multiply <= (state == MULTIPLY);
            
            if (state == MULTIPLY) begin
                // Compute all products: A[i][k] * B[k][j]
                for (i = 0; i < 8; i = i + 1) begin
                    for (j = 0; j < 8; j = j + 1) begin
                        for (k = 0; k < 8; k = k + 1) begin
                            set_product(i[2:0], j[2:0], k[2:0], 
                                       get_mat_a(i[2:0], k[2:0]) * get_mat_b(k[2:0], j[2:0]));
                        end
                    end
                end
            end
        end
    end
    
    // Pipeline Stage 2: Sum products (dot product) and propagate C
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_accumulate <= 1'b0;
            dot_products <= 1216'd0;
            mat_c_pipe <= 1536'd0;
        end else begin
            valid_accumulate <= valid_multiply;
            
            if (valid_multiply) begin
                for (i = 0; i < 8; i = i + 1) begin
                    for (j = 0; j < 8; j = j + 1) begin
                        // Sum all 8 products for this output element
                        set_dot_product(i[2:0], j[2:0],
                            get_product(i[2:0], j[2:0], 3'd0) + get_product(i[2:0], j[2:0], 3'd1) +
                            get_product(i[2:0], j[2:0], 3'd2) + get_product(i[2:0], j[2:0], 3'd3) +
                            get_product(i[2:0], j[2:0], 3'd4) + get_product(i[2:0], j[2:0], 3'd5) +
                            get_product(i[2:0], j[2:0], 3'd6) + get_product(i[2:0], j[2:0], 3'd7)
                        );
                    end
                end
                
                // Delay mat_c to match pipeline
                mat_c_pipe <= mat_c;
            end
        end
    end
    
    // Pipeline Stage 3: Add to accumulator and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_fma <= 1'b0;
            mat_out <= 1536'd0;
        end else begin
            done_fma <= (state == DONE);
            
            if (valid_accumulate) begin
                for (i = 0; i < 8; i = i + 1) begin
                    for (j = 0; j < 8; j = j + 1) begin
                        idx_c = (i * 8 + j) * ACCUMULATOR_WIDTH;
                        set_mat_out(i[2:0], j[2:0], 
                                   get_dot_product(i[2:0], j[2:0]) + mat_c_pipe[idx_c +: ACCUMULATOR_WIDTH]);
                    end
                end
            end
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
