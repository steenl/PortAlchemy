# PortAlchemy
Focus on UALink usage cases interconnecting CPUs, GPUs, and memory pools.  Leveraged from prior NetFPGA10GbE work, we scale to 200+Gbps with prioritized queueing between customized RISC-V and memory targets on real FPGAs and fabrics.

For some of the motivation see: https://medium.com/@steen.knud.larsen/why-ualink-could-change-memory-architecture-82f2d6c2e67f

In addition to basic RTL simulation we are validating in an older Virtex5 FPGA which has certain constraints.  This approach drives to having IP blocks such as Ethernet MAC XAUI and port arbitration.  A benefit is seeing how the hardware actually instantiates as well as signals between IP blocks. 


If you want to simulate basic transactions, (like a hello world check) install icarus and follow instructions below in the folder ualink_turbo64_v1_00_a/hdl/verilog:

> iverilog -o ualink_turbo64_tb.vvp .\ualink_turbo64_tb.v ualink_turbo64.v .\fallthrough_small_fifo_v2.v .\small_fifo_v3.v .\ualink_dpmem.v
> 
> vvp ualink_turbo64_tb.vvp
> 
> gtkwave.exe .\ualink_turbo_tb.vcd

Before checking in any code, ensure scripts/run_all_tests.sh pass