# PortAlchemy AI Coding Guidelines

## Project Overview
PortAlchemy is a high-performance networking project leveraging NetFPGA-10GbE infrastructure for UALink interconnects between CPUs, GPUs, and memory pools. It achieves 200+Gbps throughput with prioritized queuing, targeting RISC-V and memory architectures on real FPGAs.

## Architecture
- **FPGA Layer**: Verilog IP cores handle packet processing acceleration
  - `ualink_turbo64_v1_00_a/`: Main UALink arbitration and packet processing core
  - `nf10_bram_output_queues_v1_00_a/`: BRAM-based output queue management
  - `nf10_nic_output_port_lookup_v1_00_a/`: NIC output port lookup logic
- **User-Space Layer**: C++ library (`CustomEth/`) for raw packet manipulation via AF_PACKET sockets
- **Data Flow**: NIC → FPGA processing → AF_PACKET → CustomEth library → Application

## Key Components
- **ualink_fma.v**: 8x8 matrix FMA operations with memory interface
- **packet.h/layers.h**: Packet crafting with composable layers (Ethernet/IP/UDP/Memcached)
- **udp_memcached_AF_PACKET.cpp**: Raw socket memcached client bypassing kernel stack

## Development Workflows
### Verilog Testing
Run all tests before commits: `./scripts/run_all_tests.sh`
- Compiles with `iverilog`, simulates with `vvp`
- Testbenches: `ualink_turbo64_tb`, `ualink_turbordwr_tb`, `ualink_dpmem_tb`
- Example: `iverilog -o ualink_fma.vvp ualink_fma.v; vvp ualink_fma.vvp`

### FPGA Synthesis
Use root `Makefile` (Xilinx EDK-based) for hardware builds
- Includes `system_incl.make` for project configuration
- Deprecated software flow; prefer Xilinx SDK for new projects

### C++ Packet Handling
- Build with `g++ udp_memcached_AF_PACKET.cpp` (requires root for AF_PACKET)
- Use `CustomEth/include/` for packet structures
- Raw sockets bypass kernel for performance

## Coding Conventions
### Verilog
- Use Verilog-2001 syntax with flat packed arrays
- Module naming: `ualink_*` for UALink components, `nf10_*` for NetFPGA cores
- Testbenches named `*_tb.v` with matching `*_tb.vvp` outputs
- Include VCD generation for GTKWave debugging

### C++
- AF_PACKET sockets for raw Ethernet access (requires sudo)
- Packet composition using `/` operator: `Ethernet() / IP() / UDP() / Memcached()`
- Manual checksum calculation for performance
- Error handling with `die()` function for critical failures

## Integration Points
- **Memory Interface**: Dual-port BRAM for matrix operations in FMA
- **AXI Stream**: For read/write operations in turbo cores
- **AF_PACKET**: Linux raw socket interface for user-space packet I/O
- **Memcached Protocol**: UDP-based key-value operations over custom Ethernet

## Testing Strategy
- Pre-commit: Run `./scripts/run_all_tests.sh` locally
- CI/CD: GitHub Actions parallel matrix testing (6 testbenches)
- Waveform artifacts stored on failures for 7 days
- Python result parsing in test scripts

## Dependencies
- **FPGA**: Icarus Verilog (iverilog/vvp), GTKWave for waveforms
- **C++**: GCC, Linux headers for AF_PACKET
- **External**: Memcached server for UDP testing

## Common Patterns
- Matrix operations use 64-element 8x8 layout with base addressing
- Packet headers built manually for zero-copy performance
- FSM-based control in Verilog modules with `start_*`/`done_*` signals
- Raw socket setup requires interface name and IP configuration</content>
<parameter name="filePath">c:/Source/PortAlchemy/.github/copilot-instructions.md