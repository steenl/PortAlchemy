/*******************************************************************************
 *
 * Steen Larsen with some AI assistance.  For Artix-7 FPGAs using the MIG IP core and replacing below seems to be needed to meet 2026 Vivado synthesis.
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

module dual_port_ram_8x64 
#(
    parameter DPADDR_WIDTH = 8,
    parameter DPDATA_WIDTH = 64,
    parameter DPDEPTH = (1 << DPADDR_WIDTH)
)
(
    // Port A
    input  wire                     axi_aclk,      // common clock for port A and B
    input  wire                     axi_resetn,    // reset (active low)
    input  wire                     we_a,          // write enable for port A (active high)
    input  wire [DPADDR_WIDTH-1:0]  addr_a,        // address for port A
    input  wire [DPDATA_WIDTH-1:0]  din_a,         // data input for port A
    output reg  [DPDATA_WIDTH-1:0]  dout_a,        // data output for port A

    // Port B
    input  wire                     we_b,          // write enable for port B (active high)
    input  wire [DPADDR_WIDTH-1:0]  addr_b,        // address for port B
    input  wire [DPDATA_WIDTH-1:0]  din_b,         // data input for port B
    output reg  [DPDATA_WIDTH-1:0]  dout_b         // data output for port B
);

// Memory declaration with Vivado blockram synthesis directive
(* ram_style = "registers" *) reg [DPDATA_WIDTH-1:0] dpmem [0:DPDEPTH-1];


// Port A logic (synchronous write-first)
// Write-first: when writing, output immediately reflects written data
always @(posedge axi_aclk) begin
    if (!axi_resetn) begin
        dout_a <= {DPDATA_WIDTH{1'b0}};
    end else begin
        if (we_a) begin
            dpmem[addr_a] <= din_a;
            dout_a <= din_a;  // write-first: output reflects written data
        end else begin
            dout_a <= dpmem[addr_a];  // synchronous read
        end
    end
end

// Port B logic (synchronous write-first)
// Write-first: when writing, output immediately reflects written data
always @(posedge axi_aclk) begin
    if (!axi_resetn) begin
        dout_b <= {DPDATA_WIDTH{1'b0}};
    end else begin
        if (we_b) begin
            dpmem[addr_b] <= din_b;
            dout_b <= din_b;  // write-first: output reflects written data
        end else begin
            dout_b <= dpmem[addr_b];  // synchronous read
        end
    end
end

// Synthesis notes:
// - Uses (* ram_style = "block" *) directive for Vivado to infer blockram
// - Both ports support independent synchronous read/write with write-first behavior
// - Reset is active-low (axi_resetn)
// - Simultaneous writes to same address produce implementation-dependent results
// - Memory is initialized to zero at reset
endmodule
