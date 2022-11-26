BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: adc.fs

# Synthesis
adc.json: top.v i2c.v adc.v screen.v text.v
	yosys -p "read_verilog screen.v i2c.v adc.v text.v top.v; synth_gowin -noalu -nowidelut -top top -json adc.json"

# Place and Route
adc_pnr.json: adc.json
	nextpnr-gowin --json adc.json --write adc_pnr.json --freq 27 --enable-globals --enable-auto-longwires --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
adc.fs: adc_pnr.json
	gowin_pack -d ${FAMILY} -o adc.fs adc_pnr.json

# Program Board
load: adc.fs
	openFPGALoader -b ${BOARD} adc.fs -f

# Generate Simulation
adc_test.o: i2c.v adc.v adc_tb.v
	iverilog -o adc_test.o -s test i2c.v adc.v adc_tb.v

# Run Simulation
test: adc_test.o
	vvp adc_test.o

# Generate Font
font: font.hex
font.hex:
	node ./scripts/generate_font.js

# Cleanup build artifacts
clean:
	rm adc.vcd adc.fs adc_test.o

.PHONY: load clean test
.INTERMEDIATE: adc_pnr.json adc.json adc_test.o
