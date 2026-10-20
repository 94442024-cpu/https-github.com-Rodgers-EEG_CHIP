# EEG Convolution Accelerator SoC

A fabrication-oriented RISC-V SoC for accelerating convolution and FIR filtering of EEG signals.

## Current Status

Project setup. Phase 1 is the RV32I single-cycle host core. The design will be developed and verified in simulation before synthesis, FPGA validation, and any possible silicon submission.

## Planned System

```text
RISC-V host core <-> bus/interconnect <-> instruction/data memory
                                      <-> convolution accelerator
                                      <-> DMA controller
                                      <-> interrupt controller
```

The RISC-V core controls the system. The convolution accelerator performs the repeated multiply-accumulate work used by the EEG signal-processing pipeline. DMA will later move larger EEG buffers without involving the CPU in every transfer.

## Repository Layout

- `rtl/`: synthesizable Verilog RTL
- `tb/`: cocotb testbenches and simulation harnesses
- `models/`: Python golden/reference models
- `sw/`: firmware, drivers, and test programs
- `docs/`: architecture, memory maps, and project plans
- `sim/`: simulator scripts and generated waveforms

## Development Rules

1. Define the behavior in a Python golden model before writing RTL.
2. Use self-checking cocotb tests; waveforms are for debugging failures.
3. Test in this order: directed, randomized, then representative EEG data.
4. Re-run module tests after integration.
5. Keep register interfaces and memory maps documented as they are created.
6. Do not claim fabrication readiness until RTL, verification, synthesis, timing, and physical-design checks have passed.

## First Milestone

Implement and verify the RV32I single-cycle core in `rtl/core/`. See [docs/project-plan.md](docs/project-plan.md).

## Local Tooling

The initial verification flow is intended to use:

- Icarus Verilog or Verilator
- cocotb
- Python and NumPy
- GTKWave for waveform debugging
- RISC-V GCC for compiled software tests

Tool versions and exact commands will be pinned as the project becomes executable.
