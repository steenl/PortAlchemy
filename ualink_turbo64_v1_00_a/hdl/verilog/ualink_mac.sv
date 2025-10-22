// mac_unit.sv Dean 2025 - Single-Cycle MAC Unit

module mac_unit #(
    parameter DATA_WIDTH = 16,
    parameter ARRAY_SIZE = 8
)(
    input wire clk,
    input wire rst,
    input wire start_mac,
    // Memory Port B interface
    output reg [7:0] addrb,
    output reg enb,
    input wire [63:0] doutb_a, // Data out from memory for array_a
    input wire [63:0] doutb_b, // Data out from memory for array_b
    // Control and result
    output reg [2*DATA_WIDTH-1:0] mac_result,
    output reg status_done
);

    // No need for mac_index or accumulator in single-cycle version

    // Combinational MAC calculation for single-cycle operation
    function [2*DATA_WIDTH-1:0] mac4;
        input [63:0] a_packed, b_packed;
        reg [DATA_WIDTH-1:0] a [0:3];
        reg [DATA_WIDTH-1:0] b [0:3];
        integer i;
        reg [2*DATA_WIDTH-1:0] acc;
        begin
            a[0] = a_packed[15:0];
            a[1] = a_packed[31:16];
            a[2] = a_packed[47:32];
            a[3] = a_packed[63:48];
            b[0] = b_packed[15:0];
            b[1] = b_packed[31:16];
            b[2] = b_packed[47:32];
            b[3] = b_packed[63:48];
            acc = 0;
            for (i = 0; i < 4; i = i + 1) begin
                acc = acc + a[i] * b[i];
            end
            mac4 = acc;
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mac_result <= 0;
            status_done <= 0;
            addrb <= 0;
            enb <= 0;
        end else if (start_mac) begin
            mac_result <= mac4(doutb_a, doutb_b);
            status_done <= 1;
            enb <= 0;
        end else begin
            status_done <= 0;
            enb <= 0;
        end
    end

endmodule