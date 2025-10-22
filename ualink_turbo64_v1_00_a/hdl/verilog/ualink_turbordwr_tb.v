//Partially AI generated, tests DPMEM read/write operations via AXI Stream interface

// iverilog -o ualink_turbordwr_tb.vvp  ualink_turbordwr_tb.v  ualink_turbo64.v .\fallthrough_small_fifo_v2.v .\small_fifo_v3.v .\ualink_dpmem.v  
// vvp .\ualink_turbordwr_tb.vvp  
// gtkwave.exe .\ualink_turbo64.vcd

`timescale 1ns / 1ps

module tb_ualink_turbo64;

    // Parameters
    parameter C_M_AXIS_DATA_WIDTH = 64;
    parameter C_S_AXIS_DATA_WIDTH = 64;
    parameter C_M_AXIS_TUSER_WIDTH = 32;
    parameter C_S_AXIS_TUSER_WIDTH = 32;
    parameter NUM_QUEUES = 5;
    parameter DPADDR_WIDTH = 8;
    parameter DPDATA_WIDTH = 64;
    parameter DPDEPTH = (1 << DPADDR_WIDTH);
    parameter CLK_PERIOD = 10; // 10ns = 100MHz

    // Testbench signals
    reg axi_aclk;
    reg axi_resetn;

    // Master Stream Ports
    wire [C_M_AXIS_DATA_WIDTH - 1:0] m_axis_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tstrb;
    wire [C_M_AXIS_TUSER_WIDTH-1:0] m_axis_tuser;
    wire m_axis_tvalid;
    reg  m_axis_tready;
    wire m_axis_tlast;

    // Slave Stream Ports (Port 0 - we'll primarily use this)
    reg [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata_0;
    reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tstrb_0;
    reg [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser_0;
    reg  s_axis_tvalid_0;
    wire s_axis_tready_0;
    reg  s_axis_tlast_0;

    // Other slave ports (unused in this test, tied off)
    reg [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata_1;
    reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tstrb_1;
    reg [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser_1;
    reg  s_axis_tvalid_1;
    wire s_axis_tready_1;
    reg  s_axis_tlast_1;

    reg [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata_2;
    reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tstrb_2;
    reg [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser_2;
    reg  s_axis_tvalid_2;
    wire s_axis_tready_2;
    reg  s_axis_tlast_2;

    reg [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata_3;
    reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tstrb_3;
    reg [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser_3;
    reg  s_axis_tvalid_3;
    wire s_axis_tready_3;
    reg  s_axis_tlast_3;

    reg [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata_4;
    reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tstrb_4;
    reg [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser_4;
    reg  s_axis_tvalid_4;
    wire s_axis_tready_4;
    reg  s_axis_tlast_4;

    // Debug outputs (not monitored in this basic test)
    wire LED03;
    wire CS_empty0;
    wire CS_state0, CS_state1, CS_state2, CS_state3;
    wire CS_we_a, CS_addr_a0, CS_din_a0;
    wire CS_m_axis_tvalid, CS_m_axis_tready, CS_m_axis_tlast;
    wire CS_s_axis_tvalid_0, CS_s_axis_tready_0, CS_s_axis_tlast_0;
    wire [63:0] cs_m_axis_tdata_debug;
    wire [63:0] cs_s_axis_tdata_debug;

    // Instantiate the DUT
    ualink_turbo64 #(
        .C_M_AXIS_DATA_WIDTH(C_M_AXIS_DATA_WIDTH),
        .C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
        .C_M_AXIS_TUSER_WIDTH(C_M_AXIS_TUSER_WIDTH),
        .C_S_AXIS_TUSER_WIDTH(C_S_AXIS_TUSER_WIDTH),
        .NUM_QUEUES(NUM_QUEUES),
        .DPADDR_WIDTH(DPADDR_WIDTH),
        .DPDATA_WIDTH(DPDATA_WIDTH),
        .DPDEPTH(DPDEPTH)
    ) dut (
        .axi_aclk(axi_aclk),
        .axi_resetn(axi_resetn),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tstrb(m_axis_tstrb),
        .m_axis_tuser(m_axis_tuser),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .s_axis_tdata_0(s_axis_tdata_0),
        .s_axis_tstrb_0(s_axis_tstrb_0),
        .s_axis_tuser_0(s_axis_tuser_0),
        .s_axis_tvalid_0(s_axis_tvalid_0),
        .s_axis_tready_0(s_axis_tready_0),
        .s_axis_tlast_0(s_axis_tlast_0),
        .s_axis_tdata_1(s_axis_tdata_1),
        .s_axis_tstrb_1(s_axis_tstrb_1),
        .s_axis_tuser_1(s_axis_tuser_1),
        .s_axis_tvalid_1(s_axis_tvalid_1),
        .s_axis_tready_1(s_axis_tready_1),
        .s_axis_tlast_1(s_axis_tlast_1),
        .s_axis_tdata_2(s_axis_tdata_2),
        .s_axis_tstrb_2(s_axis_tstrb_2),
        .s_axis_tuser_2(s_axis_tuser_2),
        .s_axis_tvalid_2(s_axis_tvalid_2),
        .s_axis_tready_2(s_axis_tready_2),
        .s_axis_tlast_2(s_axis_tlast_2),
        .s_axis_tdata_3(s_axis_tdata_3),
        .s_axis_tstrb_3(s_axis_tstrb_3),
        .s_axis_tuser_3(s_axis_tuser_3),
        .s_axis_tvalid_3(s_axis_tvalid_3),
        .s_axis_tready_3(s_axis_tready_3),
        .s_axis_tlast_3(s_axis_tlast_3),
        .s_axis_tdata_4(s_axis_tdata_4),
        .s_axis_tstrb_4(s_axis_tstrb_4),
        .s_axis_tuser_4(s_axis_tuser_4),
        .s_axis_tvalid_4(s_axis_tvalid_4),
        .s_axis_tready_4(s_axis_tready_4),
        .s_axis_tlast_4(s_axis_tlast_4),
        .LED03(LED03),
        .CS_empty0(CS_empty0),
        .CS_state0(CS_state0),
        .CS_state1(CS_state1),
        .CS_state2(CS_state2),
        .CS_state3(CS_state3),
        .CS_we_a(CS_we_a),
        .CS_addr_a0(CS_addr_a0),
        .CS_din_a0(CS_din_a0),
        .CS_m_axis_tvalid(CS_m_axis_tvalid),
        .CS_m_axis_tready(CS_m_axis_tready),
        .CS_m_axis_tlast(CS_m_axis_tlast),
        .CS_s_axis_tvalid_0(CS_s_axis_tvalid_0),
        .CS_s_axis_tready_0(CS_s_axis_tready_0),
        .CS_s_axis_tlast_0(CS_s_axis_tlast_0),
        .CS_M_AXIS_TDATA0(cs_m_axis_tdata_debug[0]),
        .CS_M_AXIS_TDATA1(cs_m_axis_tdata_debug[1]),
        .CS_M_AXIS_TDATA2(cs_m_axis_tdata_debug[2]),
        .CS_M_AXIS_TDATA3(cs_m_axis_tdata_debug[3]),
        .CS_M_AXIS_TDATA4(cs_m_axis_tdata_debug[4]),
        .CS_M_AXIS_TDATA5(cs_m_axis_tdata_debug[5]),
        .CS_M_AXIS_TDATA6(cs_m_axis_tdata_debug[6]),
        .CS_M_AXIS_TDATA7(cs_m_axis_tdata_debug[7]),
        .CS_M_AXIS_TDATA8(cs_m_axis_tdata_debug[8]),
        .CS_M_AXIS_TDATA9(cs_m_axis_tdata_debug[9]),
        .CS_M_AXIS_TDATA10(cs_m_axis_tdata_debug[10]),
        .CS_M_AXIS_TDATA11(cs_m_axis_tdata_debug[11]),
        .CS_M_AXIS_TDATA12(cs_m_axis_tdata_debug[12]),
        .CS_M_AXIS_TDATA13(cs_m_axis_tdata_debug[13]),
        .CS_M_AXIS_TDATA14(cs_m_axis_tdata_debug[14]),
        .CS_M_AXIS_TDATA15(cs_m_axis_tdata_debug[15]),
        .CS_M_AXIS_TDATA16(cs_m_axis_tdata_debug[16]),
        .CS_M_AXIS_TDATA17(cs_m_axis_tdata_debug[17]),
        .CS_M_AXIS_TDATA18(cs_m_axis_tdata_debug[18]),
        .CS_M_AXIS_TDATA19(cs_m_axis_tdata_debug[19]),
        .CS_M_AXIS_TDATA20(cs_m_axis_tdata_debug[20]),
        .CS_M_AXIS_TDATA21(cs_m_axis_tdata_debug[21]),
        .CS_M_AXIS_TDATA22(cs_m_axis_tdata_debug[22]),
        .CS_M_AXIS_TDATA23(cs_m_axis_tdata_debug[23]),
        .CS_M_AXIS_TDATA24(cs_m_axis_tdata_debug[24]),
        .CS_M_AXIS_TDATA25(cs_m_axis_tdata_debug[25]),
        .CS_M_AXIS_TDATA26(cs_m_axis_tdata_debug[26]),
        .CS_M_AXIS_TDATA27(cs_m_axis_tdata_debug[27]),
        .CS_M_AXIS_TDATA28(cs_m_axis_tdata_debug[28]),
        .CS_M_AXIS_TDATA29(cs_m_axis_tdata_debug[29]),
        .CS_M_AXIS_TDATA30(cs_m_axis_tdata_debug[30]),
        .CS_M_AXIS_TDATA31(cs_m_axis_tdata_debug[31]),
        .CS_M_AXIS_TDATA32(cs_m_axis_tdata_debug[32]),
        .CS_M_AXIS_TDATA33(cs_m_axis_tdata_debug[33]),
        .CS_M_AXIS_TDATA34(cs_m_axis_tdata_debug[34]),
        .CS_M_AXIS_TDATA35(cs_m_axis_tdata_debug[35]),
        .CS_M_AXIS_TDATA36(cs_m_axis_tdata_debug[36]),
        .CS_M_AXIS_TDATA37(cs_m_axis_tdata_debug[37]),
        .CS_M_AXIS_TDATA38(cs_m_axis_tdata_debug[38]),
        .CS_M_AXIS_TDATA39(cs_m_axis_tdata_debug[39]),
        .CS_M_AXIS_TDATA40(cs_m_axis_tdata_debug[40]),
        .CS_M_AXIS_TDATA41(cs_m_axis_tdata_debug[41]),
        .CS_M_AXIS_TDATA42(cs_m_axis_tdata_debug[42]),
        .CS_M_AXIS_TDATA43(cs_m_axis_tdata_debug[43]),
        .CS_M_AXIS_TDATA44(cs_m_axis_tdata_debug[44]),
        .CS_M_AXIS_TDATA45(cs_m_axis_tdata_debug[45]),
        .CS_M_AXIS_TDATA46(cs_m_axis_tdata_debug[46]),
        .CS_M_AXIS_TDATA47(cs_m_axis_tdata_debug[47]),
        .CS_M_AXIS_TDATA48(cs_m_axis_tdata_debug[48]),
        .CS_M_AXIS_TDATA49(cs_m_axis_tdata_debug[49]),
        .CS_M_AXIS_TDATA50(cs_m_axis_tdata_debug[50]),
        .CS_M_AXIS_TDATA51(cs_m_axis_tdata_debug[51]),
        .CS_M_AXIS_TDATA52(cs_m_axis_tdata_debug[52]),
        .CS_M_AXIS_TDATA53(cs_m_axis_tdata_debug[53]),
        .CS_M_AXIS_TDATA54(cs_m_axis_tdata_debug[54]),
        .CS_M_AXIS_TDATA55(cs_m_axis_tdata_debug[55]),
        .CS_M_AXIS_TDATA56(cs_m_axis_tdata_debug[56]),
        .CS_M_AXIS_TDATA57(cs_m_axis_tdata_debug[57]),
        .CS_M_AXIS_TDATA58(cs_m_axis_tdata_debug[58]),
        .CS_M_AXIS_TDATA59(cs_m_axis_tdata_debug[59]),
        .CS_M_AXIS_TDATA60(cs_m_axis_tdata_debug[60]),
        .CS_M_AXIS_TDATA61(cs_m_axis_tdata_debug[61]),
        .CS_M_AXIS_TDATA62(cs_m_axis_tdata_debug[62]),
        .CS_M_AXIS_TDATA63(cs_m_axis_tdata_debug[63]),
        .CS_S_AXIS_TDATA0(cs_s_axis_tdata_debug[0]),
        .CS_S_AXIS_TDATA1(cs_s_axis_tdata_debug[1]),
        .CS_S_AXIS_TDATA2(cs_s_axis_tdata_debug[2]),
        .CS_S_AXIS_TDATA3(cs_s_axis_tdata_debug[3]),
        .CS_S_AXIS_TDATA4(cs_s_axis_tdata_debug[4]),
        .CS_S_AXIS_TDATA5(cs_s_axis_tdata_debug[5]),
        .CS_S_AXIS_TDATA6(cs_s_axis_tdata_debug[6]),
        .CS_S_AXIS_TDATA7(cs_s_axis_tdata_debug[7]),
        .CS_S_AXIS_TDATA8(cs_s_axis_tdata_debug[8]),
        .CS_S_AXIS_TDATA9(cs_s_axis_tdata_debug[9]),
        .CS_S_AXIS_TDATA10(cs_s_axis_tdata_debug[10]),
        .CS_S_AXIS_TDATA11(cs_s_axis_tdata_debug[11]),
        .CS_S_AXIS_TDATA12(cs_s_axis_tdata_debug[12]),
        .CS_S_AXIS_TDATA13(cs_s_axis_tdata_debug[13]),
        .CS_S_AXIS_TDATA14(cs_s_axis_tdata_debug[14]),
        .CS_S_AXIS_TDATA15(cs_s_axis_tdata_debug[15]),
        .CS_S_AXIS_TDATA16(cs_s_axis_tdata_debug[16]),
        .CS_S_AXIS_TDATA17(cs_s_axis_tdata_debug[17]),
        .CS_S_AXIS_TDATA18(cs_s_axis_tdata_debug[18]),
        .CS_S_AXIS_TDATA19(cs_s_axis_tdata_debug[19]),
        .CS_S_AXIS_TDATA20(cs_s_axis_tdata_debug[20]),
        .CS_S_AXIS_TDATA21(cs_s_axis_tdata_debug[21]),
        .CS_S_AXIS_TDATA22(cs_s_axis_tdata_debug[22]),
        .CS_S_AXIS_TDATA23(cs_s_axis_tdata_debug[23]),
        .CS_S_AXIS_TDATA24(cs_s_axis_tdata_debug[24]),
        .CS_S_AXIS_TDATA25(cs_s_axis_tdata_debug[25]),
        .CS_S_AXIS_TDATA26(cs_s_axis_tdata_debug[26]),
        .CS_S_AXIS_TDATA27(cs_s_axis_tdata_debug[27]),
        .CS_S_AXIS_TDATA28(cs_s_axis_tdata_debug[28]),
        .CS_S_AXIS_TDATA29(cs_s_axis_tdata_debug[29]),
        .CS_S_AXIS_TDATA30(cs_s_axis_tdata_debug[30]),
        .CS_S_AXIS_TDATA31(cs_s_axis_tdata_debug[31]),
        .CS_S_AXIS_TDATA32(cs_s_axis_tdata_debug[32]),
        .CS_S_AXIS_TDATA33(cs_s_axis_tdata_debug[33]),
        .CS_S_AXIS_TDATA34(cs_s_axis_tdata_debug[34]),
        .CS_S_AXIS_TDATA35(cs_s_axis_tdata_debug[35]),
        .CS_S_AXIS_TDATA36(cs_s_axis_tdata_debug[36]),
        .CS_S_AXIS_TDATA37(cs_s_axis_tdata_debug[37]),
        .CS_S_AXIS_TDATA38(cs_s_axis_tdata_debug[38]),
        .CS_S_AXIS_TDATA39(cs_s_axis_tdata_debug[39]),
        .CS_S_AXIS_TDATA40(cs_s_axis_tdata_debug[40]),
        .CS_S_AXIS_TDATA41(cs_s_axis_tdata_debug[41]),
        .CS_S_AXIS_TDATA42(cs_s_axis_tdata_debug[42]),
        .CS_S_AXIS_TDATA43(cs_s_axis_tdata_debug[43]),
        .CS_S_AXIS_TDATA44(cs_s_axis_tdata_debug[44]),
        .CS_S_AXIS_TDATA45(cs_s_axis_tdata_debug[45]),
        .CS_S_AXIS_TDATA46(cs_s_axis_tdata_debug[46]),
        .CS_S_AXIS_TDATA47(cs_s_axis_tdata_debug[47]),
        .CS_S_AXIS_TDATA48(cs_s_axis_tdata_debug[48]),
        .CS_S_AXIS_TDATA49(cs_s_axis_tdata_debug[49]),
        .CS_S_AXIS_TDATA50(cs_s_axis_tdata_debug[50]),
        .CS_S_AXIS_TDATA51(cs_s_axis_tdata_debug[51]),
        .CS_S_AXIS_TDATA52(cs_s_axis_tdata_debug[52]),
        .CS_S_AXIS_TDATA53(cs_s_axis_tdata_debug[53]),
        .CS_S_AXIS_TDATA54(cs_s_axis_tdata_debug[54]),
        .CS_S_AXIS_TDATA55(cs_s_axis_tdata_debug[55]),
        .CS_S_AXIS_TDATA56(cs_s_axis_tdata_debug[56]),
        .CS_S_AXIS_TDATA57(cs_s_axis_tdata_debug[57]),
        .CS_S_AXIS_TDATA58(cs_s_axis_tdata_debug[58]),
        .CS_S_AXIS_TDATA59(cs_s_axis_tdata_debug[59]),
        .CS_S_AXIS_TDATA60(cs_s_axis_tdata_debug[60]),
        .CS_S_AXIS_TDATA61(cs_s_axis_tdata_debug[61]),
        .CS_S_AXIS_TDATA62(cs_s_axis_tdata_debug[62]),
        .CS_S_AXIS_TDATA63(cs_s_axis_tdata_debug[63])
    );

    // Clock generation
    initial begin
        axi_aclk = 0;
        forever #(CLK_PERIOD/2) axi_aclk = ~axi_aclk;
    end

    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("ualink_turbo64_tb.vcd");
        $dumpvars(0, tb_ualink_turbo64);
        
        $display("========================================");
        $display("UALink Turbo64 Testbench Started");
        $display("Testing DPMEM through AXI Stream");
        $display("========================================");
        
        // Initialize all signals
        initialize_signals();
        
        // Apply reset
        axi_resetn = 0;
        #(CLK_PERIOD*5);
        axi_resetn = 1;
        #(CLK_PERIOD*2);
        
        // Test 1: Write to dual port RAM (opcode 0x0245)
        $display("\n=== Test 1: Memory Write Operation (opcode 0x0245) ===");
        send_write_packet(64'hDEADBEEF_CAFEBEEF);
        #(CLK_PERIOD*20);
       
        // Test 2: Read from dual port RAM (opcode 0x0145)
        $display("\n=== Test 2: Memory Read Operation (opcode 0x0145) ===");
        send_read_packet();
        #(CLK_PERIOD*30);
        
        // Test 3: Multiple write operations
        $display("\n=== Test 3: Multiple Write Operations ===");
        send_write_packet(64'h1111111111111111);
        #(CLK_PERIOD*20);
        send_write_packet(64'h2222222222222222);
        #(CLK_PERIOD*20);
        
        // Test 4: Read after multiple writes
        $display("\n=== Test 4: Read After Multiple Writes ===");
        send_read_packet();
        #(CLK_PERIOD*30);
    /*    
        // Test 5: Burst write and read
        $display("\n=== Test 5: Burst Write-Read Sequence ===");
        send_write_packet(64'hAAAAAAAA_BBBBBBBB);
        #(CLK_PERIOD*5);
        send_read_packet();
        #(CLK_PERIOD*30);
        
        // Test 6: Back pressure test (m_axis_tready toggling)
        $display("\n=== Test 6: Back Pressure Test ===");
        fork
            begin
                send_write_packet(64'hCCCCCCCC_DDDDDDDD);
            end
            begin
                repeat(5) begin
                    #(CLK_PERIOD*3);
                    m_axis_tready = 0;
                    #(CLK_PERIOD*2);
                    m_axis_tready = 1;
                end
            end
        join
        #(CLK_PERIOD*20);
        */
        $display("\n========================================");
        $display("All Tests Completed!");
        $display("========================================");
        #(CLK_PERIOD*10);
        $finish;
    end

    // Task: Initialize all signals
    task initialize_signals;
        begin
            m_axis_tready = 1;
            
            s_axis_tdata_0 = 0;
            s_axis_tstrb_0 = 8'hFF;
            s_axis_tuser_0 = 0;
            s_axis_tvalid_0 = 0;
            s_axis_tlast_0 = 0;
            
            s_axis_tdata_1 = 0;
            s_axis_tstrb_1 = 8'hFF;
            s_axis_tuser_1 = 0;
            s_axis_tvalid_1 = 0;
            s_axis_tlast_1 = 0;
            
            s_axis_tdata_2 = 0;
            s_axis_tstrb_2 = 8'hFF;
            s_axis_tuser_2 = 0;
            s_axis_tvalid_2 = 0;
            s_axis_tlast_2 = 0;
            
            s_axis_tdata_3 = 0;
            s_axis_tstrb_3 = 8'hFF;
            s_axis_tuser_3 = 0;
            s_axis_tvalid_3 = 0;
            s_axis_tlast_3 = 0;
            
            s_axis_tdata_4 = 0;
            s_axis_tstrb_4 = 8'hFF;
            s_axis_tuser_4 = 0;
            s_axis_tvalid_4 = 0;
            s_axis_tlast_4 = 0;
        end
    endtask

    // Task: Send write packet to dual port RAM
    // Packet format: [header1] [header2] [header3 with opcode 0x0245] [data]
    task send_write_packet;
        input [63:0] write_data;
        begin
            $display("  Sending write packet: data=0x%h", write_data);
            
            // Word 1: Header
            @(posedge axi_aclk);
            s_axis_tdata_0 = 64'h0000000000000001;
            s_axis_tvalid_0 = 1;
            s_axis_tlast_0 = 0;
            wait(s_axis_tready_0);
            
            // Word 2: Header
            @(posedge axi_aclk);
            s_axis_tdata_0 = 64'h0000000000000002;
            
            // Word 3: Header with write opcode (0x0245 in upper 16 bits)
            @(posedge axi_aclk);
            s_axis_tdata_0 = 64'h0245000000000003;
            
            // Word 4: Data to write
            @(posedge axi_aclk);
            s_axis_tdata_0 = write_data;
            s_axis_tlast_0 = 1;
            
            // Deassert after last word
            @(posedge axi_aclk);
            s_axis_tvalid_0 = 0;
            s_axis_tlast_0 = 0;
            s_axis_tdata_0 = 0;
            
            $display("  Write packet sent");
        end
    endtask

    // Task: Send read packet to dual port RAM
    // Packet format: [header1] [header2] [header3 with opcode 0x0145] [dummy]
    task send_read_packet;
        begin
            $display("  Sending read packet");
            
            // Word 1: Header
            @(posedge axi_aclk);
            s_axis_tdata_0 = 64'h0000000000000001;
            s_axis_tvalid_0 = 1;
            s_axis_tlast_0 = 0;
            wait(s_axis_tready_0);
            
            // Word 2: Header
            @(posedge axi_aclk);
            s_axis_tdata_0 = 64'h0000000000000002;
            
            // Word 3: Header with read opcode (0x0145 in upper 16 bits)
            @(posedge axi_aclk);
            s_axis_tdata_0 = 64'h0145000000000003;
            
            // Word 4: Dummy data for read command
            @(posedge axi_aclk);
            s_axis_tdata_0 = 64'h0000000000000000;
            s_axis_tlast_0 = 1;
            
            // Deassert after last word
            @(posedge axi_aclk);
            s_axis_tvalid_0 = 0;
            s_axis_tlast_0 = 0;
            s_axis_tdata_0 = 0;
            
            $display("  Read packet sent, waiting for response...");
        end
    endtask

    // Monitor master axis output
    always @(posedge axi_aclk) begin
        if (axi_resetn && m_axis_tvalid && m_axis_tready) begin
            $display("  [Master Output] tdata=0x%h, tlast=%b, time=%t", 
                     m_axis_tdata, m_axis_tlast, $time);
        end
    end

    // Monitor state changes
    reg [3:0] prev_state;
    initial prev_state = 4'b0000;
    
    always @(posedge axi_aclk) begin
        if (axi_resetn) begin
            if ({CS_state3, CS_state2, CS_state1, CS_state0} != prev_state) begin
                prev_state = {CS_state3, CS_state2, CS_state1, CS_state0};
                case(prev_state)
                    4'b0001: $display("  [State Change] -> IDLE");
                    4'b0010: $display("  [State Change] -> WR_PKT");
                    4'b0100: $display("  [State Change] -> READ_OPc1");
                    4'b1000: $display("  [State Change] -> READ_OPc2");
                    default: $display("  [State Change] -> State 0x%h", prev_state);
                endcase
            end
        end
    end

    // Monitor memory write enable
    always @(posedge axi_aclk) begin
        if (axi_resetn && CS_we_a) begin
            $display("  [DPMEM Write] we_a asserted at time=%t", $time);
        end
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 10000);
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule