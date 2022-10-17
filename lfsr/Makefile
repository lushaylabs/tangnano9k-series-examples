BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: lfsr.fs

# Synthesis
lfsr.json: top.v screen.v lfsr.v
	yosys -p "read_verilog screen.v lfsr.v top.v; synth_gowin -noalu -top top -json lfsr.json"

# Place and Route
lfsr_pnr.json: lfsr.json
	nextpnr-gowin --json lfsr.json --write lfsr_pnr.json --enable-auto-longwires --enable-globals --freq 27 --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
lfsr.fs: lfsr_pnr.json
	gowin_pack -d ${FAMILY} -o lfsr.fs lfsr_pnr.json

# Program Board
load: lfsr.fs
	openFPGALoader -b ${BOARD} lfsr.fs -f

# Generate Simulation
lfsr_test.o: lfsr.v lfsr_tb.v
	iverilog -o lfsr_test.o -s test lfsr.v lfsr_tb.v

# Run Simulation
test: lfsr_test.o
	vvp lfsr_test.o

# Cleanup build artifacts
clean:
	rm lfsr.fs lfsr_test.o

.PHONY: load clean test
.INTERMEDIATE: lfsr_pnr.json lfsr.json lfsr_test.o
