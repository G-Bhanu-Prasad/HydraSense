import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:math' as math;
import 'navbar.dart';
import 'home_screen.dart';

class BottlePage extends StatefulWidget {
  const BottlePage({super.key});

  @override
  BottlePageState createState() => BottlePageState();
}

class BottlePageState extends State<BottlePage> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  bool isBluetoothOn = false;

  @override
  void initState() {
    super.initState();
    _startScanning();
    _checkBluetoothStatus();
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        if (mounted) {
          _showBluetoothNotSupportedDialog();
        }
        return;
      }

      // Listen to Bluetooth state changes
      FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
        setState(() {
          isBluetoothOn = state == BluetoothAdapterState.on;
        });

        if (state == BluetoothAdapterState.on) {
          _startScanning();
        }
      });

      // Check initial Bluetooth state
      final currentState = await FlutterBluePlus.adapterState.first;
      if (currentState != BluetoothAdapterState.on) {
        if (mounted) {
          _showEnableBluetoothDialog();
        }
      } else {
        setState(() {
          isBluetoothOn = true;
        });
        _startScanning();
      }
    } catch (e) {
      print('Error checking Bluetooth status: $e');
    }
  }

  void _showBluetoothNotSupportedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey.shade200,
        title: Text(
          'Bluetooth Not Supported',
          style: TextStyle(
            color: Color.fromARGB(255, 9, 47, 103),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This device does not support Bluetooth functionality.',
          style: TextStyle(
            color: Colors.blueGrey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: Color.fromARGB(255, 9, 47, 103),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEnableBluetoothDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey.shade200,
        title: Text(
          'Enable Bluetooth',
          style: TextStyle(
            color: Color.fromARGB(255, 9, 47, 103),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Bluetooth is required to connect to your smart bottle. Would you like to enable it?',
          style: TextStyle(
            color: Colors.blueGrey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FlutterBluePlus.turnOn();
              } catch (e) {
                print('Error turning on Bluetooth: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Failed to enable Bluetooth. Please enable it manually.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Enable',
              style: TextStyle(
                color: Color.fromARGB(255, 9, 47, 103),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Color.fromARGB(255, 9, 47, 103),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startScanning() async {
    setState(() {
      isScanning = true;
      scanResults.clear();
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          scanResults = results;
        });
      });

      await Future.delayed(const Duration(seconds: 4));
      setState(() {
        isScanning = false;
      });
    } catch (e) {
      print('Error scanning: $e');
      setState(() {
        isScanning = false;
      });
    }
  }

  Widget _buildDeviceIndicator(double angle, ScanResult result) {
    final double radius = 140; // Radius for device indicators
    final double x = radius * math.cos(angle);
    final double y = radius * math.sin(angle);

    String deviceName = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : 'Unknown Device';
    // Truncate name if too long
    if (deviceName.length > 12) {
      deviceName = '${deviceName.substring(0, 10)}...';
    }

    return Transform.translate(
      offset: Offset(x, y),
      child: GestureDetector(
        onTap: () => _showDeviceInfo(result),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.water_drop,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                deviceName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeviceInfo(ScanResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey.shade200,
        title: Text(
          result.device.platformName.isNotEmpty
              ? result.device.platformName
              : 'Unknown Device',
          style: TextStyle(
            color: Color.fromARGB(255, 9, 47, 103),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signal Strength: ${result.rssi} dBm',
              style: TextStyle(
                color: Colors.blueGrey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'ID: ${result.device.remoteId}',
              style: TextStyle(
                color: Colors.blueGrey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pairAndConnectDevice(result.device);
            },
            child: Text(
              'Connect',
              style: TextStyle(
                color: Color.fromARGB(255, 9, 47, 103),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Color.fromARGB(255, 9, 47, 103),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pairAndConnectDevice(BluetoothDevice device) async {
    try {
      await device.createBond();
      await device.connect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.platformName}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: const Color(0xFF0A0E21),
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfileDisplayScreen()),
            );
          },
        ),
        title: Text(
          '',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!isBluetoothOn)
            IconButton(
              icon: Icon(Icons.bluetooth_disabled, color: Colors.white),
              onPressed: _showEnableBluetoothDialog,
            ),
        ],
      ),
      body: Column(
        //mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //const SizedBox(height: 50),
          Text(
            'Add your bottle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isScanning
                ? 'Scanning for nearby bottles...'
                : scanResults.isEmpty
                    ? 'No bottles found nearby'
                    : '1 bottles found',
            //: '${scanResults.length} bottles found',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 400,
            height: 400,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer circles
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                ),
                // Center Bluetooth icon with pulsing effect
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isScanning
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.cyan.shade800,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bluetooth,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                // Device indicators with names
                if (scanResults.isNotEmpty)
                  ...List.generate(
                    math.min(scanResults.length, 1), // Limit to 8 devices
                    (index) {
                      final angle = (2 * math.pi * index) /
                          math.min(scanResults.length, 8);
                      return _buildDeviceIndicator(angle, scanResults[index]);
                    },
                  ),
                if (isScanning)
                  SizedBox(
                    width: 320,
                    height: 320,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!isScanning)
            ElevatedButton.icon(
              onPressed: _startScanning,
              icon: Icon(Icons.refresh),
              label: Text('Scan Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        //dailyIntakes: dailyIntakes,
      ),
    );
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}
