const fs = require('fs');

const bitmaps = fs.readFileSync('./fonts/monogram.json');
const json = JSON.parse(bitmaps.toString());

const memory = [];
for (var i = 32; i <= 126; i += 1) {
  const key = i.toString()
  const horizontalBytes = json[key];
  const verticalBytes = [];

  for (let x = 0; x < 8; x += 1) {
    let b1 = 0;
    let b2 = 0;
    for (let y = 0; y < 8; y += 1) {
      if (!horizontalBytes) { continue; }
      const num1 = horizontalBytes[y];
      const num2 = horizontalBytes[y+8] || 0;
      const bit = (1 << x);
      if ((num1 & bit) !== 0) {
        b1 = b1 | (1 << y);
      }
      if ((num2 & bit) !== 0) {
        b2 = b2 | (1 << y);
      }
    }
    memory.push(b1.toString(16).padStart(2, '0'));
    memory.push(b2.toString(16).padStart(2, '0'));
  }
}
fs.writeFileSync('font.hex', memory.join(' '));