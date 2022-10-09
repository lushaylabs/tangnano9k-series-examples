BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: uart.fs

# Synthesis
uart.json: uart.v
	yosys -p "read_verilog uart.v; synth_gowin -top uart -json uart.json"

# Place and Route
uart_pnr.json: uart.json
	nextpnr-gowin --json uart.json --write uart_pnr.json --freq 27 --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
uart.fs: uart_pnr.json
	gowin_pack -d ${FAMILY} -o uart.fs uart_pnr.json

# Program Board
load: uart.fs
	openFPGALoader -b ${BOARD} uart.fs -f


# Generate Simulation
uart_test.o: uart.v uart_tb.v
	iverilog -o uart_test.o -s test uart.v uart_tb.v

# Run Simulation
test: uart_test.o
	vvp uart_test.o

# Cleanup build artifacts
clean:
	rm uart.vcd uart.fs uart_test.o

.PHONY: load clean test
.INTERMEDIATE: uart_pnr.json uart.json uart_test.o
