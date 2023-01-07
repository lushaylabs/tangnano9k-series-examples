const fs = require('fs');
const path = require('path');

const file = process.argv[2];
if (!file) {
    console.error('No file supplied, usage `node scripts/assembler.js <filename>`');
    process.exit(1);
}
try {
    const fileStat = fs.statSync(file);
    if (fileStat.isDirectory()) {
        console.error(`Supplied file (${file}) is a directory`);
        process.exit(1);
    }
} catch(e) {
    if (e.code === 'ENOENT') {
        console.error(`Could not find file ${file}`);
        process.exit(1);
    }
}

const fileContents = fs.readFileSync(file).toString();
const lines = fileContents.split('\n').map((line) => line.split(';').shift().trim()).filter((line) => !!line);
let pc = 0;
const memoryMap = {}
const commands = [
    { regex: /^CLR A$/i,  byte: 0b00001000 },
    { regex: /^CLR B$/i,  byte: 0b00000100 },
    { regex: /^CLR BTN$/i,  byte: 0b00000010 },
    { regex: /^CLR AC$/i, byte: 0b00000001 },
    { regex: /^ADD A$/i,  byte: 0b00011000 },
    { regex: /^ADD B$/i,  byte: 0b00010100 },
    { regex: /^ADD C$/i,  byte: 0b00010010 },
    { regex: /^ADD ([0-9A-F]+?)([HBD]?)$/i,  byte: 0b10010001, hasConstant: true },
    { regex: /^STA A$/i,   byte: 0b00101000 },
    { regex: /^STA B$/i,   byte: 0b00100100 },
    { regex: /^STA C$/i,   byte: 0b00100010 },
    { regex: /^STA LED$/i, byte: 0b00100001 },
    { regex: /^INV A$/i,  byte: 0b00111000 },
    { regex: /^INV B$/i,  byte: 0b00110100 },
    { regex: /^INV C$/i,  byte: 0b00110010 },
    { regex: /^INV AC$/i, byte: 0b00110001 },
    { regex: /^PRNT A$/i,  byte: 0b01001000 },
    { regex: /^PRNT B$/i,  byte: 0b01000100 },
    { regex: /^PRNT C$/i,  byte: 0b01000010 },
    { regex: /^PRNT ([0-9A-F]+?)([HBD]?)$/i,  byte: 0b11000001, hasConstant: true },
    { regex: /^JMPZ A$/i,  byte: 0b01011000 },
    { regex: /^JMPZ B$/i,  byte: 0b01010100 },
    { regex: /^JMPZ C$/i,  byte: 0b01010010 },
    { regex: /^JMPZ ([0-9A-F]+?)([HBD]?)$/i,  byte: 0b11010001, hasConstant: true },
    { regex: /^WAIT A$/i,  byte: 0b01101000 },
    { regex: /^WAIT B$/i,  byte: 0b01100100 },
    { regex: /^WAIT C$/i,  byte: 0b01100010 },
    { regex: /^WAIT ([0-9A-F]+?)([HBD]?)$/i,  byte: 0b11100001, hasConstant: true },
    { regex: /^HLT$/i,  byte: 0b01110000 },
];

for (const line of lines) {
    const orgMatch = line.match(/\.org ([0-9A-F]+)([HBD])?/i);
    if (orgMatch) {
        const memoryAddressStr = orgMatch[1];
        const type = (orgMatch[2] || 'd').toLowerCase();
        const memoryAddress = parseInt(memoryAddressStr, type == 'd' ? 10 : type == 'h' ? 16 : 2);
        pc = memoryAddress;
        continue;
    }
    for (const command of commands) {
        const commandMatch = line.match(command.regex);
        if (commandMatch) {
            memoryMap[pc] = command.byte;
            pc += 1;
            if (command.hasConstant) {
                const constantStr = commandMatch[1];
                const constantType = (commandMatch[2] || 'd').toLowerCase();
                const constant = parseInt(constantStr, constantType == 'd' ? 10 : constantType == 'h' ? 16 : 2);
                const constantSized = constant % 256;
                if (constant !== constantSized) {
                    console.warn(`Line ${line} has an invalid constant`);
                }
                memoryMap[pc] = constantSized;
                pc += 1;
            }
            break;
        }
    }
}

const largestAddress = Object.keys(memoryMap).map((key) => +key).sort((a, b) => a > b ? -1 : a < b ? 1 : 0).shift();
if (typeof largestAddress === 'undefined') {
    console.error('No code to assemble');
    process.exit(1);
}

const byteArray = new Array(largestAddress + 1);
for (let i = 0; i <= largestAddress; i += 1) {
    byteArray[i] = (i in memoryMap) ? memoryMap[i] : 0;
}
const filename = file.replace('.prog', '.bin');
fs.writeFileSync(filename, Buffer.from(byteArray));
console.log("Assembled Program");