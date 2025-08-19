// -----------------------------------------------------------------------------
// ualink_axis_turbo64.v
// Generate and check basic packets
// Steen Larsen 2025
// -----------------------------------------------------------------------------

module ualink_axis_turbo64 #(
    parameter C_BASEADDR           = 32'h00000000,
    parameter C_HIGHADDR           = 32'h00000002,
    parameter C_M_AXIS_DATA_WIDTH  = 64,  // max 256bit supported
    parameter C_S_AXIS_DATA_WIDTH  = 64,  // max 256bit supported
    parameter C_S_AXIS_TUSER_WIDTH = 128,
    parameter C_M_AXIS_TUSER_WIDTH = 128,
    parameter C_GEN_PKT_SIZE       = 16,  // in words
    parameter C_CHECK_PKT_SIZE     = 16,  // in words
    parameter C_IFG_SIZE           = 5,   // in words
    parameter C_S_AXI_ADDR_WIDTH   = 32,
    parameter C_S_AXI_DATA_WIDTH   = 32
)(
    input  wire                          aclk,
    input  wire                          aresetn,
    // AXI streaming data interface
    output reg  [C_M_AXIS_DATA_WIDTH-1:0] m_axis_tdata,
    output reg  [C_M_AXIS_DATA_WIDTH/8-1:0] m_axis_tstrb,
    output reg  [C_M_AXIS_TUSER_WIDTH-1:0] m_axis_tuser,
    output reg                           m_axis_tvalid,
    input  wire                          m_axis_tready,
    output reg                           m_axis_tlast,
    input  wire [C_S_AXIS_DATA_WIDTH-1:0] s_axis_tdata,
    input  wire [C_S_AXIS_DATA_WIDTH/8-1:0] s_axis_tstrb,
    input  wire [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser,
    input  wire                          s_axis_tvalid,
    output wire                          s_axis_tready,
    input  wire                          s_axis_tlast,
    // AXI lite control/status interface
    input  wire                          S_AXI_ACLK,
    input  wire                          S_AXI_ARESETN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire                          S_AXI_AWVALID,
    output wire                          S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                          S_AXI_WVALID,
    output wire                          S_AXI_WREADY,
    output wire [1:0]                    S_AXI_BRESP,
    output wire                          S_AXI_BVALID,
    input  wire                          S_AXI_BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire                          S_AXI_ARVALID,
    output wire                          S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0]                    S_AXI_RRESP,
    output wire                          S_AXI_RVALID,
    input  wire                          S_AXI_RREADY,
    // LEDs and debug outputs
    output reg                           LED03,
    output reg                           CS_M_AXIS_TDATA0,
    output reg                           CS_M_AXIS_TDATA1,
    output reg                           CS_M_AXIS_TDATA2,
    output reg                           CS_M_AXIS_TDATA3,
    output reg                           CS_M_AXIS_TDATA4,
    output reg                           CS_M_AXIS_TDATA5,
    output reg                           CS_M_AXIS_TDATA6,
    output reg                           CS_M_AXIS_TDATA7,
    output reg                           CS_M_AXIS_TDATA8,
    output reg                           CS_M_AXIS_TDATA9,
    output reg                           CS_M_AXIS_TDATA10,
    output reg                           CS_M_AXIS_TDATA11,
    output reg                           CS_M_AXIS_TDATA12,
    output reg                           CS_M_AXIS_TDATA13,
    output reg                           CS_M_AXIS_TDATA14,
    output reg                           CS_M_AXIS_TDATA15,
    output reg                           CS_M_AXIS_TDATA16,
    output reg                           CS_M_AXIS_TDATA17,
    output reg                           CS_M_AXIS_TDATA18,
    output reg                           CS_M_AXIS_TDATA19,
    output reg                           CS_M_AXIS_TDATA20,
    output reg                           CS_M_AXIS_TDATA21,
    output reg                           CS_M_AXIS_TDATA22,
    output reg                           CS_M_AXIS_TDATA23,
    output reg                           CS_M_AXIS_TDATA24,
    output reg                           CS_M_AXIS_TDATA25,
    output reg                           CS_M_AXIS_TDATA26,
    output reg                           CS_M_AXIS_TDATA27,
    output reg                           CS_M_AXIS_TDATA28,
    output reg                           CS_M_AXIS_TDATA29,
    output reg                           CS_M_AXIS_TDATA30,
    output reg                           CS_M_AXIS_TDATA31,
    output reg                           CS_M_AXIS_TDATA32,
    output reg                           CS_M_AXIS_TDATA33,
    output reg                           CS_M_AXIS_TDATA34,
    output reg                           CS_M_AXIS_TDATA35,
    output reg                           CS_M_AXIS_TDATA36,
    output reg                           CS_M_AXIS_TDATA37,
    output reg                           CS_M_AXIS_TDATA38,
    output reg                           CS_M_AXIS_TDATA39,
    output reg                           CS_M_AXIS_TDATA40,
    output reg                           CS_M_AXIS_TDATA41,
    output reg                           CS_M_AXIS_TDATA42,
    output reg                           CS_M_AXIS_TDATA43,
    output reg                           CS_M_AXIS_TDATA44,
    output reg                           CS_M_AXIS_TDATA45,
    output reg                           CS_M_AXIS_TDATA46,
    output reg                           CS_M_AXIS_TDATA47,
    output reg                           CS_M_AXIS_TDATA48,
    output reg                           CS_M_AXIS_TDATA49,
    output reg                           CS_M_AXIS_TDATA50,
    output reg                           CS_M_AXIS_TDATA51,
    output reg                           CS_M_AXIS_TDATA52,
    output reg                           CS_M_AXIS_TDATA53,
    output reg                           CS_M_AXIS_TDATA54,
    output reg                           CS_M_AXIS_TDATA55,
    output reg                           CS_M_AXIS_TDATA56,
    output reg                           CS_M_AXIS_TDATA57,
    output reg                           CS_M_AXIS_TDATA58,
    output reg                           CS_M_AXIS_TDATA59,
    output reg                           CS_M_AXIS_TDATA60,
    output reg                           CS_M_AXIS_TDATA61,
    output reg                           CS_M_AXIS_TDATA62,
    output reg                           CS_M_AXIS_TDATA63
);

// Internal signals
reg [15:0] gen_word_num;
reg [1:0]  gen_state;
reg [1:0]  check_state;
reg [15:0] check_word_num;
reg [31:0] tx_count, rx_count, err_count;
wire        count_reset;  //was reg
reg        ok;
reg [C_M_AXIS_DATA_WIDTH-1:0] pkt_tx_buf;
reg [C_S_AXIS_DATA_WIDTH-1:0] pkt_rx_buf;
wire [255:0] seed = 256'hCAFEBEEFCAFEBEEFCAFEBEEFCAFEBEEFCAFEBEEFCAFEBEEFCAFEBEEFCAFEBEEF;

reg [19:0] ledcnt;
reg        led_reg;

// AXI slave/reg interface stub
axi4_lite_regs #(
    .ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
    .DATA_WIDTH(C_S_AXI_DATA_WIDTH)
) regs (
    .tx_count    (tx_count),
    .rx_count    (rx_count),
    .err_count   (err_count),
    .count_reset (count_reset),
    .AXIS_ACLK   (aclk),
    .aclk        (S_AXI_ACLK),
    .aresetn     (S_AXI_ARESETN),
    .AWADDR      (S_AXI_AWADDR),
    .AWVALID     (S_AXI_AWVALID),
    .AWREADY     (S_AXI_AWREADY),
    .WDATA       (S_AXI_WDATA),
    .WSTRB       (S_AXI_WSTRB),
    .WVALID      (S_AXI_WVALID),
    .WREADY      (S_AXI_WREADY),
    .BRESP       (S_AXI_BRESP),
    .BVALID      (S_AXI_BVALID),
    .BREADY      (S_AXI_BREADY),
    .ARADDR      (S_AXI_ARADDR),
    .ARVALID     (S_AXI_ARVALID),
    .ARREADY     (S_AXI_ARREADY),
    .RDATA       (S_AXI_RDATA),
    .RRESP       (S_AXI_RRESP),
    .RVALID      (S_AXI_RVALID),
    .RREADY      (S_AXI_RREADY)
);

// Output assignments
assign s_axis_tready = 1'b1;

// Packet generator FSM
localparam GEN_PKT    = 2'b00,
           GEN_IFG    = 2'b01,
           GEN_FINISH = 2'b11,
           CHECK_IDLE = 2'b00,
           CHECK_COMPARE = 2'b01,
           CHECK_FINISH  = 2'b11,
           CHECK_WAIT_LAST = 2'b10;
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        m_axis_tstrb  <= 0;
        m_axis_tvalid <= 0;
        gen_word_num  <= 0;
        tx_count      <= 0;
        gen_state     <= GEN_IFG;
    end else begin
        case (gen_state)
            GEN_PKT: begin
                m_axis_tstrb  <= {C_M_AXIS_DATA_WIDTH/8{1'b1}};
                m_axis_tvalid <= 1'b1;
                if (m_axis_tready) begin
                    gen_word_num <= gen_word_num + 1'b1;
                    if (gen_word_num == (C_GEN_PKT_SIZE-1)) begin
                        m_axis_tstrb  <= 0;
                        m_axis_tvalid <= 0;
                        tx_count      <= tx_count + 1'b1;
                        gen_state     <= GEN_IFG;
                    end else begin
                        pkt_tx_buf    <= {pkt_tx_buf[0], pkt_tx_buf[C_M_AXIS_DATA_WIDTH-1:1]};
                        m_axis_tdata  <= {pkt_tx_buf[0], pkt_tx_buf[C_M_AXIS_DATA_WIDTH-1:1]};
                    end
                end
            end
            GEN_IFG: begin
                m_axis_tstrb  <= 0;
                m_axis_tvalid <= 0;
                if (m_axis_tready) begin
                    gen_word_num <= gen_word_num + 1'b1;
                    if (gen_word_num == (C_GEN_PKT_SIZE+C_IFG_SIZE-1)) begin
                        if (count_reset)
                            gen_state <= GEN_IFG;
                        else
                            gen_state <= GEN_FINISH;
                    end
                end
            end
            GEN_FINISH: begin
                m_axis_tstrb  <= {C_M_AXIS_DATA_WIDTH/8{1'b1}};
                m_axis_tvalid <= 1'b1;
                m_axis_tdata  <= seed[C_M_AXIS_DATA_WIDTH-1:0];
                pkt_tx_buf    <= seed[C_M_AXIS_DATA_WIDTH-1:0];
                gen_word_num  <= 0;
                gen_state     <= GEN_PKT;
            end
        endcase

        // TLAST & TUSER
        m_axis_tlast <= (gen_word_num == (C_GEN_PKT_SIZE-1)) ? 1'b1 : 1'b0;
        m_axis_tuser <= 0;

        // Debug outputs
        {CS_M_AXIS_TDATA63, CS_M_AXIS_TDATA62, CS_M_AXIS_TDATA61, CS_M_AXIS_TDATA60,
         CS_M_AXIS_TDATA59, CS_M_AXIS_TDATA58, CS_M_AXIS_TDATA57, CS_M_AXIS_TDATA56,
         CS_M_AXIS_TDATA55, CS_M_AXIS_TDATA54, CS_M_AXIS_TDATA53, CS_M_AXIS_TDATA52,
         CS_M_AXIS_TDATA51, CS_M_AXIS_TDATA50, CS_M_AXIS_TDATA49, CS_M_AXIS_TDATA48,
         CS_M_AXIS_TDATA47, CS_M_AXIS_TDATA46, CS_M_AXIS_TDATA45, CS_M_AXIS_TDATA44,
         CS_M_AXIS_TDATA43, CS_M_AXIS_TDATA42, CS_M_AXIS_TDATA41, CS_M_AXIS_TDATA40,
         CS_M_AXIS_TDATA39, CS_M_AXIS_TDATA38, CS_M_AXIS_TDATA37, CS_M_AXIS_TDATA36,
         CS_M_AXIS_TDATA35, CS_M_AXIS_TDATA34, CS_M_AXIS_TDATA33, CS_M_AXIS_TDATA32,
         CS_M_AXIS_TDATA31, CS_M_AXIS_TDATA30, CS_M_AXIS_TDATA29, CS_M_AXIS_TDATA28,
         CS_M_AXIS_TDATA27, CS_M_AXIS_TDATA26, CS_M_AXIS_TDATA25, CS_M_AXIS_TDATA24,
         CS_M_AXIS_TDATA23, CS_M_AXIS_TDATA22, CS_M_AXIS_TDATA21, CS_M_AXIS_TDATA20,
         CS_M_AXIS_TDATA19, CS_M_AXIS_TDATA18, CS_M_AXIS_TDATA17, CS_M_AXIS_TDATA16,
         CS_M_AXIS_TDATA15, CS_M_AXIS_TDATA14, CS_M_AXIS_TDATA13, CS_M_AXIS_TDATA12,
         CS_M_AXIS_TDATA11, CS_M_AXIS_TDATA10, CS_M_AXIS_TDATA9,  CS_M_AXIS_TDATA8,
         CS_M_AXIS_TDATA7,  CS_M_AXIS_TDATA6,  CS_M_AXIS_TDATA5,  CS_M_AXIS_TDATA4,
         CS_M_AXIS_TDATA3,  CS_M_AXIS_TDATA2,  CS_M_AXIS_TDATA1,  CS_M_AXIS_TDATA0} <= pkt_tx_buf;
    end
end

// Packet checker FSM
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        check_state    <= 2'b00; // equivalent to (others => '0')
        rx_count       <= 0;
        err_count      <= 0;
        ok             <= 1'b1;
        check_word_num <= 0;
    end else begin
        case (check_state)
            CHECK_IDLE: begin
                // waiting for a pkt
                if (s_axis_tvalid) begin
                    ok             <= 1'b1;
                    pkt_rx_buf     <= {s_axis_tdata[0], s_axis_tdata[C_S_AXIS_DATA_WIDTH-1:1]};
                    check_word_num <= 0;
                    check_state    <= CHECK_COMPARE;
                end
            end
            CHECK_COMPARE: begin
                // checking the packet
                if (s_axis_tvalid) begin
                    pkt_rx_buf     <= {pkt_rx_buf[0], pkt_rx_buf[C_S_AXIS_DATA_WIDTH-1:1]};
                    check_word_num <= check_word_num + 1;
                    if (s_axis_tdata == pkt_rx_buf)
                        ok <= ok;
                    else
                        ok <= 1'b0;
                    if (check_word_num == (C_CHECK_PKT_SIZE - 2)) begin
                        if (s_axis_tlast)
                            check_state <= CHECK_FINISH; // finish up
                        else begin
                            ok         <= 1'b0;
                            check_state<= CHECK_WAIT_LAST; // Wait for last
                        end
                    end
                end
            end
            CHECK_FINISH: begin
                // finish up
                if (ok)
                    rx_count  <= rx_count + 1;
                else
                    err_count <= err_count + 1;
                check_state    <= CHECK_IDLE;
                ok             <= 1'b1;
            end
            CHECK_WAIT_LAST: begin
                // Wait for last
                if (s_axis_tlast && s_axis_tvalid)
                    check_state <= CHECK_FINISH;
            end
        endcase

        if (count_reset) begin
            rx_count  <= 0;
            err_count <= 0;
        end
    end
end

// LED logic (blinky)
always @(posedge aclk) begin
    if (!aresetn) begin
        ledcnt  <= 0;
        led_reg <= 0;
    end else begin
        if (ledcnt == 4191) begin
            ledcnt  <= 0;
            led_reg <= ~led_reg;
        end else begin
            ledcnt <= ledcnt + 1'b1;
        end
    end
end
always @(*) LED03 = led_reg;

// TODO: Implement check_p process logic (packet checker FSM) in Verilog.

endmodule

// -----------------------------------------------------------------------------
// AXI4-Lite register interface 
module axi4_lite_regs
#(
    // Master AXI Stream Data Width
    parameter DATA_WIDTH=32,
    parameter ADDR_WIDTH=32
)
(
   input  aclk,
   input  aresetn,

   input  [ADDR_WIDTH-1: 0] AWADDR,
   input  AWVALID,
   output reg AWREADY,

   input  [DATA_WIDTH-1: 0]   WDATA,
   input  [DATA_WIDTH/8-1: 0] WSTRB,
   input  WVALID,
   output reg WREADY,

   output reg [1:0] BRESP,
   output reg BVALID,
   input  BREADY,

   input  [ADDR_WIDTH-1: 0] ARADDR,
   input  ARVALID,
   output reg ARREADY,

   output reg [DATA_WIDTH-1: 0] RDATA,
   output reg [1:0] RRESP,
   output reg RVALID,
   input  RREADY,

   input  [31:0] tx_count,
   input  [31:0] rx_count,
   input  [31:0] err_count,
   output reg       count_reset,
   input         AXIS_ACLK
);

    localparam AXI_RESP_OK = 2'b00;
    localparam AXI_RESP_SLVERR = 2'b10;

    localparam WRITE_IDLE = 0;
    localparam WRITE_RESPONSE = 1;
    localparam WRITE_DATA = 2;

    localparam READ_IDLE = 0;
    localparam READ_RESPONSE = 1;
    localparam READ_WAIT = 2;

    localparam REG_TX_COUNT = 2'h0;
    localparam REG_RX_COUNT = 2'h1;
    localparam REG_ERR_COUNT = 2'h2;
    localparam REG_COUNT_RESET = 2'h3;

    reg [31:0] tx_count_r_2, tx_count_r;
    reg [31:0] rx_count_r_2, rx_count_r;
    reg [31:0] err_count_r_2, err_count_r;
    reg        count_reset_control_next, count_reset_control;
    reg        count_reset_r_2, count_reset_r;
    // synthesis attribute ASYNC_REG of tx_count_r is "TRUE";
    // synthesis attribute ASYNC_REG of rx_count_r is "TRUE";
    // synthesis attribute ASYNC_REG of err_count_r is "TRUE";
    // synthesis attribute ASYNC_REG of count_reset_r_2 is "TRUE";

    reg [1:0] write_state, write_state_next;
    reg [1:0] read_state, read_state_next;
    reg [ADDR_WIDTH-1:0] read_addr, read_addr_next;
    reg [ADDR_WIDTH-1:0] write_addr, write_addr_next;
    reg [2:0] counter, counter_next;
    reg [1:0] BRESP_next;
    localparam WAIT_COUNT = 2;

    always @(*) begin
        read_state_next = read_state;
        ARREADY = 1'b1;
        read_addr_next = read_addr;
        counter_next = counter;
        RDATA = 0;
        RRESP = AXI_RESP_OK;
        RVALID = 1'b0;

        case(read_state)
            READ_IDLE: begin
                counter_next = 0;
                if(ARVALID) begin
                    read_addr_next = ARADDR;
                    read_state_next = READ_WAIT;
                end
            end

            READ_WAIT: begin
                counter_next = counter + 1;
                ARREADY = 1'b0;
                if(counter == WAIT_COUNT)
                    read_state_next = READ_RESPONSE;
            end

            READ_RESPONSE: begin
                RVALID = 1'b1;
                ARREADY = 1'b0;

                if(read_addr[1:0] == REG_TX_COUNT) begin
                    RDATA = tx_count_r_2;
                end
                else if(read_addr[1:0] == REG_RX_COUNT) begin
                    RDATA = rx_count_r_2;
                end
                else if(read_addr[1:0] == REG_ERR_COUNT) begin
                    RDATA = err_count_r_2;
                end
                else begin
                    RRESP = AXI_RESP_SLVERR;
                end
                if(RREADY) begin
                    read_state_next = READ_IDLE;
                end
            end
        endcase
    end

    always @(*) begin
        write_state_next = write_state;
        write_addr_next = write_addr;
        count_reset_control_next = count_reset_control;
        AWREADY = 1'b1;
        WREADY = 1'b0;
        BVALID = 1'b0;
        BRESP_next = BRESP;

        case(write_state)
            WRITE_IDLE: begin
                write_addr_next = AWADDR;
                if(AWVALID) begin
                    write_state_next = WRITE_DATA;
                end
            end
            WRITE_DATA: begin
                AWREADY = 1'b0;
                WREADY = 1'b1;
                if(WVALID) begin
                    if (write_addr[1:0] == REG_COUNT_RESET) begin
                        count_reset_control_next = WDATA;
                        BRESP_next = AXI_RESP_OK;
                    end
                    else begin
                        BRESP_next = AXI_RESP_SLVERR;
                    end
                    write_state_next = WRITE_RESPONSE;
                end
            end
            WRITE_RESPONSE: begin
                AWREADY = 1'b0;
                BVALID = 1'b1;
                if(BREADY) begin
                    write_state_next = WRITE_IDLE;
                end
            end
        endcase
    end

    always @(posedge aclk) begin
        if(~aresetn) begin
            write_state <= WRITE_IDLE;
            read_state <= READ_IDLE;
            read_addr <= 0;
            write_addr <= 0;
            BRESP <= AXI_RESP_OK;
            count_reset_control <= 0;
        end
        else begin
            write_state <= write_state_next;
            read_state <= read_state_next;
            read_addr <= read_addr_next;
            write_addr <= write_addr_next;
            BRESP <= BRESP_next;
            count_reset_control <= count_reset_control_next;
        end

        rx_count_r_2 <= rx_count_r;
        tx_count_r_2 <= tx_count_r;
        err_count_r_2 <= err_count_r;
        count_reset_r <= count_reset_control;

        rx_count_r <= rx_count;
        tx_count_r <= tx_count;
        err_count_r <= err_count;

        counter <= counter_next;
    end

    always @(AXIS_ACLK) begin
        count_reset <= count_reset_r_2;
        count_reset_r_2 <= count_reset_r;
    end

endmodule
