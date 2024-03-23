const sharp = require('sharp');
const fs = require('fs');

// usage: node convert.js <image_path>

const imagePath = process.argv[2];
const imageWidth = 64;
const imageHeight = 32;

function quantizeColor(colorVal) {
  const quantizationLevels = 4;
  const stepSize = 256 / quantizationLevels;

  return Math.floor(colorVal / stepSize);
}

function convertTo6Bit(r, g, b) {
  return (quantizeColor(b) << 4) | (quantizeColor(g) << 2) | quantizeColor(r);
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
        const value = convertTo6Bit(r, g, b);

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
    let verilogCode = `module ${moduleName}(input clk, input [9:0] addr, output reg [5:0] data = 0);\n\n`;
    verilogCode += `    always @(*) begin\n`;
    verilogCode += `        case (addr)\n`;

    array.forEach((value, index) => {
        let binaryAddress = index.toString(2).padStart(10, '0'); // 10-bit binary address
        let binaryValue = value.toString(2).padStart(6, '0'); // 6-bit binary value
        verilogCode += `            10'b${binaryAddress}: data <= 6'b${binaryValue};\n`;
    });
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
