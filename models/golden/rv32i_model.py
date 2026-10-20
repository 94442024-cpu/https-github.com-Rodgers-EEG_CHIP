"""Small executable reference model for the Phase 1 RV32I core."""

from __future__ import annotations

from dataclasses import dataclass, field

MASK32 = 0xFFFFFFFF
MEMORY_SIZE = 4096


def u32(value: int) -> int:
    return value & MASK32


def s32(value: int) -> int:
    value &= MASK32
    return value if value < 0x80000000 else value - 0x100000000


def sign_extend(value: int, bits: int) -> int:
    sign = 1 << (bits - 1)
    value &= (1 << bits) - 1
    return value - (1 << bits) if value & sign else value


@dataclass
class RV32IModel:
    program: list[int] = field(default_factory=list)
    memory: bytearray = field(default_factory=lambda: bytearray(MEMORY_SIZE))
    registers: list[int] = field(default_factory=lambda: [0] * 32)
    pc: int = 0
    halted: bool = False

    def __post_init__(self) -> None:
        self.program = [u32(instruction) for instruction in self.program]
        self.load_program(self.program)

    def reset(self) -> None:
        self.memory[:] = b"\x00" * len(self.memory)
        self.registers[:] = [0] * 32
        self.pc = 0
        self.halted = False

    def load_word(self, address: int) -> int:
        self._check_memory(address, 4)
        return int.from_bytes(self.memory[address : address + 4], "little")

    def store_word(self, address: int, value: int) -> None:
        self._check_memory(address, 4)
        self.memory[address : address + 4] = u32(value).to_bytes(4, "little")

    def load_program(self, program: list[int], address: int = 0) -> None:
        for offset, instruction in enumerate(program):
            self.store_word(address + offset * 4, instruction)

    def step(self) -> None:
        if self.halted:
            return

        instruction = self.load_word(self.pc)
        opcode = instruction & 0x7F
        rd = (instruction >> 7) & 0x1F
        funct3 = (instruction >> 12) & 0x07
        rs1 = (instruction >> 15) & 0x1F
        rs2 = (instruction >> 20) & 0x1F
        funct7 = (instruction >> 25) & 0x7F
        current_pc = self.pc
        next_pc = u32(current_pc + 4)
        write_register: tuple[int, int] | None = None

        if opcode == 0x37:  # LUI
            write_register = (rd, instruction & 0xFFFFF000)
        elif opcode == 0x17:  # AUIPC
            write_register = (rd, current_pc + (instruction & 0xFFFFF000))
        elif opcode == 0x13:  # OP-IMM
            immediate = sign_extend(instruction >> 20, 12)
            value = self.registers[rs1]
            if funct3 == 0x0:
                result = value + immediate
            elif funct3 == 0x2:
                result = int(s32(value) < immediate)
            elif funct3 == 0x3:
                result = int(value < u32(immediate))
            elif funct3 == 0x4:
                result = value ^ immediate
            elif funct3 == 0x6:
                result = value | immediate
            elif funct3 == 0x7:
                result = value & immediate
            elif funct3 == 0x1:
                result = value << ((instruction >> 20) & 0x1F)
            elif funct3 == 0x5 and funct7 == 0x00:
                result = value >> ((instruction >> 20) & 0x1F)
            elif funct3 == 0x5 and funct7 == 0x20:
                result = s32(value) >> ((instruction >> 20) & 0x1F)
            else:
                raise ValueError(f"unsupported OP-IMM instruction 0x{instruction:08x}")
            write_register = (rd, result)
        elif opcode == 0x33:  # OP
            left = self.registers[rs1]
            right = self.registers[rs2]
            if funct3 == 0x0 and funct7 == 0x00:
                result = left + right
            elif funct3 == 0x0 and funct7 == 0x20:
                result = left - right
            elif funct3 == 0x1:
                result = left << (right & 0x1F)
            elif funct3 == 0x2:
                result = int(s32(left) < s32(right))
            elif funct3 == 0x3:
                result = int(left < right)
            elif funct3 == 0x4:
                result = left ^ right
            elif funct3 == 0x5 and funct7 == 0x00:
                result = left >> (right & 0x1F)
            elif funct3 == 0x5 and funct7 == 0x20:
                result = s32(left) >> (right & 0x1F)
            elif funct3 == 0x6:
                result = left | right
            elif funct3 == 0x7:
                result = left & right
            else:
                raise ValueError(f"unsupported OP instruction 0x{instruction:08x}")
            write_register = (rd, result)
        elif opcode == 0x03:  # LOAD
            address = u32(self.registers[rs1] + sign_extend(instruction >> 20, 12))
            if funct3 == 0x0:
                result = sign_extend(self._load_unsigned(address, 1), 8)
            elif funct3 == 0x1:
                result = sign_extend(self._load_unsigned(address, 2), 16)
            elif funct3 == 0x2:
                result = self._load_unsigned(address, 4)
            elif funct3 == 0x4:
                result = self._load_unsigned(address, 1)
            elif funct3 == 0x5:
                result = self._load_unsigned(address, 2)
            else:
                raise ValueError(f"unsupported LOAD instruction 0x{instruction:08x}")
            write_register = (rd, result)
        elif opcode == 0x23:  # STORE
            immediate = sign_extend(((instruction >> 25) << 5) | ((instruction >> 7) & 0x1F), 12)
            address = u32(self.registers[rs1] + immediate)
            if funct3 == 0x0:
                width = 1
            elif funct3 == 0x1:
                width = 2
            elif funct3 == 0x2:
                width = 4
            else:
                raise ValueError(f"unsupported STORE instruction 0x{instruction:08x}")
            self._store(address, self.registers[rs2], width)
        elif opcode == 0x63:  # BRANCH
            immediate = sign_extend(
                (((instruction >> 31) & 0x1) << 12)
                | (((instruction >> 7) & 0x1) << 11)
                | (((instruction >> 25) & 0x3F) << 5)
                | ((instruction >> 8) & 0xF) << 1,
                13,
            )
            left = self.registers[rs1]
            right = self.registers[rs2]
            taken = {
                0x0: left == right,
                0x1: left != right,
                0x4: s32(left) < s32(right),
                0x5: s32(left) >= s32(right),
                0x6: left < right,
                0x7: left >= right,
            }.get(funct3)
            if taken is None:
                raise ValueError(f"unsupported BRANCH instruction 0x{instruction:08x}")
            if taken:
                next_pc = u32(current_pc + immediate)
        elif opcode == 0x6F:  # JAL
            immediate = sign_extend(
                (((instruction >> 31) & 0x1) << 20)
                | (((instruction >> 12) & 0xFF) << 12)
                | (((instruction >> 20) & 0x1) << 11)
                | (((instruction >> 21) & 0x3FF) << 1),
                21,
            )
            write_register = (rd, next_pc)
            next_pc = u32(current_pc + immediate)
        elif opcode == 0x67 and funct3 == 0x0:  # JALR
            immediate = sign_extend(instruction >> 20, 12)
            write_register = (rd, next_pc)
            next_pc = u32(self.registers[rs1] + immediate) & ~1
        else:
            raise ValueError(f"unsupported instruction 0x{instruction:08x} at PC 0x{current_pc:08x}")

        if write_register is not None and write_register[0] != 0:
            self.registers[write_register[0]] = u32(write_register[1])
        self.registers[0] = 0
        self.pc = next_pc

    def run(self, steps: int) -> None:
        for _ in range(steps):
            self.step()

    def _load_unsigned(self, address: int, width: int) -> int:
        self._check_memory(address, width)
        return int.from_bytes(self.memory[address : address + width], "little")

    def _store(self, address: int, value: int, width: int) -> None:
        self._check_memory(address, width)
        self.memory[address : address + width] = u32(value).to_bytes(4, "little")[:width]

    def _check_memory(self, address: int, width: int) -> None:
        if address < 0 or address + width > len(self.memory):
            raise IndexError(f"memory access out of range: 0x{address:08x} (+{width})")
        if width in (2, 4) and address % width:
            raise ValueError(f"misaligned {width}-byte access at 0x{address:08x}")
