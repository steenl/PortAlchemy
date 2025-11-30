`timescale 1ns / 1ps

module tb_dual_port_ram_8x64;

    // Parameters
    parameter DPADDR_WIDTH = 8;
    parameter DPDATA_WIDTH = 64;
    parameter DPDEPTH = (1 << DPADDR_WIDTH);
    parameter CLK_PERIOD = 10; // 10ns clock period (100MHz)

    // Testbench signals
    reg axi_aclk;
    reg axi_resetn;
    
    // Port A signals
    reg we_a;
    reg [DPADDR_WIDTH-1:0] addr_a;
    reg [DPDATA_WIDTH-1:0] din_a;
    wire [DPDATA_WIDTH-1:0] dout_a;
    
    // Port B signals
    reg we_b;
    reg [DPADDR_WIDTH-1:0] addr_b;
    reg [DPDATA_WIDTH-1:0] din_b;
    wire [DPDATA_WIDTH-1:0] dout_b;

    // Instantiate the DUT (Device Under Test)
    dual_port_ram_8x64 #(
        .DPADDR_WIDTH(DPADDR_WIDTH),
        .DPDATA_WIDTH(DPDATA_WIDTH),
        .DPDEPTH(DPDEPTH)
    ) dut (
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

    // Clock generation
    initial begin
        axi_aclk = 0;
        forever #(CLK_PERIOD/2) axi_aclk = ~axi_aclk;
    end

    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("ualink_dpmem_tb.vcd");
        $dumpvars(0, tb_dual_port_ram_8x64);
        
        // Initialize signals
        axi_resetn = 0;
        we_a = 0;
        addr_a = 0;
        din_a = 0;
        we_b = 0;
        addr_b = 0;
        din_b = 0;
        
        $display("========================================");
        $display("Dual Port RAM Testbench Started");
        $display("========================================");
        
        // Apply reset
        #(CLK_PERIOD*2);
        axi_resetn = 1;
        #(CLK_PERIOD);
        
        // Test 1: Write to Port A, Read from Port A
        $display("\nTest 1: Port A Write and Read");
        write_port_a(8'h10, 64'hDEADBEEF_CAFEBABE);
        #(CLK_PERIOD);
        read_port_a(8'h10);
        #(CLK_PERIOD*2);
        
        // Test 2: Write to Port B, Read from Port B (if Port B write is implemented)
        $display("\nTest 2: Port B operations (Note: Port B write is commented out in module)");
        write_port_b(8'h20, 64'h12345678_9ABCDEF0);
        #(CLK_PERIOD);
        read_port_b(8'h20);
        #(CLK_PERIOD*2);
        
        // Test 3: Multiple writes to Port A
        $display("\nTest 3: Multiple writes to Port A");
        write_port_a(8'h00, 64'h0000000000000001);
        write_port_a(8'h01, 64'h0000000000000002);
        write_port_a(8'h02, 64'h0000000000000004);
        write_port_a(8'h03, 64'h0000000000000008);
        #(CLK_PERIOD);
        
        // Test 4: Sequential reads from Port A
        $display("\nTest 4: Sequential reads from Port A");
        read_port_a(8'h00);
        #(CLK_PERIOD);
        read_port_a(8'h01);
        #(CLK_PERIOD);
        read_port_a(8'h02);
        #(CLK_PERIOD);
        read_port_a(8'h03);
        #(CLK_PERIOD);
        
        // Test 5: Write-first behavior test
        $display("\nTest 5: Write-first behavior (should see BEEFbeef on write)");
        write_port_a(8'h50, 64'hAAAAAAAA_BBBBBBBB);
        #(CLK_PERIOD);
        $display("  dout_a after write = 0x%h (expected BEEFbeef)", dout_a);
        read_port_a(8'h50);
        #(CLK_PERIOD);
        $display("  dout_a after read = 0x%h (expected AAAAAAAA_BBBBBBBB)", dout_a);
        #(CLK_PERIOD);
        
        // Test 6: Simultaneous access to different addresses
        $display("\nTest 6: Simultaneous Port A and Port B access (different addresses)");
        fork
            write_port_a(8'hA0, 64'h1111111111111111);
            read_port_b(8'h10);
        join
        #(CLK_PERIOD*2);
        
        // Test 7: Same address access (potential conflict)
        $display("\nTest 7: Same address access from both ports");
        write_port_a(8'hFF, 64'hFFFFFFFFFFFFFFFF);
        #(CLK_PERIOD);
        fork
            read_port_a(8'hFF);
            read_port_b(8'hFF);
        join
        #(CLK_PERIOD*2);
        
/*
        
        // Test 9: Reset during operation
        $display("\nTest 9: Reset test");
        write_port_a(8'h55, 64'hBEFORE_RESET_DATA);
        #(CLK_PERIOD);
        axi_resetn = 0;
        #(CLK_PERIOD*2);
        $display("  dout_a during reset = 0x%h (expected CAFEcafe)", dout_a);
        axi_resetn = 1;
        #(CLK_PERIOD);
        read_port_a(8'h55);
        #(CLK_PERIOD*2);
   
        // Test 10: Burst write and read
        $display("\nTest 10: Burst write and read test");
        burst_write_port_a(8'h80, 16); // Write 16 locations starting at 0x80
        #(CLK_PERIOD);
        burst_read_port_a(8'h80, 16);  // Read back 16 locations
        #(CLK_PERIOD*2);
     */  
        // End simulation
        $display("\n========================================");
        $display("All tests completed!");
        $display("========================================");
        #(CLK_PERIOD*5);
        $finish;
    end

    // Task: Write to Port A
    task write_port_a;
        input [DPADDR_WIDTH-1:0] address;
        input [DPDATA_WIDTH-1:0] data;
        begin
            @(posedge axi_aclk);
            we_a = 1;
            addr_a = address;
            din_a = data;
            $display("  [Port A Write] Addr=0x%h, Data=0x%h", address, data);
            @(posedge axi_aclk);
            we_a = 0;
        end
    endtask

    // Task: Read from Port A
    task read_port_a;
        input [DPADDR_WIDTH-1:0] address;
        begin
            @(posedge axi_aclk);
            we_a = 0;
            addr_a = address;
            @(posedge axi_aclk);
            #1; // Small delay to allow output to settle
            $display("  [Port A Read]  Addr=0x%h, Data=0x%h", address, dout_a);
        end
    endtask

    // Task: Write to Port B
    task write_port_b;
        input [DPADDR_WIDTH-1:0] address;
        input [DPDATA_WIDTH-1:0] data;
        begin
            @(posedge axi_aclk);
            we_b = 1;
            addr_b = address;
            din_b = data;
            $display("  [Port B Write] Addr=0x%h, Data=0x%h", address, data);
            @(posedge axi_aclk);
            we_b = 0;
        end
    endtask

    // Task: Read from Port B
    task read_port_b;
        input [DPADDR_WIDTH-1:0] address;
        begin
            @(posedge axi_aclk);
            we_b = 0;
            addr_b = address;
            @(posedge axi_aclk);
            #1; // Small delay to allow output to settle
            $display("  [Port B Read]  Addr=0x%h, Data=0x%h", address, dout_b);
        end
    endtask

 /*   // Task: Burst write to Port A
    task burst_write_port_a;
        input [DPADDR_WIDTH-1:0] start_addr;
        input integer count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                write_port_a(start_addr + i, {32'h0000, 32'(start_addr + i)});
            end
        end
    endtask

    // Task: Burst read from Port A
    task burst_read_port_a;
        input [DPADDR_WIDTH-1:0] start_addr;
        input integer count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                read_port_a(start_addr + i);
            end
        end
    endtask
*/
    // Monitor for detecting unexpected changes
    always @(posedge axi_aclk) begin
        if (axi_resetn && we_a) begin
            #1;
            if (dout_a !== 64'hBEEFbeef) begin
                $display("  WARNING: Write-first behavior violation at time %t", $time);
            end
        end
    end

endmodule