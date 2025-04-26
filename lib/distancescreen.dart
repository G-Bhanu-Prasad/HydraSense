import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DistanceScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  const DistanceScreen({
    super.key,
    required this.device,
    required this.characteristic,
  });

  @override
  State<DistanceScreen> createState() => _DistanceScreenState();
}

class _DistanceScreenState extends State<DistanceScreen> {
  int? distance;

  @override
  void initState() {
    super.initState();

    widget.characteristic.setNotifyValue(true);
    widget.characteristic.onValueReceived.listen((value) {
      final byteData = Uint8List.fromList(value).buffer.asByteData();
      final newDistance = byteData.getInt32(0, Endian.little);
      setState(() {
        distance = newDistance;
      });
    });
  }

  @override
  void dispose() {
    widget.characteristic.setNotifyValue(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Live Distance"),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: Center(
        child: distance == null
            ? const CircularProgressIndicator()
            : Text(
                "$distance ml",
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
      ),
    );
  }
}
