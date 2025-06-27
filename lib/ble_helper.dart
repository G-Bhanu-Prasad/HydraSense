import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_2/distanceprovider.dart';
import 'package:flutter_application_2/home_screen.dart';

class BLEHelper {
  static Future<void> pairAndConnectDevice(
    BuildContext context,
    BluetoothDevice device,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                'Connecting...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await device.connect(timeout: const Duration(seconds: 10));

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastConnectedDeviceId', device.remoteId.str);

      final services = await device.discoverServices();

      final targetService = services.firstWhere(
        (s) =>
            s.serviceUuid.toString().toLowerCase() ==
            "19b10000-e8f2-537e-4f6c-d104768a1214",
        orElse: () => throw Exception("Target service not found"),
      );

      final targetCharacteristic = targetService.characteristics.firstWhere(
        (c) =>
            c.characteristicUuid.toString().toLowerCase() ==
            "19b10001-e8f2-537e-4f6c-d104768a1214",
        orElse: () => throw Exception("Target characteristic not found"),
      );

      final connectionProvider =
          Provider.of<ConnectionProvider>(context, listen: false);
      connectionProvider.setConnectionStatus(true);

      final distanceProvider =
          Provider.of<DistanceProvider>(context, listen: false);
      distanceProvider.startListening(targetCharacteristic);

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          connectionProvider.setConnectionStatus(false);
        } else if (state == BluetoothConnectionState.connected) {
          connectionProvider.setConnectionStatus(true);
        }
      });

      Navigator.pop(context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileDisplayScreen(),
        ),
      );
    } catch (e) {
      Navigator.pop(context);

      final connectionProvider =
          Provider.of<ConnectionProvider>(context, listen: false);
      connectionProvider.setConnectionStatus(false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> autoReconnectToLastDevice(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastId = prefs.getString('lastConnectedDeviceId');

    if (lastId != null) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (result.device.remoteId.str == lastId) {
            FlutterBluePlus.stopScan();
            pairAndConnectDevice(context, result.device);
            break;
          }
        }
      });
    }
  }
}
