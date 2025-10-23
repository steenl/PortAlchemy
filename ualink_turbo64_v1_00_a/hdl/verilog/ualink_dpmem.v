/*******************************************************************************
 *
 *  Licence:
 *        This file is part of the NetFPGA 10G development base package.
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
input wire axi_aclk,  //common clock for port A and B
input  wire                     axi_resetn,      // enable for port A (active high)
input  wire                    we_a,      // write enable for port A (active high)
input  wire [DPADDR_WIDTH-1:0]    addr_a,
input  wire [DPDATA_WIDTH-1:0]    din_a,
output reg [DPDATA_WIDTH-1:0]    dout_a,

    // Port B

    input  wire                     we_b,      // write enable for port B (active high)
    input  wire [DPADDR_WIDTH-1:0]    addr_b,
    input  wire [DPDATA_WIDTH-1:0]    din_b,
    output reg  [DPDATA_WIDTH-1:0]    dout_b
);


// Memory declaration
reg [DPDATA_WIDTH-1:0] dpmem [0:DPDEPTH-1];
// Optional synthesis attribute for inferred block RAM (vendor-specific)
// (* ram_style = "block" *) reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
reg we_a_reg, we_b_reg;
reg [DPADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
reg [DPDATA_WIDTH-1:0] din_a_reg, din_b_reg;
reg [DPDATA_WIDTH-1:0] dout_a_reg;
reg [DPDATA_WIDTH-1:0] dout_b_reg;

always @(*) begin
        we_a_reg = we_a;
        we_b_reg = we_b;
        addr_a_reg = addr_a;
        addr_b_reg = addr_b;
        din_a_reg = din_a;
        din_b_reg = din_b;

end


// Port A logic (synchronous)
// Write-first behavior: when a write occurs on port A, dout_a returns the written data immediately.
  always @(posedge axi_aclk) begin
    if (!axi_resetn) begin  //initialize memory at reset
        dout_a <= "CAFEcafe";
        we_a_reg   <= 0;
        addr_a_reg <= 0;
        din_a_reg  <= 0;
        // dout_b <= 0;
        we_b_reg   <= 0;
        addr_b_reg <= 0;
        din_b_reg  <= 0;
        // for (i=0; i<DEPTH; i=i+1) begin
        //     mem[i] <= 0;
        // end
      end else begin
      if (we_a) begin
         dpmem[addr_a] <= din_a;
         dout_a <= din_a;  // write-first: read returns new data
         end else begin
         dout_a <= dpmem[addr_a];    // synchronous read
         end
      end
    end
	 // Port B logic (synchronous)
  // Write-first behavior on port B as well.
  always @(posedge axi_aclk) begin
    if (axi_resetn) begin
      if (we_b) begin
        dpmem[addr_b] <= din_b;
        dout_b <= din_b;
      end else begin
        dout_b <= dpmem[addr_b];
        end
		end
  end
// Notes:
// - If both ports write the same address in the same cycle (in the same or different clocks), the final value is implementation-dependent / undefined.
// - To infer true dual-port block RAM on your FPGA, check vendor guidance (attributes or IP generator). The commented ram_style attribute is supported by some toolchains.
// - If you prefer read-first behavior, set dout <= mem[addr] before mem[addr] <= din (change assignment order in the write branch).
endmodule
