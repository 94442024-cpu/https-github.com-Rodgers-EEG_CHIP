TOPLEVEL_LANG := verilog
SIM ?= icarus
TOPLEVEL := riscv_core
MODULE := test_riscv_core_cocotb

VERILOG_SOURCES := $(PWD)/../../rtl/core/alu.v \
                   $(PWD)/../../rtl/core/regfile.v \
                   $(PWD)/../../rtl/core/control.v \
                   $(PWD)/../../rtl/core/imm_gen.v \
                   $(PWD)/../../rtl/core/instr_mem.v \
                   $(PWD)/../../rtl/core/data_mem.v \
                   $(PWD)/../../rtl/core/riscv_core.v

COMPILE_ARGS += -g2012

include $(shell cocotb-config --makefiles)/Makefile.sim
