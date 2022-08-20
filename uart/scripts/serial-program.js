const {SerialPort} = require('serialport');

const tangnano = new SerialPort({
    path: '/dev/tty.usbserial-2101',
    baudRate: 115200,
});

let counter = 0;

tangnano.on('data', function (data) {
    console.log('Data In Text:', data.toString());
    console.log('Data In Hex:', data.toString('hex'));

    const binary = data.toString().split('').map((byte) => {
        return byte.charCodeAt(0).toString(2).padStart(8, '0');
    });
    console.log('Data In Binary: ', binary.join(' '));
    console.log("\n");
    counter += 1;
    tangnano.write(Buffer.from([counter]));
});
