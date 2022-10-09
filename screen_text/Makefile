BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: text.fs

# Synthesis
text.json: top.v text.v screen.v
	yosys -p "read_verilog screen.v text.v top.v; synth_gowin -top top -json text.json"

# Place and Route
text_pnr.json: text.json
	nextpnr-gowin --json text.json --write text_pnr.json --freq 27 --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
text.fs: text_pnr.json
	gowin_pack -d ${FAMILY} -o text.fs text_pnr.json

# Program Board
load: text.fs
	openFPGALoader -b ${BOARD} text.fs -f

# Generate Simulation
text_test.o: text.v text_tb.v top.v screen.v
	iverilog -o text_test.o -s test text.v text_tb.v top.v screen.v

# Run Simulation
test: text_test.o
	vvp text_test.o

# Generate Font
font: font.hex
font.hex:
	node ./scripts/generate_font.js

# Cleanup build artifacts
clean:
	rm text.vcd text.fs text_test.o

.PHONY: load clean test
.INTERMEDIATE: text_pnr.json text.json text_test.o
