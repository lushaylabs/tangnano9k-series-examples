BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: cpu.fs

# Synthesis
cpu.json: top.v text.v screen.v flash.v cpu.v
	yosys -p "read_verilog screen.v flash.v text.v cpu.v top.v; synth_gowin -noalu -nowidelut -nolutram -nodffe -top top -json cpu.json"

# Place and Route
cpu_pnr.json: cpu.json
	nextpnr-gowin --json cpu.json --write cpu_pnr.json --enable-auto-longwires --enable-globals --freq 27 --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
cpu.fs: cpu_pnr.json
	gowin_pack -d ${FAMILY} -o cpu.fs cpu_pnr.json

# Program Board
load: cpu.fs
	openFPGALoader -b ${BOARD} cpu.fs -f

# Generate Font
font: font.hex
font.hex:
	node ./scripts/generate_font.js

# Cleanup build artifacts
clean:
	rm cpu.fs

.PHONY: load clean test
.INTERMEDIATE: cpu_pnr.json cpu.json
