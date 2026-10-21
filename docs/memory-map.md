# Memory Map

This document will become the authoritative address map for the integrated SoC.

## Phase 1: Local Simulation Memories

The first CPU milestone uses separate simulation-local memories. They are not yet connected through the system bus.

| Memory | Default size | Address range | Access |
|---|---:|---|---|
| Instruction memory | 4 KiB | `0x00000000`-`0x00000FFC` | 32-bit word fetch |
| Data memory | 4 KiB | `0x00000000`-`0x00000FFF` | Byte-addressable |

These are physically separate memories, so the same numeric address in instruction and data memory refers to different storage.

Data memory is little-endian. Naturally aligned byte, halfword, and word accesses are supported. Misaligned accesses, traps, CSRs, exceptions, and privileged-mode behavior are outside Phase 1.

## Future Integrated Map

The Phase 2 Wishbone decoder reserves these non-overlapping regions:

| Region | Address range | Initial function |
|---|---|---|
| Main memory | `0x00000000`-`0x0000FFFF` | Instruction/data memory target |
| Accelerator | `0x40000000`-`0x40000FFF` | Convolution accelerator registers/data |
| DMA controller | `0x40001000`-`0x40001FFF` | DMA control/status registers |

Unmapped addresses return a bus error. The final system address map may refine the memory window, but the peripheral regions are reserved now so software interfaces remain stable.

The integrated system must provide non-overlapping regions for:

- Instruction/data memory
- Convolution accelerator registers and data ports
- DMA controller registers
- Interrupt controller
- Any debug or status peripherals

## Accelerator Registers

Offsets are relative to `0x40000000`:

| Offset | Register | Description |
|---:|---|---|
| `0x00` | CONTROL | Write bit 0 to start; readback of control bits |
| `0x04` | STATUS | Bit 0 busy, bit 1 done; write bit 0 to clear done |
| `0x08` | SAMPLE0 | Signed 32-bit input sample, tap 0 |
| `0x0C` | COEFF0 | Signed 32-bit coefficient, tap 0 |
| `0x10` | RESULT | Signed 32-bit result |
| `0x14` | SAMPLE1 | Signed 32-bit input sample, tap 1 |
| `0x18` | COEFF1 | Signed 32-bit coefficient, tap 1 |
| `0x1C` | SAMPLE2 | Signed 32-bit input sample, tap 2 |
| `0x20` | COEFF2 | Signed 32-bit coefficient, tap 2 |
| `0x24` | SAMPLE3 | Signed 32-bit input sample, tap 3 |
| `0x28` | COEFF3 | Signed 32-bit coefficient, tap 3 |

The initial register block performs a one-cycle four-tap signed accumulation. The streaming and DMA versions will preserve this register contract where practical.

## Streaming Interface

The streaming datapath accepts one signed 32-bit sample whenever `sample_valid_i` and `sample_ready_o` are high. It keeps the newest sample at tap zero and emits `result_valid_o` after the fourth sample and for every subsequent sample. Coefficients are supplied as four signed 32-bit inputs.
