/***Steen Larsen with AI assistance
  The intent of this testbench is to perform basic network driven read and write operations.  To mirror the scapy script:
pktwr=Ether()/IP(dst="192.168.0.6") / UDP(dport=12345)/b"00000ZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789AB"
pktrd=Ether()/IP(dst="192.168.0.6") / UDP(dport=12345)/b"00000ZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
pktrd[IP].tos=0x01
pktwr[IP].tos=0x02
sendp(pktwr,iface="enp3s0f1")
sendp(pktrd,iface="enp3s0f1")

For now all is AXI_0, we leave artifacts of port interfaces 0-4 for future multiport testing.
    




 to run in Icarus simulator use:
iverilog -o ualink_turbo64_tb.vvp .\ualink_turbo64_tb.v ualink_turbo64.v .\fallthrough_small_fifo_v2.v .\small_fifo_v3.v .\ualink_dpmem.v
vvp ualink_turbo64_tb.vvp
gtkwave.exe .\ualink_turbo64_tb.vcd


 *
 */

`timescale 1 ns / 1ps
module testbench();

   // parameter CLK_PERIOD = 10; // 10ns = 100MHz

    reg clk, reset;
    reg [63:0]  tdata[4:0];
    reg [4:0]  tlast;
    wire[4:0]  tready;

   reg 	       tvalid_0 = 0;
   reg 	       tvalid_1 = 0;
   reg 	       tvalid_2 = 0;
   reg 	       tvalid_3 = 0;
   reg 	       tvalid_4 = 0;

    reg [3:0] random = 0;

    integer i;
// wireshark displays in little-endian format, so we need to reverse byte order when constructing test packets
// chipscope has already reversed the byte order for us internally so we need to follow that convention here.
    wire [63:0] wr_w0 = 64'h0000FFFFFFFFFFFF; // Destination MAC with write opcode
    wire [63:0] wr_w1 = 64'h0245000800000000; // Source MAC + EtherType + write opcode
    wire [63:0] wr_w2 = 64'h1140000001000600;
    wire [63:0] wr_w3 = 64'hA8c000000000D9B9;
    wire [63:0] wr_w4 = 64'h4F00393035000600; //0x3039 is the UDP port number 12345
    wire [63:0] wr_w5 = 64'h5A30303030309896;  //address or key field 0x3030305A
    wire [63:0] wr_w6 = 64'h4847464544434241;  //1of8 data words
    wire [63:0] wr_w7 = 64'h504F4E4D4C4B4A49;  //
    wire [63:0] wr_w8 = 64'h5857565554535251;
    wire [63:0] wr_w9 = 64'h6665646362615A59;  //4
    wire [63:0] wr_wa = 64'h6E6D6C6B6A696867;
    wire [63:0] wr_wb = 64'h767574737271706F;
    wire [63:0] wr_wc = 64'h333231307A797877;
    wire [63:0] wr_wd = 64'h6261393837363534;  //8 of 8 data words


    wire [63:0] rd_w0 = 64'h0000FFFFFFFFFFFF; // Destination MAC  read opcode
    wire [63:0] rd_w1 = 64'h0145000800000000; // Source MAC + EtherType
    wire [63:0] rd_w2 = 64'h1140000001005C00;
    wire [63:0] rd_w3 = 64'hA8C000000000E1B9;
    wire [63:0] rd_w4 = 64'h4800393035000600;
    wire [63:0] rd_w5 = 64'h5A3030303030E1F4;  //address or key field
    wire [63:0] rd_w6 = 64'h4141414141414141;  //1of8 data words all AAAAAAAA 
    wire [63:0] rd_w7 = 64'h4141414141414141;  //
    wire [63:0] rd_w8 = 64'h4141414141414141;
    wire [63:0] rd_w9 = 64'h4141414141414141;  //4
    wire [63:0] rd_wa = 64'h4141414141414141;
    wire [63:0] rd_wb = 64'h4141414141414141;
    wire [63:0] rd_wc = 64'h4141414141414141;
    wire [63:0] rd_wd = 64'h4141414141414141;  //8 of 8 data words

    localparam HEADER_0 = 0;
    localparam HEADER_1 = 1;
    localparam HEADER_0a = 2;
    localparam HEADER_1a = 3;
    localparam PAYLOAD  = 4;
    localparam DEAD     = 5;

    reg [2:0] state, state_next;
    reg [7:0] counter, counter_next;

    always @(*) begin
       state_next = state;
       tdata[0] = 64'b0;
       tdata[1] = 64'b0;
       tdata[2] = 64'b0;
       tdata[3] = 64'b0;
       tdata[4] = 64'b0;
       tlast[0] = 1'b0;
       tlast[1] = 1'b0;
       tlast[2] = 1'b0;
       tlast[3] = 1'b0;
       tlast[4] = 1'b0;
       counter_next = counter;

        case(state)
            HEADER_0: begin
                tdata[random] = wr_w0;
                if(tready[random]) begin
                    state_next = HEADER_1;
                end
	       if (random == 0)
		 tvalid_0 = 1;
	       else if (random == 1)
		 tvalid_1 = 1;
	       else if (random == 2)
		 tvalid_2 = 1;
	       else if (random == 3)
		 tvalid_3 = 1;
	       else if (random == 4)
		 tvalid_4 = 1;
            end
            HEADER_1: begin
                tdata[random] = wr_w1;
                if(tready[random]) begin
                    state_next = PAYLOAD;
                end
            end
            PAYLOAD: begin
                tdata[random] = {8{counter}};
                if(tready[random]) begin
                    counter_next = counter + 1'b1;
                    if(counter == 8'h00) begin
                       tdata[random] = wr_w2;
                    end
                    if(counter == 8'h01) begin
                       tdata[random] = wr_w3;
                    end
                    if(counter == 8'h02) begin
                       tdata[random] = wr_w4;
                    end
                    if(counter == 8'h03) begin
                       tdata[random] = wr_w5;
                    end
                    if(counter == 8'h04) begin
                       tdata[random] = wr_w6;
                    end
                    if(counter == 8'h05) begin
                       tdata[random] = wr_w7;
                    end
                    if(counter == 8'h06) begin
                       tdata[random] = wr_w8;
                    end
                    if(counter == 8'h07) begin
                       tdata[random] = wr_w9;
                    end
                    if(counter == 8'h08) begin
                       tdata[random] = wr_wa;
                    end
                    if(counter == 8'h09) begin
                       tdata[random] = wr_wb;
                    end
                    if(counter == 8'h0a) begin
                       tdata[random] = wr_wc;
                    end
                    if(counter == 8'h0b) begin
                       tdata[random] = wr_wd;
                    end

                    if(counter == 8'h1F) begin
                        state_next = DEAD;
                        counter_next = 8'b0;
                        tlast[random] = 1'b1;
                    end
                end
            end  //PAYLOAD state

//try a read operation now

            HEADER_0a: begin
                tdata[random] = rd_w0;
                if(tready[random]) begin
                    counter_next = 8'b0;
                    state_next = HEADER_1a;
                end
         if (random == 0)
		 tvalid_0 = 1;
	       else if (random == 1)
		 tvalid_1 = 1;
	       else if (random == 2)
		 tvalid_2 = 1;
	       else if (random == 3)
		 tvalid_0 = 1;  //force to port 0 for easier debugging
	       else if (random == 4)
		 tvalid_4 = 1;
            end  //HEADER_0a
            HEADER_1a: begin
                tdata[random] = {8{counter}};

                // tdata[random] = rd_w1;
                if(tready[random]) begin
                    counter_next = counter + 1'b1;
                    if(counter == 8'h00) begin
                       tdata[random] = rd_w1;
                    end
                    if(counter == 8'h01) begin
                       tdata[random] = rd_w2;
                    end
                    if(counter == 8'h02) begin
                       tdata[random] = rd_w3;
                    end
                    if(counter == 8'h03) begin
                       tdata[random] = rd_w4;
                    end
                    if(counter == 8'h04) begin
                       tdata[random] = rd_w5;
                    end

                
                if(counter == 8'h17) begin
                    state_next = DEAD;
                    counter_next = 8'b0;
                    tlast[random] = 1'b1;
                end
                end
            end  //HEADER_1a


            DEAD: begin
         //   for (i = 0; i < 50; i = i + 1) begin
         //        @(posedge clk);
         //   end
                counter_next = counter + 1'b1;
                tlast[random] = 1'b0;
         	tvalid_0 = 0;
	        tvalid_1 = 0;
		tvalid_2 = 0;
		tvalid_3 = 0;
		tvalid_4 = 0;
                if(counter[3]==1'b1) begin
                   counter_next = 8'b0;
		           random = 0; //$random % 5;  // lock to 0 for easier debugging
                   if (random == 0)  begin  //do a read op
                     state_next = HEADER_0a;
                     $display("Next random = %d", random);
                   end
                   else begin
                     state_next = HEADER_0;
                   end

                end
            end
        endcase
    end

    always @(posedge clk) begin
        if(reset) begin
            state <= HEADER_0;
            counter <= 8'b0;
        end
        else begin
            state <= state_next;
            counter <= counter_next;
        end
    end

  initial begin
      clk   = 1'b0;

      $display("[%t] : System Reset Asserted...", $realtime);
      $dumpfile("ualink_turbo64_tb.vcd");
      $dumpvars(0, testbench);

      reset = 1'b1;
      for (i = 0; i < 2; i = i + 1) begin
                 @(posedge clk);
      end
      $display("[%t] : System Reset De-asserted...", $realtime);
      reset = 1'b0;
      $display("\n========================================");
      $display("All Tests Completed!");
      $display("========================================");
      #3000  ;    $finish;       //end simulation
  end

  always #2.5  clk = ~clk;      // 200MHz



  ualink_turbo64 
    #(.C_M_AXIS_DATA_WIDTH(64),
      .C_S_AXIS_DATA_WIDTH(64),
      .C_M_AXIS_TUSER_WIDTH(128),
      .C_S_AXIS_TUSER_WIDTH(128)
     ) in_arb
    (
    // Global Ports
    .axi_aclk(clk),
    .axi_resetn(~reset),

    // Master Stream Ports
    .m_axis_tdata(),
    .m_axis_tstrb(),
    .m_axis_tvalid(),
    .m_axis_tready(1'b1),
    .m_axis_tlast(),

    // Slave Stream Ports
    .s_axis_tdata_0(tdata[0]),
    .s_axis_tuser_0(128'hAA),
    .s_axis_tstrb_0(8'hFF),
    .s_axis_tvalid_0(tvalid_0),
    .s_axis_tready_0(tready[0]),
    .s_axis_tlast_0(tlast[0]),

    .s_axis_tdata_1(tdata[1]),
    .s_axis_tuser_1(128'hAA),
    .s_axis_tstrb_1(8'hFF),
    .s_axis_tvalid_1(tvalid_1),
    .s_axis_tready_1(tready[1]),
    .s_axis_tlast_1(tlast[1]),

    .s_axis_tdata_2(tdata[2]),
    .s_axis_tuser_2(128'hAA),
    .s_axis_tstrb_2(8'hFF),
    .s_axis_tvalid_2(tvalid_2),
    .s_axis_tready_2(tready[2]),
    .s_axis_tlast_2(tlast[2]),

    .s_axis_tdata_3(tdata[3]),
    .s_axis_tuser_3(128'hAA),
    .s_axis_tstrb_3(8'hFF),
    .s_axis_tvalid_3(tvalid_3),
    .s_axis_tready_3(tready[3]),
    .s_axis_tlast_3(tlast[3]),

    .s_axis_tdata_4(tdata[4]),
    .s_axis_tuser_4(128'hAA),
    .s_axis_tstrb_4(8'hFF),
    .s_axis_tvalid_4(tvalid_4),
    .s_axis_tready_4(tready[4]),
    .s_axis_tlast_4(tlast[4])

   );



endmodule
