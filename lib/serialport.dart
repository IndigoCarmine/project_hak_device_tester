import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';
import 'package:cobs2/cobs2.dart';
import 'package:usb_serial/usb_serial.dart' as UsbSerial;
import 'package:serial_port_win32/serial_port_win32.dart' as SerialPortWin32;
import 'package:stream_isolate/stream_isolate.dart';

abstract class Device {
  bool isConnected();
  Future<bool> tryConnect();
  int? get vid;
  int? get pid;
  Stream<Uint8List>? get stream;
  Future write(Uint8List data);
}

class AndroidDevice extends Device {
  UsbSerial.UsbDevice device;
  AndroidDevice(this.device);
  @override
  Future<bool> tryConnect() async {
    try {
      await device.create();
    } catch (e) {
      return false;
    }
    if (device.port == null) return false;
    device.port!.setPortParameters(115200, UsbSerial.UsbPort.DATABITS_8,
        UsbSerial.UsbPort.STOPBITS_1, UsbSerial.UsbPort.PARITY_NONE);

    print("Connecting to ...");
    //open a port.
    if (device.port == null || !(await device.port!.open())) return false;

    return true;
  }

  @override
  bool isConnected() {
    return device.port != null;
  }

  @override
  Stream<Uint8List>? get stream {
    return device.port?.inputStream?.asBroadcastStream();
  }

  @override
  Future write(Uint8List data) {
    return device.port!.write(data);
  }

  @override
  int? get pid => device.pid;

  @override
  int? get vid => device.vid;
}

class WindowsDevice extends Device {
  SerialPortWin32.PortInfo device;
  SerialPortWin32.SerialPort? port;
  WindowsDevice(this.device);
  final ReceivePort _receivePort = ReceivePort();
  Isolate? _isolate;
  @override
  Future<bool> tryConnect() async {
    port = SerialPortWin32.SerialPort(device.portName, openNow: false);
    try {
      print("port opening");
      port!.open();
      port!.BaudRate = 115200; //baudrate 115200
      port!.ByteSize = 8; //8 bits
      port!.StopBits = 0; //stopbits 1
      port!.Parity = 0; //parity none
      _isolate = await Isolate.spawn((message) async {
        final SendPort sendPort = message.$1;
        final SerialPortWin32.SerialPort port =
            SerialPortWin32.SerialPort(message.$2, openNow: false);
        port.handler = message.$3;

        while (true) {
          final data = await port.readBytesUntil(Uint8List.fromList([0]));
          print("receive: $data");
          sendPort.send(data);
        }
      }, (_receivePort.sendPort, port!.portName, port!.handler));
      print("port opened");
    } catch (e) {
      print("port open error");
      print(e);

      return false;
    }

    return true;
  }

  @override
  bool isConnected() {
    return port != null && port!.isOpened;
  }

  @override
  Stream<Uint8List>? get stream {
    return _receivePort.map((event) => event as Uint8List).asBroadcastStream();
  }

  @override
  Future write(Uint8List data) async {
    print("send: $data");
    if (port!.writeBytesFromUint8List(data)) {
      print("send success");
    } else {
      print("send fail");
    }
    return;
  }

  bool isLoadPortInfo = false;

  void loadPortInfo() {
    if (isLoadPortInfo) return;
    isLoadPortInfo = true;

    if (!device.hardwareID.contains("USB\\")) return;
    print("USB device");
    print(device.hardwareID);
    print(device.portName);
    print(device.friendlyName);
    print(device.manufactureName);

    final info = device.hardwareID.split('\\')[1].split('&');
    _pid = int.parse(info[1].split('_')[1], radix: 16);
    _vid = int.parse(info[0].split('_')[1], radix: 16);
  }

  int? _pid;
  int? _vid;

  @override
  int? get pid {
    loadPortInfo();
    return _pid;
  }

  @override
  int? get vid {
    loadPortInfo();
    return _vid;
  }
}

class MultiPlatformSerialPort {
  static Future<List<Device>> listDevices() async {
    if (Platform.isAndroid) {
      return (await UsbSerial.UsbSerial.listDevices()).map((element) {
        return AndroidDevice(element);
      }).toList();
    } else if (Platform.isWindows) {
      return SerialPortWin32.SerialPort.getPortsWithFullMessages()
          .map((portinfo) {
        return WindowsDevice(portinfo);
      }).toList();
    } else {
      throw Exception("Unsupported platform");
    }
  }
}

// data structure
/*
uint8_t command <<4 | motor id
... : some data
*/
/*
command:
0x00: set angle
0x01: communication test
0x02: start or stop motor
*/
class Command {
  int toInt() {
    return 0;
  }
}

class Packet {
  int command;
  int lowerbyte;
  Uint8List data;

  Packet(this.command, this.data, {this.lowerbyte = 0});
  Uint8List toUint8List() {
    Uint8List result = Uint8List(data.length + 1);
    result[0] = (command << 4) + (0x0F & lowerbyte);
    result.setRange(1, data.length + 1, data);
    return result;
  }

  Packet.fromUint8List(Uint8List rawData)
      : data = Uint8List.sublistView(rawData, 1),
        command = rawData[0] << 4,
        lowerbyte = rawData[0] & 0x0F;
}

class HAKDevice<Command> {
  Device? device;
  bool connectionEstablished = false;
  Stream<Packet>? _stream;
  Stream<Packet> get stream {
    _stream ??= _usbStream().asBroadcastStream();
    return _stream!;
  }

  Future<bool> connectUSB() async {
    Device? newDevice;
    //Search a usbcan.
    List<Device> devices = await MultiPlatformSerialPort.listDevices();
    for (var element in devices) {
      if (Platform.isWindows) {
        print(
            "element: ${element.vid} ${element.pid} ,,, ${(element as WindowsDevice).port?.isOpened}");
      } else if (Platform.isAndroid) {
        print("element: ${element.vid} ${element.pid} ");
      }

      if (element.vid == 0x16C0 && element.pid == 0x27E1) {
        newDevice = element;
        break;
      }
    }
    if (newDevice == null) return false;
    if (await newDevice.tryConnect()) {
      device = newDevice;
      return true;
    } else {
      return false;
    }
  }

  Future<bool> sendPacket(Packet frame) async {
    print("send packet: ${frame.toUint8List()}");
    return await _sendUint8List(frame.toUint8List());
  }

  Future<bool> sendCommand(int command, Uint8List data) async {
    Uint8List sendData = Uint8List(data.length + 1);
    sendData[0] = command << 4;
    sendData.setRange(1, data.length + 1, data);
    return await _sendUint8List(sendData);
  }

  //for test
  Future<bool> sendString(String text) async {
    return await _sendUint8List(ascii.encode(text));
  }

  //Simply send Uin8list data.
  Future<bool> _sendUint8List(Uint8List rawData) async {
    if (device == null || !device!.isConnected()) return false;

    ByteData encoded = ByteData(64);
    EncodeResult encodeResult =
        encodeCOBS(encoded, ByteData.sublistView(rawData));
    if (encodeResult.status != EncodeStatus.OK) return false;
    Uint8List encodedList = Uint8List(encodeResult.outLen + 1);
    encodedList.setRange(0, encodeResult.outLen, encoded.buffer.asUint8List());
    encodedList.last = 0;
    device!.write(encodedList);
    return true;
  }

  Stream<Packet> _usbStream() async* {
    while (device == null || !device!.isConnected()) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    final reader = _usbRawStream();
    await for (Uint8List data in reader) {
      yield Packet.fromUint8List(data);
      if (data[0] << 4 == 0x01) {
        print("communication test");
        connectionEstablished = true;
      }
    }
  }

  //this is stream for receive data.
  //it do COBS.
  Stream<Uint8List> _usbRawStream() async* {
    List<int> buffer = List.generate(64, (index) => 0);
    int bufferIndex = 0;
    final stream = device!.stream!.handleError((error) {
      print(error);
    });
    await for (Uint8List data in stream) {
      for (int i = 0; i < data.length; i++) {
        if (data[i] == 0) {
          ByteData decoded = ByteData(64);
          DecodeResult decodeResult = decodeCOBS(
              decoded, ByteData.sublistView(Uint8List.fromList(buffer), 0, i));
          if (decodeResult.status != DecodeStatus.OK) {
            buffer = Uint8List(0);
            continue;
          }
          yield decoded.buffer.asUint8List();
          buffer.setAll(0, List.generate(64, (index) => 0));
          bufferIndex = 0;
        } else {
          buffer[bufferIndex] = data[i];
          bufferIndex++;
        }
      }
    }
  }
}
