// Desktop USB serial (flutter_libserialport) is disabled for Android builds.
// Falls back to the stub implementation so all serial services use BLE / Mock mode cleanly.
export 'serial_port_adapter_stub.dart';
