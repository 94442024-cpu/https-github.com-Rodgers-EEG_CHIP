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

The final system address map will be defined when the bus is added. It must reserve non-overlapping regions for:

- Instruction/data memory
- Convolution accelerator registers and data ports
- DMA controller registers
- Interrupt controller
- Any debug or status peripherals
