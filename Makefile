MODELSIM_DIR = /d/intelFPGA_lite/20.1/modelsim_ase/win32aloem
export PATH := $(MODELSIM_DIR):$(PATH)
VLOG = $(MODELSIM_DIR)/vlog -sv
VSIM = $(MODELSIM_DIR)/vsim
SRC_RTL = mac_16bit.sv
SRC_TB = tb_mac_16bit.sv
TOP_TB = tb_mac_16bit

.PHONY: all compile sim gui clean
all: sim
compile:
	@if [ ! -d "work" ]; then $(MODELSIM_DIR)/vlib work; fi
	$(VLOG) $(SRC_RTL) $(SRC_TB)
sim: compile
	$(VSIM) -c -do "run -all; quit" $(TOP_TB)
gui: compile
	$(VSIM) -do "add wave -r /*; run -all" $(TOP_TB)
clean:
	rm -rf work transcript *.wlf

