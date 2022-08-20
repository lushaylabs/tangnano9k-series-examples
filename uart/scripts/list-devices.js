const {SerialPort} = require('serialport');

SerialPort.list().then(console.log);