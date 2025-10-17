`timescale 1ns / 1ps

module mac_unit_tb;

    parameter DATA_WIDTH = 16;
    parameter ARRAY_SIZE = 8;

    reg clk;
    reg rst;
    reg start_mac;
    reg [63:0] doutb_a;
    reg [63:0] doutb_b;
    wire [2*DATA_WIDTH-1:0] mac_result;
    wire status_done;

    integer i;

    // Arrays for testing
    reg [DATA_WIDTH-1:0] array_a [0:ARRAY_SIZE-1];
    reg [DATA_WIDTH-1:0] array_b [0:ARRAY_SIZE-1];

    // Instantiate MAC unit
    mac_unit uut (
        .clk(clk),
        .rst(rst),
        .start_mac(start_mac),
        .doutb_a(doutb_a),
        .doutb_b(doutb_b),
        .mac_result(mac_result),
        .status_done(status_done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task run_mac_test;
        input [8*32-1:0] test_name; // 32-char string
        begin
            rst = 1;
            start_mac = 0;
            #20 rst = 0;

            // Print initial arrays before operation
            $display("%s: Initial array_a:", test_name);
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                $display("  array_a[%0d] = %0d", i, array_a[i]);
            end
            $display("%s: Initial array_b:", test_name);
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                $display("  array_b[%0d] = %0d", i, array_b[i]);
            end

            // Pack all values into 64-bit words
            doutb_a = {array_a[3], array_a[2], array_a[1], array_a[0]};
            doutb_b = {array_b[3], array_b[2], array_b[1], array_b[0]};

            // Check status_done before starting MAC
            $display("%s: status_done before start = %b", test_name, status_done);

            start_mac = 1;
            #10 start_mac = 0;

            // Optionally, check status_done during operation (should be 0)
            #10;
            $display("%s: status_done during operation = %b", test_name, status_done);

            wait(status_done);
            #10;

            // Check status_done after operation (should be 1)
            $display("%s: status_done after operation = %b", test_name, status_done);
            $display("%s: MAC Result = %d", test_name, mac_result);
        end
    endtask

    initial begin
        // Test 1: Sequential
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            array_a[i] = i + 1;
            array_b[i] = i + 2;
        end
        run_mac_test("Test 1 - Sequential");

        // Test 2: Zeros
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            array_a[i] = 0;
            array_b[i] = 0;
        end
        run_mac_test("Test 2 - Zeros");

        // Test 3: Ones
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            array_a[i] = 1;
            array_b[i] = 1;
        end
        run_mac_test("Test 3 - Ones");

        // Test 4: Alternating
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            array_a[i] = (i % 2 == 0) ? 1 : 2;
            array_b[i] = (i % 2 == 0) ? 3 : 4;
        end
        run_mac_test("Test 4 - Alternating");

        // Test 5: Max values
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            array_a[i] = 16'hFFFF;
            array_b[i] = 16'hFFFF;
        end
        run_mac_test("Test 5 - Max");

        $finish;
    end

endmodule
