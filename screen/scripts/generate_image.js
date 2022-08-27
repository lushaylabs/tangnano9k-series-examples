const fs = require("fs");
const PNG = require("pngjs").PNG;

fs.createReadStream("image.png")
  .pipe(new PNG())
  .on("parsed", function () {
    const bytes = [];

    for (var y = 0; y < this.height; y+=8) {
      for (var x = 0; x < this.width; x+=1) {
        let byte = 0;

        for (var j = 7; j >= 0; j -= 1) {
            let idx = (this.width * (y+j) + x) * 4;
            if (this.data[idx+3] > 128) {
                byte = (byte << 1) + 1;
            } else {
                byte = (byte << 1) + 0;
            }
        }

        bytes.push(byte);
      }
    }
    const hexData = bytes.map((b) => b.toString('16').padStart(2, '0'));
    fs.writeFileSync('image.hex', hexData.join(' '));
});
