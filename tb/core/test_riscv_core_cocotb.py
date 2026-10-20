import sys
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

sys.path.insert(0, str(Path(__file__).parents[2] / "models" / "golden"))
from rv32i_model import RV32IModel


def i_type(imm, rs1, funct3, rd, opcode=0x13):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def r_type(funct7, rs2, rs1, funct3, rd):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x33


def s_type(imm, rs2, rs1, funct3):
    return (((imm >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | ((imm & 0x1F) << 7) | 0x23


def b_type(offset, rs2, rs1, funct3):
    return (((offset >> 12) & 1) << 31) | (((offset >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (((offset >> 1) & 0xF) << 8) | (((offset >> 11) & 1) << 7) | 0x63


def u_type(value, rd, opcode):
    return (value & 0xFFFFF000) | (rd << 7) | opcode


def j_type(offset, rd):
    return (((offset >> 20) & 1) << 31) | (((offset >> 12) & 0xFF) << 12) | (((offset >> 11) & 1) << 20) | (((offset >> 1) & 0x3FF) << 21) | (rd << 7) | 0x6F


async def write_program(dut, program):
    for index, instruction in enumerate(program):
        dut.instruction_memory.memory[index].value = instruction


@cocotb.test()
async def test_core_matches_golden_model(dut):
    program = [
        i_type(5, 0, 0, 1),
        i_type(7, 0, 0, 2),
        r_type(0, 2, 1, 0, 3),
        r_type(0x20, 1, 3, 0, 4),
        r_type(0, 2, 1, 7, 5),
        r_type(0, 2, 1, 6, 6),
        r_type(0, 2, 1, 4, 7),
        i_type(0x100, 0, 0, 8),
        s_type(0, 3, 8, 2),
        i_type(0, 8, 2, 9, 0x03),
        b_type(8, 9, 3, 0),
        i_type(1, 0, 0, 10),
        i_type(2, 0, 0, 10),
        u_type(0x12345000, 11, 0x37),
        j_type(8, 12),
        i_type(3, 0, 0, 12),
        i_type(4, 0, 0, 12),
        0x00000013,
    ]
    model = RV32IModel(program)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await write_program(dut, program)
    dut.reset.value = 1
    await Timer(12, units="ns")
    dut.reset.value = 0

    for _ in range(16):
        model.step()
        await RisingEdge(dut.clk)

    await Timer(1, units="ns")
    for register in (1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12):
        actual = int(dut.register_file.registers[register].value)
        assert actual == model.registers[register], f"x{register}: {actual:#x} != {model.registers[register]:#x}"
    assert int(dut.register_file.registers[0].value) == 0
    assert int(dut.data_memory.memory[0x100].value) == model.memory[0x100]


@cocotb.test()
async def test_core_load_store_widths_and_shifts(dut):
    program = [
        i_type(0x200, 0, 0, 1),
        i_type(-1, 0, 0, 2),
        s_type(0, 2, 1, 0),
        i_type(0, 1, 0, 3, 0x03),
        i_type(0, 1, 4, 4, 0x03),
        s_type(2, 2, 1, 1),
        i_type(2, 1, 1, 5, 0x03),
        i_type(2, 1, 5, 6, 0x03),
        i_type(1, 0, 0, 7),
        i_type(4, 7, 1, 8),
        i_type(2, 8, 5, 9),
        i_type(0x404, 2, 5, 10),
        i_type(-2, 2, 2, 11),
    ]
    model = RV32IModel(program)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await write_program(dut, program)
    dut.reset.value = 1
    await Timer(12, units="ns")
    dut.reset.value = 0

    for _ in range(len(program)):
        model.step()
        await RisingEdge(dut.clk)

    await Timer(1, units="ns")
    for register in range(1, 12):
        actual = int(dut.register_file.registers[register].value)
        assert actual == model.registers[register], f"x{register}: {actual:#x} != {model.registers[register]:#x}"
    for address in (0x200, 0x202, 0x203):
        assert int(dut.data_memory.memory[address].value) == model.memory[address]
