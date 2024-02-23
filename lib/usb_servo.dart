import 'dart:typed_data';

import 'serialport.dart';

Packet activateAllServoPacket =
    Packet(ServoCommand.startOrStopMotor.toInt(), Uint8List.fromList([0xFF]));

class ServoAnglePacket extends Packet {
  ServoAnglePacket(int servoId, int angle)
      : super(ServoCommand.setAngle.toInt(),
            Uint8List.fromList([servoId, angle]));

  int get servoId => data[0];
  int get angle => data[1];
}

enum ServoCommand implements Command {
  setAngle,
  communicationTest,
  startOrStopMotor;

  @override
  int toInt() {
    return index;
  }
}
