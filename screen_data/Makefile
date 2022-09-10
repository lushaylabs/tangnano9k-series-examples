BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: data.fs

# Synthesis
data.json: top.v text.v screen.v uart.v rows.v
	yosys -p "read_verilog screen.v uart.v rows.v text.v top.v; synth_gowin -noalu -top top -json data.json"

# Place and Route
data_pnr.json: data.json
	nextpnr-gowin --json data.json --write data_pnr.json --enable-globals --freq 27 --enable-auto-longwires --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
data.fs: data_pnr.json
	gowin_pack -d ${FAMILY} -o data.fs data_pnr.json

# Program Board
load: data.fs
	openFPGALoader -b ${BOARD} data.fs -f

# Generate Simulation
data_test.o: text.v data_tb.v top.v uart.v rows.v screen.v
	iverilog -o data_test.o -s test text.v uart.v rows.v data_tb.v top.v screen.v

# Run Simulation
test: data_test.o
	./data_test.o

# Generate Font
font: font.hex
font.hex:
	node ./scripts/generate_font.js

# Cleanup build artifacts
clean:
	rm data.vcd data.fs data_test.o

.PHONY: load clean test
.INTERMEDIATE: data_pnr.json data.json data_test.o
