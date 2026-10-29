import 'dart:async';
import 'dart:typed_data';
import 'serial_port_adapter_base.dart';

class _StubSerialPortAdapter implements SerialPortAdapter {
  @override
  bool get isSupported => false;

  @override
  bool get isOpen => false;

  @override
  List<String> getAvailablePorts() => const [];

  @override
  bool openPort(String portName, int baudRate) => false;

  @override
  Stream<Uint8List>? get inputStream => null;

  @override
  void writeBytes(Uint8List bytes) {}

  @override
  void closePort() {}
}

SerialPortAdapter createSerialPortAdapter() => _StubSerialPortAdapter();
