BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: arbiter.fs

# Synthesis
arbiter.json: top.v shared_memory.v controller.v memory_inc.v screen.v text.v
	yosys -p "read_verilog top.v shared_memory.v controller.v memory_inc.v screen.v text.v; synth_gowin -noalu -nolutram -top top -json arbiter.json"

# Place and Route
arbiter_pnr.json: arbiter.json
	nextpnr-gowin --json arbiter.json --write arbiter_pnr.json --enable-auto-longwires --enable-globals --freq 27 --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
arbiter.fs: arbiter_pnr.json
	gowin_pack -d ${FAMILY} -o arbiter.fs arbiter_pnr.json

# Program Board
load: arbiter.fs
	openFPGALoader -b ${BOARD} arbiter.fs -f

# Generate Font
font: font.hex
font.hex:
	node ./scripts/generate_font.js

# Generate Simulation
controller_test.o: controller.v controller_tb.v
	iverilog -o controller_test.o -s test controller.v controller_tb.v

# Run Simulation
test: controller_test.o
	vvp controller_test.o

# Cleanup build artifacts
clean:
	rm arbiter.fs font.hex controller.vcd

.PHONY: load clean test font
.INTERMEDIATE: arbiter_pnr.json arbiter.json controller_test.o
