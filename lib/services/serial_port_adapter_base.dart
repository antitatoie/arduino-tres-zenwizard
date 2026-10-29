import 'dart:async';
import 'dart:typed_data';

abstract class SerialPortAdapter {
  bool get isSupported;
  bool get isOpen;
  List<String> getAvailablePorts();
  bool openPort(String portName, int baudRate);
  Stream<Uint8List>? get inputStream;
  void writeBytes(Uint8List bytes);
  void closePort();
}
