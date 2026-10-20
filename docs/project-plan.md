# Project Plan

## Objective

Build and verify a RISC-V-hosted SoC that accelerates convolution/FIR filtering for EEG signals, then measure whether the hardware is a useful alternative to the existing MCU implementation.

## Phases

### Phase 0: Foundation

- [x] Create repository structure and development rules
- [ ] Select and document simulator/tool versions
- [x] Add the first Python golden-model conventions
- [x] Add continuous-integration checks

### Phase 1: RV32I Host Core

- [ ] Implement instruction formats and immediate generation
- [ ] Implement 32 x 32-bit register file with hardwired `x0`
- [ ] Implement ALU and control decoding
- [ ] Implement instruction and data memories for simulation
- [ ] Implement branches, jumps, loads, and stores
- [ ] Add directed and randomized cocotb tests
- [ ] Run a relevant RV32I compliance subset

### Phase 2: Bus Infrastructure

- [ ] Define the system address map
- [ ] Add a Wishbone or AXI-lite interconnect
- [ ] Add address decoding and peripheral responses
- [ ] Preserve Phase 1 core tests through integration

### Phase 3: Convolution Accelerator

- [ ] Define the register and streaming interfaces
- [ ] Create a Python/NumPy reference model
- [ ] Implement fixed-point arithmetic and MAC datapath
- [ ] Add shift-register/window buffering
- [ ] Add single-channel and multi-channel tests
- [ ] Validate using representative EEG data

### Phase 4: DMA and Control

- [ ] Implement memory-to-accelerator transfers
- [ ] Define DMA control/status registers
- [ ] Add interrupt signaling and completion handling
- [ ] Add firmware drivers and an end-to-end test

### Phase 5: Integration and Measurement

- [ ] Run full SoC simulation
- [ ] Synthesize and review area/timing reports
- [ ] Compare latency, energy, and accuracy with the STM32 baseline
- [ ] Validate on FPGA where practical
- [ ] Assess Tiny Tapeout eligibility and physical-design readiness

## Verification Strategy

Every module follows the sequence: Python reference behavior, directed tests, randomized tests, integration regression, and representative EEG data where applicable.

## Completed Milestones

- RV32I Python reference model with arithmetic, memory, branch, jump, and register-zero semantics
- Focused unit tests for arithmetic, `x0`, little-endian loads/stores, sign/zero extension, and taken branches
- Initial Verilog ALU and register-file RTL with a self-checking simulator testbench
- Combinational RV32I control decoder with memory, branch, jump, immediate, and write-back controls
- Immediate generator covering I, S, B, U, and J instruction formats
- Separate instruction/data memories and an integrated single-cycle `riscv_core` smoke-test target
- Cocotb core regression scaffolded to compare DUT registers and memory against the Python model
- Cocotb coverage for byte/halfword access widths, sign/zero extension, and immediate shifts
