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
