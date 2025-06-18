// distance_provider.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DistanceProvider with ChangeNotifier {
  int? _distance;
  BluetoothCharacteristic? _characteristic;

  int? get distance => _distance;

  void startListening(BluetoothCharacteristic characteristic) {
    _characteristic = characteristic;
    characteristic.setNotifyValue(true);
    characteristic.onValueReceived.listen((value) {
      final byteData = Uint8List.fromList(value).buffer.asByteData();
      final newDistance = byteData.getInt32(0, Endian.little);
      _distance = newDistance;
      notifyListeners();
    });
  }

  void stopListening() {
    _characteristic?.setNotifyValue(false);
  }
}

class ConnectionProvider with ChangeNotifier {
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void setConnectionStatus(bool status) {
    _isConnected = status;
    notifyListeners();
  }
}
