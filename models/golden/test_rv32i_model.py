import unittest

from rv32i_model import RV32IModel


def r_type(funct7, rs2, rs1, funct3, rd):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x33


def i_type(imm, rs1, funct3, rd, opcode=0x13):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def s_type(imm, rs2, rs1, funct3):
    return (
        (((imm >> 5) & 0x7F) << 25)
        | (rs2 << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | ((imm & 0x1F) << 7)
        | 0x23
    )


def b_type(offset, rs2, rs1, funct3):
    return (
        (((offset >> 12) & 1) << 31)
        | (((offset >> 5) & 0x3F) << 25)
        | (rs2 << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | (((offset >> 1) & 0xF) << 8)
        | (((offset >> 11) & 1) << 7)
        | 0x63
    )


class RV32IModelTests(unittest.TestCase):
    def test_arithmetic_and_x0(self):
        program = [
            i_type(7, 0, 0, 1),
            i_type(3, 0, 0, 2),
            r_type(0, 2, 1, 0, 3),
            i_type(99, 0, 0, 0),
        ]
        model = RV32IModel(program)
        model.run(len(program))
        self.assertEqual(model.registers[3], 10)
        self.assertEqual(model.registers[0], 0)

    def test_little_endian_store_and_signed_loads(self):
        program = [
            i_type(-2, 0, 0, 1),
            s_type(0x100, 1, 0, 2),
            i_type(0x100, 0, 2, 2, 0x03),
            i_type(0x100, 0, 0, 3, 0x03),
            i_type(0x101, 0, 0, 4, 0x03),
            i_type(0x100, 0, 4, 5, 0x03),
        ]
        model = RV32IModel(program)
        model.run(len(program))
        self.assertEqual(model.registers[2], 0xFFFFFFFE)
        self.assertEqual(model.registers[3], 0xFFFFFFFE)
        self.assertEqual(model.registers[4], 0xFFFFFFFF)
        self.assertEqual(model.registers[5], 0xFE)

    def test_taken_branch_skips_instruction(self):
        program = [
            i_type(5, 0, 0, 1),
            i_type(5, 0, 0, 2),
            b_type(8, 2, 1, 0),
            i_type(1, 0, 0, 3),
            i_type(2, 0, 0, 3),
        ]
        model = RV32IModel(program)
        model.run(4)
        self.assertEqual(model.registers[3], 2)


if __name__ == "__main__":
    unittest.main()
