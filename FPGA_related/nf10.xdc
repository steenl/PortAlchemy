# UALink FPGA Constraints File for Vivado
# Adapted from Xilinx ISE .xdc format 
# Steen Larsen 2026 
#

# Peripheral reset - timing ignore
set_false_path -from [get_ports Peripheral_aresetn]

# Pin assignments
set_property PACKAGE_PIN AL24 [get_ports RESET]
set_property IOSTANDARD LVCMOS33 [get_ports RESET]
set_property PULLUP TRUE [get_ports RESET]
set_false_path -from [get_ports RESET]

set_property PACKAGE_PIN BB23 [get_ports RS232_Uart_1_sin]
set_property IOSTANDARD LVCMOS33 [get_ports RS232_Uart_1_sin]

set_property PACKAGE_PIN BB21 [get_ports RS232_Uart_1_sout]
set_property IOSTANDARD LVCMOS33 [get_ports RS232_Uart_1_sout]

set_property PACKAGE_PIN AN25 [get_ports CLK]
set_property IOSTANDARD LVCMOS33 [get_ports CLK]

set_property PACKAGE_PIN AK23 [get_ports MDC]
set_property IOSTANDARD LVCMOS33 [get_ports MDC]

set_property PACKAGE_PIN AL20 [get_ports MDIO]
set_property IOSTANDARD LVCMOS33 [get_ports MDIO]

set_property PACKAGE_PIN AR20 [get_ports PHY_RST_N]
set_property IOSTANDARD LVCMOS33 [get_ports PHY_RST_N]
set_property PULLUP TRUE [get_ports PHY_RST_N]

# Clock constraints
create_clock -name sys_clk_pin -period 10.000 [get_ports CLK]

# Timing ignore for clock domain crossings
set_false_path -from [get_clocks core_clk] -to [get_clocks dma_0/dma_0/trn_clk_c]
set_false_path -from [get_clocks dma_0/dma_0/trn_clk_c] -to [get_clocks core_clk]
set_false_path -from [get_clocks control_clk] -to [get_clocks dma_0/dma_0/trn_clk_c]
set_false_path -from [get_clocks dma_0/dma_0/trn_clk_c] -to [get_clocks control_clk]
set_false_path -from [get_clocks control_clk] -to [get_clocks core_clk]
set_false_path -from [get_clocks core_clk] -to [get_clocks control_clk]

# GTX PLACEMENT
set_property LOC GTX_DUAL_X1Y6 [get_cells nf10_10g_interface_0/nf10_10g_interface_0/xaui_block/rocketio_wrapper_i/tile0_rocketio_wrapper_i/USE_REVERSE_LANES.gtx_dual_i]
set_property LOC GTX_DUAL_X1Y7 [get_cells nf10_10g_interface_0/nf10_10g_interface_0/xaui_block/rocketio_wrapper_i/tile1_rocketio_wrapper_i/USE_REVERSE_LANES.gtx_dual_i]
set_property LOC GTX_DUAL_X1Y8 [get_cells nf10_10g_interface_1/nf10_10g_interface_1/xaui_block/rocketio_wrapper_i/tile0_rocketio_wrapper_i/USE_REVERSE_LANES.gtx_dual_i]
set_property LOC GTX_DUAL_X1Y9 [get_cells nf10_10g_interface_1/nf10_10g_interface_1/xaui_block/rocketio_wrapper_i/tile1_rocketio_wrapper_i/USE_REVERSE_LANES.gtx_dual_i]
set_property LOC GTX_DUAL_X1Y10 [get_cells nf10_10g_interface_2/nf10_10g_interface_2/xaui_block/rocketio_wrapper_i/tile0_rocketio_wrapper_i/USE_REVERSE_LANES.gtx_dual_i]
set_property LOC GTX_DUAL_X1Y11 [get_cells nf10_10g_interface_2/nf10_10g_interface_2/xaui_block/rocketio_wrapper_i/tile1_rocketio_wrapper_i/USE_REVERSE_LANES.gtx_dual_i]
set_property LOC GTX_DUAL_X0Y11 [get_cells nf10_10g_interface_3/nf10_10g_interface_3/xaui_block/rocketio_wrapper_i/tile0_rocketio_wrapper_i/NO_REVERSE_LANES.gtx_dual_i]
set_property LOC GTX_DUAL_X0Y10 [get_cells nf10_10g_interface_3/nf10_10g_interface_3/xaui_block/rocketio_wrapper_i/tile1_rocketio_wrapper_i/NO_REVERSE_LANES.gtx_dual_i]

# Reference clocks
set_property PACKAGE_PIN M4 [get_ports refclk_A_p]
set_property PACKAGE_PIN M3 [get_ports refclk_A_n]
set_property PACKAGE_PIN C4 [get_ports refclk_B_p]
set_property PACKAGE_PIN C3 [get_ports refclk_B_n]
set_property PACKAGE_PIN D16 [get_ports refclk_C_p]
set_property PACKAGE_PIN C16 [get_ports refclk_C_n]
set_property PACKAGE_PIN D27 [get_ports refclk_D_p]
set_property PACKAGE_PIN C27 [get_ports refclk_D_n]

# Clock constraints for 10G interfaces
create_clock -name clk156_top -period 6.4 [get_pins nf10_10g_interface_0/nf10_10g_interface_0/clk156]
create_clock -name clk156_rec -period 6.4 [get_pins nf10_10g_interface_0/nf10_10g_interface_0/xaui_block/rocketio_wrapper_i/tile1_rxrecclk0_i]

# Note: The complex timing constraints for MAC interfaces (false paths, etc.) would need manual review
# and conversion as they reference specific internal signals that may not exist in the same form
# in Vivado. These constraints may need to be adapted based on the actual design hierarchy.

# PCIe constraints
set_property PACKAGE_PIN AT4 [get_ports pcie_clk_p]
set_property PACKAGE_PIN AT3 [get_ports pcie_clk_n]
set_property DIFF_TERM TRUE [get_cells dma_0/dma_0/pcie_clk_ibuf]
set_property LOC GTX_DUAL_X1Y5 [get_cells dma_0/dma_0/ep/pcie_ep0/pcie_blk/SIO/.pcie_gt_wrapper_i/GTD[0].GT_i]
set_property LOC GTX_DUAL_X1Y4 [get_cells dma_0/dma_0/ep/pcie_ep0/pcie_blk/SIO/.pcie_gt_wrapper_i/GTD[2].GT_i]
set_property LOC GTX_DUAL_X1Y3 [get_cells dma_0/dma_0/ep/pcie_ep0/pcie_blk/SIO/.pcie_gt_wrapper_i/GTD[4].GT_i]
set_property LOC GTX_DUAL_X1Y2 [get_cells dma_0/dma_0/ep/pcie_ep0/pcie_blk/SIO/.pcie_gt_wrapper_i/GTD[6].GT_i]

# BlockRAM placement
set_property LOC RAMB36_X5Y20 [get_cells dma_0/dma_0/ep/pcie_ep0/pcie_blk/pcie_mim_wrapper_i/bram_retry/generate_sdp.ram_sdp_inst]
set_property LOC RAMB36_X5Y19 [get_cells dma_0/dma_0/ep/pcie_ep0/pcie_blk/pcie_mim_wrapper_i/bram_tl_tx/generate_tdp2[1].ram_tdp2_inst]
set_property LOC RAMB36_X5Y18 [get_cells dma_0/dma_0/ep/pcie_ep0/pcie_blk/pcie_mim_wrapper_i/bram_tl_rx/generate_tdp2[1].ram_tdp2_inst]
set_property LOC RAMB36_X5Y17 [get_cells dma_0/dma_0/ep/pcie_ep0/pcie_blk/pcie_mim_wrapper_i/bram_tl_tx/generate_tdp2[0].ram_tdp2_inst]
set_property LOC RAMB36_X5Y16 [get_cells dma_0/dma_0/ep/pcie_ep0/pcie_blk/pcie_mim_wrapper_i/bram_tl_rx/generate_tdp2[0].ram_tdp2_inst]
set_property LOC RAMB36_X5Y15 [get_cells dma_0/dma_0/ep/pcie_ep0/pcie_blk_if/ll_bridge/rx_bridge/fifo_inst/oq_fifo/Mram_regBank]

# LED
set_property PACKAGE_PIN AP20 [get_ports nf10_input_arbiter_0_LED03_pin]
set_property IOSTANDARD LVCMOS33 [get_ports nf10_input_arbiter_0_LED03_pin]

# PCIe clock
create_clock -name MGTCLK -period 10.000 [get_pins dma_0/dma_0/ep/pcie_ep0/pcie_blk/SIO/.pcie_gt_wrapper_i/gt_refclk_out[0]]

# Note: Some constraints may need adjustment based on the actual Vivado design structure
# The complex MAC timing constraints have been omitted as they reference ISE-specific
# internal signals that may not be applicable in Vivado.