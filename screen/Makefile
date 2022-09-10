BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: screen.fs

# Synthesis
screen.json: screen.v
	yosys -p "read_verilog screen.v; synth_gowin -top screen -json screen.json"

# Place and Route
screen_pnr.json: screen.json
	nextpnr-gowin --json screen.json --write screen_pnr.json --freq 27 --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
screen.fs: screen_pnr.json
	gowin_pack -d ${FAMILY} -o screen.fs screen_pnr.json

# Program Board
load: screen.fs
	openFPGALoader -b ${BOARD} screen.fs -f


# Generate Simulation
screen_test.o: screen.v screen_tb.v
	iverilog -o screen_test.o -s test screen.v screen_tb.v

# Run Simulation
test: screen_test.o
	./screen_test.o

# Cleanup build artifacts
clean:
	rm screen.vcd screen.fs screen_test.o

.PHONY: load clean test
.INTERMEDIATE: screen_pnr.json screen.json screen_test.o
