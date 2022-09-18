BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: flash.fs

# Synthesis
flash.json: top.v text.v screen.v flash.v
	yosys -p "read_verilog screen.v flash.v text.v top.v; synth_gowin -noalu -top top -json flash.json"

# Place and Route
flash_pnr.json: flash.json
	nextpnr-gowin --json flash.json --write flash_pnr.json --enable-auto-longwires --enable-globals --freq 27 --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
flash.fs: flash_pnr.json
	gowin_pack -d ${FAMILY} -o flash.fs flash_pnr.json

# Program Board
load: flash.fs
	openFPGALoader -b ${BOARD} flash.fs -f

# Generate Font
font: font.hex
font.hex:
	node ./scripts/generate_font.js

# Cleanup build artifacts
clean:
	rm flash.fs

.PHONY: load clean test
.INTERMEDIATE: flash_pnr.json flash.json
