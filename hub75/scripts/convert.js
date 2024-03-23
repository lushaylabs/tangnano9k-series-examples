const sharp = require('sharp');
const fs = require('fs');

// usage: node convert.js <image_path>

const imagePath = process.argv[2];
const imageWidth = 64;
const imageHeight = 32;

function quantizeColor(value) {
  return value >= 128 ? 1 : 0;
}

function convertTo3Bit(r, g, b) {
  return (quantizeColor(b) << 2) | (quantizeColor(g) << 1) | quantizeColor(r);
}

async function processImage() {
  try {
    const image = sharp(imagePath);
    const { data, info } = await image
      .resize(imageWidth, imageHeight)
      .raw()
      .toBuffer({ resolveWithObject: true });

    let topHalf = [];
    let bottomHalf = [];

    for (let y = 0; y < imageHeight; y++) {
      for (let x = 0; x < imageWidth; x++) {
        const idx = (imageWidth * y + x) * info.channels;
        const r = data[idx];
        const g = data[idx + 1];
        const b = data[idx + 2];
        const value = convertTo3Bit(r, g, b);

        if (y < imageHeight / 2) {
          topHalf.push(value);
        } else {
          bottomHalf.push(value);
        }
      }
    }

    return { topHalf, bottomHalf };
  } catch (error) {
    console.error('Error processing image:', error);
  }
}


function generateVerilogROM(array, moduleName) {
    let verilogCode = `module ${moduleName}(input clk, input [9:0] addr, output reg [2:0] data = 0);\n\n`;
    verilogCode += `    always @(*) begin\n`;
    verilogCode += `        case (addr)\n`;

    array.forEach((value, index) => {
        let binaryAddress = index.toString(2).padStart(10, '0'); // 10-bit binary address
        let binaryValue = value.toString(2).padStart(3, '0'); // 3-bit binary value
        verilogCode += `            10'b${binaryAddress}: data <= 3'b${binaryValue};\n`;
    });

    verilogCode += `            default: data <= 3'b000;\n`;
    verilogCode += `        endcase\n`;
    verilogCode += `    end\n`;
    verilogCode += `endmodule\n`;

    return verilogCode;
}

async function main() {
    const { topHalf, bottomHalf } = await processImage();

    const topHalfVerilog = generateVerilogROM(topHalf, 'ROMTop');
    const bottomHalfVerilog = generateVerilogROM(bottomHalf, 'ROMBottom');

    fs.writeFileSync('top_half_rom.v', topHalfVerilog);
    fs.writeFileSync('bottom_half_rom.v', bottomHalfVerilog);
    console.log('Generated 2 Verilog ROM files');
}
main();
