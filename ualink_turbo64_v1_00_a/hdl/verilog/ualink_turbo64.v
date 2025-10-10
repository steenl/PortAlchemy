
/*******************************************************************************
 *  Steen Larsen 2025
 *
 *  Licence:
 *
 *        This file is free code: you can redistribute it and/or modify it under
 *        the terms of the GNU Lesser General Public License version 2.1 as
 *        published by the Free Software Foundation.
 *
 *        This package is distributed in the hope that it will be useful, but
 *        WITHOUT ANY WARRANTY; without even the implied warranty of
 *        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *        Lesser General Public License for more details.
 *
 *        You should have received a copy of the GNU Lesser General Public
 *        License along with the NetFPGA source package.  If not, see
 *        http://www.gnu.org/licenses/.
 *
 */

module ualink_turbo64
#(
    // Master AXI Stream Data Width
    parameter C_M_AXIS_DATA_WIDTH=64,  //256, for visibility
    parameter C_S_AXIS_DATA_WIDTH=64, // 256,
    parameter C_M_AXIS_TUSER_WIDTH=32, //128,
    parameter C_S_AXIS_TUSER_WIDTH=32, //128,
    parameter NUM_QUEUES=5,
    parameter DPADDR_WIDTH = 8,
    parameter DPDATA_WIDTH = 64,
    parameter DPDEPTH = (1 << DPADDR_WIDTH)
)
(
    // Part 1: System side signals
    // Global Ports
    input axi_aclk,
    input axi_resetn,

    // Master Stream Ports (interface to data path)
    output [C_M_AXIS_DATA_WIDTH - 1:0] m_axis_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tstrb,
    output [C_M_AXIS_TUSER_WIDTH-1:0] m_axis_tuser,
    output m_axis_tvalid,
    input  m_axis_tready,
    output m_axis_tlast,


    // Slave Stream Ports (interface to RX queues)
    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata_0,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tstrb_0,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser_0,
    input  s_axis_tvalid_0,
    output s_axis_tready_0,
    input  s_axis_tlast_0,

    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata_1,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tstrb_1,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser_1,
    input  s_axis_tvalid_1,
    output s_axis_tready_1,
    input  s_axis_tlast_1,

    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata_2,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tstrb_2,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser_2,
    input  s_axis_tvalid_2,
    output s_axis_tready_2,
    input  s_axis_tlast_2,

    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata_3,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tstrb_3,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser_3,
    input  s_axis_tvalid_3,
    output s_axis_tready_3,
    input  s_axis_tlast_3,

    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata_4,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tstrb_4,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser_4,
    input  s_axis_tvalid_4,
    output s_axis_tready_4,
    input  s_axis_tlast_4,
         // LEDs and debug outputs
    output reg LED03,
	 output reg CS_empty0,
    output reg CS_state0, CS_state1, CS_state2, CS_state3,
    output reg CS_we_a, CS_addr_a0, CS_din_a0,
	 output reg CS_m_axis_tvalid,
	 output reg CS_m_axis_tready,
	 output reg CS_m_axis_tlast,
	 output reg CS_s_axis_tvalid_0,
	 output reg CS_s_axis_tready_0,
	 output reg CS_s_axis_tlast_0,	 
    output reg CS_M_AXIS_TDATA0, CS_M_AXIS_TDATA1, CS_M_AXIS_TDATA2, CS_M_AXIS_TDATA3, CS_M_AXIS_TDATA4, CS_M_AXIS_TDATA5, CS_M_AXIS_TDATA6, CS_M_AXIS_TDATA7, CS_M_AXIS_TDATA8, CS_M_AXIS_TDATA9, CS_M_AXIS_TDATA10, CS_M_AXIS_TDATA11, CS_M_AXIS_TDATA12, CS_M_AXIS_TDATA13, CS_M_AXIS_TDATA14, CS_M_AXIS_TDATA15, CS_M_AXIS_TDATA16, CS_M_AXIS_TDATA17, CS_M_AXIS_TDATA18, CS_M_AXIS_TDATA19, CS_M_AXIS_TDATA20, CS_M_AXIS_TDATA21, CS_M_AXIS_TDATA22, CS_M_AXIS_TDATA23, CS_M_AXIS_TDATA24, CS_M_AXIS_TDATA25, CS_M_AXIS_TDATA26, CS_M_AXIS_TDATA27, CS_M_AXIS_TDATA28, CS_M_AXIS_TDATA29, CS_M_AXIS_TDATA30, CS_M_AXIS_TDATA31, CS_M_AXIS_TDATA32, CS_M_AXIS_TDATA33, CS_M_AXIS_TDATA34, CS_M_AXIS_TDATA35, CS_M_AXIS_TDATA36, CS_M_AXIS_TDATA37, CS_M_AXIS_TDATA38, CS_M_AXIS_TDATA39, CS_M_AXIS_TDATA40, CS_M_AXIS_TDATA41, CS_M_AXIS_TDATA42, CS_M_AXIS_TDATA43, CS_M_AXIS_TDATA44, CS_M_AXIS_TDATA45, CS_M_AXIS_TDATA46, CS_M_AXIS_TDATA47, CS_M_AXIS_TDATA48, CS_M_AXIS_TDATA49, CS_M_AXIS_TDATA50, CS_M_AXIS_TDATA51, CS_M_AXIS_TDATA52, CS_M_AXIS_TDATA53, CS_M_AXIS_TDATA54, CS_M_AXIS_TDATA55, CS_M_AXIS_TDATA56, CS_M_AXIS_TDATA57, CS_M_AXIS_TDATA58, CS_M_AXIS_TDATA59, CS_M_AXIS_TDATA60, CS_M_AXIS_TDATA61, CS_M_AXIS_TDATA62, CS_M_AXIS_TDATA63,  CS_S_AXIS_TDATA0, CS_S_AXIS_TDATA1, CS_S_AXIS_TDATA2, CS_S_AXIS_TDATA3, CS_S_AXIS_TDATA4, CS_S_AXIS_TDATA5, CS_S_AXIS_TDATA6, CS_S_AXIS_TDATA7, CS_S_AXIS_TDATA8, CS_S_AXIS_TDATA9, CS_S_AXIS_TDATA10, CS_S_AXIS_TDATA11, CS_S_AXIS_TDATA12, CS_S_AXIS_TDATA13, CS_S_AXIS_TDATA14, CS_S_AXIS_TDATA15, CS_S_AXIS_TDATA16, CS_S_AXIS_TDATA17, CS_S_AXIS_TDATA18, CS_S_AXIS_TDATA19, CS_S_AXIS_TDATA20, CS_S_AXIS_TDATA21, CS_S_AXIS_TDATA22, CS_S_AXIS_TDATA23, CS_S_AXIS_TDATA24, CS_S_AXIS_TDATA25, CS_S_AXIS_TDATA26, CS_S_AXIS_TDATA27, CS_S_AXIS_TDATA28, CS_S_AXIS_TDATA29, CS_S_AXIS_TDATA30, CS_S_AXIS_TDATA31, CS_S_AXIS_TDATA32, CS_S_AXIS_TDATA33, CS_S_AXIS_TDATA34, CS_S_AXIS_TDATA35, CS_S_AXIS_TDATA36, CS_S_AXIS_TDATA37, CS_S_AXIS_TDATA38, CS_S_AXIS_TDATA39, CS_S_AXIS_TDATA40, CS_S_AXIS_TDATA41, CS_S_AXIS_TDATA42, CS_S_AXIS_TDATA43, CS_S_AXIS_TDATA44, CS_S_AXIS_TDATA45, CS_S_AXIS_TDATA46, CS_S_AXIS_TDATA47, CS_S_AXIS_TDATA48, CS_S_AXIS_TDATA49, CS_S_AXIS_TDATA50, CS_S_AXIS_TDATA51, CS_S_AXIS_TDATA52, CS_S_AXIS_TDATA53, CS_S_AXIS_TDATA54, CS_S_AXIS_TDATA55, CS_S_AXIS_TDATA56, CS_S_AXIS_TDATA57, CS_S_AXIS_TDATA58, CS_S_AXIS_TDATA59, CS_S_AXIS_TDATA60, CS_S_AXIS_TDATA61, CS_S_AXIS_TDATA62, CS_S_AXIS_TDATA63);

   function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2

   // ------------ Internal Params --------

   parameter NUM_QUEUES_WIDTH = log2(NUM_QUEUES);

   parameter NUM_STATES = 4;
   parameter IDLE = 0;
   parameter WR_PKT = 1;
   parameter READ_OPc1 = 2;
   parameter READ_OPc2 = 3;
   parameter READ_OPc3 = 4;

   localparam MAX_PKT_SIZE = 2000; // In bytes
   localparam IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_M_AXIS_DATA_WIDTH / 8));

   // ------------- Regs/ wires -----------

   wire [NUM_QUEUES-1:0]               nearly_full;
   wire [NUM_QUEUES-1:0]               empty;
   wire [C_M_AXIS_DATA_WIDTH-1:0]        in_tdata      [NUM_QUEUES-1:0];
   wire [((C_M_AXIS_DATA_WIDTH/8))-1:0]  in_tstrb      [NUM_QUEUES-1:0];
   wire [C_M_AXIS_TUSER_WIDTH-1:0]             in_tuser      [NUM_QUEUES-1:0];
   wire [NUM_QUEUES-1:0] 	       in_tvalid;
   wire [NUM_QUEUES-1:0]               in_tlast;
   wire [C_M_AXIS_TUSER_WIDTH-1:0]             fifo_out_tuser[NUM_QUEUES-1:0];
   wire [C_M_AXIS_DATA_WIDTH-1:0]        fifo_out_tdata[NUM_QUEUES-1:0];
   wire [((C_M_AXIS_DATA_WIDTH/8))-1:0]  fifo_out_tstrb[NUM_QUEUES-1:0];
   wire [NUM_QUEUES-1:0] 	       fifo_out_tlast;
   wire                                fifo_tvalid;
   wire                                fifo_tlast;
   reg [NUM_QUEUES-1:0]                rd_en;

   wire [NUM_QUEUES_WIDTH-1:0]         cur_queue_plus1;
   reg [NUM_QUEUES_WIDTH-1:0]          cur_queue;
   reg [NUM_QUEUES_WIDTH-1:0]          cur_queue_next;

   reg [NUM_STATES-1:0]                state;
   reg [NUM_STATES-1:0]                state_next;
   reg [C_M_AXIS_DATA_WIDTH - 1:0] m_axis_tdata_reg = "abcdefgh"; //register to hold read response data
   reg [C_M_AXIS_DATA_WIDTH - 1:0] frame_h0d1_reg =   "00000000000000000000000000000000"; //register to hold read response data
   reg [C_M_AXIS_DATA_WIDTH - 1:0] frame_h0d2_reg = "00000000000000000000000000000000"; //register to hold read response data
   reg [C_M_AXIS_DATA_WIDTH - 1:0] frame_h0d3_reg = "00000000000000000000000000000000"; //register to hold read response data

   reg [15:0] ualink_opcode; //opcode from command packet

     //debug
  reg [19:0] ledcnt;
  reg [19:0] ledcnt1;
  reg     led_reg, led_clk;
  
  	reg we_a, we_a_next;
	reg [DPADDR_WIDTH-1:0]               addr_a;
	reg [DPDATA_WIDTH-1:0]               din_a;
	wire [DPDATA_WIDTH-1:0]               dout_a;
	reg we_b;
	reg [DPADDR_WIDTH-1:0]               addr_b;
	reg [DPDATA_WIDTH-1:0]               din_b;
	wire [DPDATA_WIDTH-1:0]               dout_b;

   // ------------ Modules -------------

   dual_port_ram_8x64
   #(
    .DPADDR_WIDTH(DPADDR_WIDTH),
    .DPDATA_WIDTH(DPDATA_WIDTH),
    .DPDEPTH (DPDEPTH)
   )
   dpmem_inst
   (
    .axi_aclk(axi_aclk),
    .axi_resetn(axi_resetn),
    .we_a(we_a),
    .addr_a(addr_a),
    .din_a(din_a),
    .dout_a(dout_a),
    .we_b(we_b),
    .addr_b(addr_b),
    .din_b(din_b),
    .dout_b(dout_b)
   );
   
   generate
   genvar i;
   for(i=0; i<NUM_QUEUES; i=i+1) begin: in_arb_queues
      fallthrough_small_fifo
        #( .WIDTH(C_M_AXIS_DATA_WIDTH+C_M_AXIS_TUSER_WIDTH+C_M_AXIS_DATA_WIDTH/8+1),
           .MAX_DEPTH_BITS(IN_FIFO_DEPTH_BIT))
      in_arb_fifo
        (// Outputs
         .dout                           ({fifo_out_tlast[i], fifo_out_tuser[i], fifo_out_tstrb[i], fifo_out_tdata[i]}),
         .full                           (),
         .nearly_full                    (nearly_full[i]),
	 .prog_full                      (),
         .empty                          (empty[i]),
         // Inputs
         .din                            ({in_tlast[i], in_tuser[i], in_tstrb[i], in_tdata[i]}),
         .wr_en                          (in_tvalid[i] & ~nearly_full[i]),
         .rd_en                          (rd_en[i]),
         .reset                          (~axi_resetn),
         .clk                            (axi_aclk));
   end
   endgenerate

   // ------------- Logic ------------

   assign in_tdata[0]        = s_axis_tdata_0;
   assign in_tstrb[0]        = s_axis_tstrb_0;
   assign in_tuser[0]        = s_axis_tuser_0;
   assign in_tvalid[0]       = s_axis_tvalid_0;
   assign in_tlast[0]        = s_axis_tlast_0;
   assign s_axis_tready_0    = !nearly_full[0];

   assign in_tdata[1]        = s_axis_tdata_1;
   assign in_tstrb[1]        = s_axis_tstrb_1;
   assign in_tuser[1]        = s_axis_tuser_1;
   assign in_tvalid[1]       = s_axis_tvalid_1;
   assign in_tlast[1]        = s_axis_tlast_1;
   assign s_axis_tready_1    = !nearly_full[1];

   assign in_tdata[2]        = s_axis_tdata_2;
   assign in_tstrb[2]        = s_axis_tstrb_2;
   assign in_tuser[2]        = s_axis_tuser_2;
   assign in_tvalid[2]       = s_axis_tvalid_2;
   assign in_tlast[2]        = s_axis_tlast_2;
   assign s_axis_tready_2    = !nearly_full[2];

   assign in_tdata[3]        = s_axis_tdata_3;
   assign in_tstrb[3]        = s_axis_tstrb_3;
   assign in_tuser[3]        = s_axis_tuser_3;
   assign in_tvalid[3]       = s_axis_tvalid_3;
   assign in_tlast[3]        = s_axis_tlast_3;
   assign s_axis_tready_3    = !nearly_full[3];

   assign in_tdata[4]        = s_axis_tdata_4;
   assign in_tstrb[4]        = s_axis_tstrb_4;
   assign in_tuser[4]        = s_axis_tuser_4;
   assign in_tvalid[4]       = s_axis_tvalid_4;
   assign in_tlast[4]        = s_axis_tlast_4;
   assign s_axis_tready_4    = !nearly_full[4];

   assign cur_queue_plus1    = 0; //lock to port 0 (cur_queue == NUM_QUEUES-1) ? 0 : cur_queue + 1;

   //assign fifo_out_tuser_sel = fifo_out_tuser[cur_queue];
   //assign fifo_out_tdata_sel = fifo_out_tdata[cur_queue];
   //assign fifo_out_tlast_sel = fifo_out_tlast[cur_queue];
   //assign fifo_out_tstrb_sel = fifo_out_tstrb[cur_queue];

   assign m_axis_tuser = fifo_out_tuser[cur_queue];
   
   assign m_axis_tdata = fifo_out_tdata[cur_queue];
   //assign m_axis_tdata = (state != READ_OPc2) ? fifo_out_tdata[cur_queue] : m_axis_tdata_reg;  //slam read data into output stream
   
   assign m_axis_tlast = fifo_out_tlast[cur_queue];  //pulse last on read data cycle 
   //assign m_axis_tlast = (state != READ_OPc3) ? fifo_out_tlast[cur_queue] : 1'b1;  //pulse last on read data cycle 
   
   assign m_axis_tstrb = fifo_out_tstrb[cur_queue];
   assign m_axis_tvalid = ~empty[cur_queue];
   

   always @(*) begin  // combinational state machine
      state_next      = state;
      cur_queue_next  = cur_queue;
      rd_en           = 0;
      we_a_next            = 0;

      case(state)

        /* cycle between input queues until one is not empty */
        IDLE: begin  
		     //check if pkt available on currently selected queue
           if(!empty[cur_queue]) begin
			     // check if pkt is on the AXIS 
              if(m_axis_tready) begin
                 state_next = WR_PKT;
                 rd_en[cur_queue] = 1;
             end
           end
           else begin
              cur_queue_next = cur_queue_plus1;
           end
        end

        /* wait until eop */
        WR_PKT: begin
           /* if this is the last word then write it and get out */
           if(m_axis_tready & m_axis_tlast) begin
              state_next = IDLE;
	           rd_en[cur_queue] = 1;
              cur_queue_next = cur_queue_plus1;
           end
           /* otherwise read and write as usual */
           else if (m_axis_tready & !empty[cur_queue]) begin
              rd_en[cur_queue] = 1;  //force response to port0
                 ualink_opcode = m_axis_tdata[15:0];
                 $display("UAlink write opcode %h", ualink_opcode);
               //decode command    
              if ((m_axis_tdata[15:0]) ==  16'h4501) begin  //write operation
                we_a_next = 1;
					 addr_a = 8'h1;
					 din_a = m_axis_tdata[63:0];
				  end
              else if ((m_axis_tdata[15:0]) ==  16'h4502) begin  //read to addr 1
                   addr_a = 8'h1;
                   state_next = READ_OPc1; 
  					    we_a_next = 0;
                 end
               else begin
					   // we_a = 0;
					end // ualink opcode processing
             end  //progress regular packet


             end  //WR_PKT state

         READ_OPc1: begin
              state_next = READ_OPc2;
              end

         READ_OPc2: begin
            state_next = READ_OPc3;
            end

         READ_OPc3: begin
            state_next = WR_PKT;
            end   

      endcase // case(state)
   end // always @ (*)
//advance state machine regs
   always @(posedge axi_aclk) begin // state machine
      if(~axi_resetn) begin
         state <= IDLE;
         cur_queue <= 0;
      end
      else begin
         state <= state_next;
         cur_queue <= cur_queue_next;
         we_a <= we_a_next;
           frame_h0d3_reg <= frame_h0d2_reg;
            frame_h0d2_reg <= frame_h0d1_reg;
            frame_h0d1_reg <= s_axis_tdata_0;
		  end
   end

      // LED logic (blinky)  Need two sensitivities to force meeting 100MHz timing
always @(posedge axi_aclk) begin
    if (!axi_resetn) begin
        ledcnt  <= 0;
        led_clk <= 0;
    end else begin
        if (ledcnt == 2047) begin
            ledcnt  <= 0;
            led_clk <= ~led_clk;
        end else begin
            ledcnt <= ledcnt + 1'b1;
        end
    end
            // Debug outputs need to be in an clock defined always.
			CS_state0 <= state[0];
         CS_state1 <= state[1];
         CS_state2 <= state[2];
         CS_state3 <= state[3];
         CS_we_a <= we_a;
			CS_empty0 <= empty[0];
         CS_addr_a0 <= addr_a[0];
         CS_din_a0 <= din_a[0];
         CS_m_axis_tvalid <= m_axis_tvalid;
			CS_m_axis_tready <= m_axis_tready;
			CS_m_axis_tlast  <= m_axis_tlast;
			CS_s_axis_tvalid_0 <= s_axis_tvalid_0;
			CS_s_axis_tready_0 <= s_axis_tready_0;
			CS_s_axis_tlast_0  <= s_axis_tlast_0;
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
         CS_M_AXIS_TDATA3,  CS_M_AXIS_TDATA2,  CS_M_AXIS_TDATA1,  CS_M_AXIS_TDATA0} <= m_axis_tdata;

         {CS_S_AXIS_TDATA63, CS_S_AXIS_TDATA62, CS_S_AXIS_TDATA61, CS_S_AXIS_TDATA60,
         CS_S_AXIS_TDATA59, CS_S_AXIS_TDATA58, CS_S_AXIS_TDATA57, CS_S_AXIS_TDATA56,
         CS_S_AXIS_TDATA55, CS_S_AXIS_TDATA54, CS_S_AXIS_TDATA53, CS_S_AXIS_TDATA52,
         CS_S_AXIS_TDATA51, CS_S_AXIS_TDATA50, CS_S_AXIS_TDATA49, CS_S_AXIS_TDATA48,
         CS_S_AXIS_TDATA47, CS_S_AXIS_TDATA46, CS_S_AXIS_TDATA45, CS_S_AXIS_TDATA44,
         CS_S_AXIS_TDATA43, CS_S_AXIS_TDATA42, CS_S_AXIS_TDATA41, CS_S_AXIS_TDATA40,
         CS_S_AXIS_TDATA39, CS_S_AXIS_TDATA38, CS_S_AXIS_TDATA37, CS_S_AXIS_TDATA36,
         CS_S_AXIS_TDATA35, CS_S_AXIS_TDATA34, CS_S_AXIS_TDATA33, CS_S_AXIS_TDATA32,
         CS_S_AXIS_TDATA31, CS_S_AXIS_TDATA30, CS_S_AXIS_TDATA29, CS_S_AXIS_TDATA28,
         CS_S_AXIS_TDATA27, CS_S_AXIS_TDATA26, CS_S_AXIS_TDATA25, CS_S_AXIS_TDATA24,
         CS_S_AXIS_TDATA23, CS_S_AXIS_TDATA22, CS_S_AXIS_TDATA21, CS_S_AXIS_TDATA20,
         CS_S_AXIS_TDATA19, CS_S_AXIS_TDATA18, CS_S_AXIS_TDATA17, CS_S_AXIS_TDATA16,
         CS_S_AXIS_TDATA15, CS_S_AXIS_TDATA14, CS_S_AXIS_TDATA13, CS_S_AXIS_TDATA12,
         CS_S_AXIS_TDATA11, CS_S_AXIS_TDATA10, CS_S_AXIS_TDATA9,  CS_S_AXIS_TDATA8,
         CS_S_AXIS_TDATA7,  CS_S_AXIS_TDATA6,  CS_S_AXIS_TDATA5,  CS_S_AXIS_TDATA4,
         CS_S_AXIS_TDATA3,  CS_S_AXIS_TDATA2,  CS_S_AXIS_TDATA1,  CS_S_AXIS_TDATA0} <= s_axis_tdata_0;
end
always @(posedge led_clk) begin
    if (!axi_resetn) begin
        ledcnt1  <= 0;
        led_reg <= 0;
    end else begin
        if (ledcnt1 == 4191) begin
            ledcnt1  <= 0;
            led_reg <= ~led_reg;
        end else begin
            ledcnt1 <= ledcnt1 + 1'b1;
        end
    end
end
always @(*) LED03 = led_reg;


endmodule