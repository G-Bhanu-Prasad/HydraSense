import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'navbar.dart';
import 'home_screen.dart';
import 'dart:convert';
// import 'dart:typed_data';
// import 'distancescreen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_2/distanceprovider.dart';
// import 'package:flutter_application_2/home_screen.dart';
//import 'package:flutter_application_2/ble_helper.dart';

class BottlePage extends StatefulWidget {
  const BottlePage({super.key});

  @override
  BottlePageState createState() => BottlePageState();
}

class BottlePageState extends State<BottlePage>
    with SingleTickerProviderStateMixin {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  bool isBluetoothOn = false;
  Map<String, int> dailyIntakes = {};
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  int? connectedDistance;

  @override
  void initState() {
    super.initState();
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
          parent: _pulseAnimationController, curve: Curves.easeInOut),
    );

    _startScanning();
    _checkBluetoothStatus();
    _loadDailyIntakes();
    _autoReconnectToLastDevice();
  }

  Future<void> _autoReconnectToLastDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastId = prefs.getString('lastConnectedDeviceId');

    if (lastId != null) {
      // Start scanning to find the previously connected device
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (result.device.remoteId.str == lastId) {
            FlutterBluePlus.stopScan();
            _pairAndConnectDevice(result.device); // ✅ your existing method
            break;
          }
        }
      });
    }
  }

  Future<void> _loadDailyIntakes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? dailyIntakesJson = prefs.getString('dailyIntakes');

    if (dailyIntakesJson != null) {
      setState(() {
        dailyIntakes = Map<String, int>.from(jsonDecode(dailyIntakesJson));
      });
    }
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
      builder: (context) => _buildCustomDialog(
        title: 'Bluetooth Not Supported',
        content: 'This device does not support Bluetooth functionality.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF1A73E8),
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
      builder: (context) => _buildCustomDialog(
        title: 'Enable Bluetooth',
        content:
            'Bluetooth is required to connect to your smart bottle. Would you like to enable it?',
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FlutterBluePlus.turnOn();
              } catch (e) {
                print('Error turning on Bluetooth: $e');
                _showSnackBar(
                    'Failed to enable Bluetooth. Please enable it manually.',
                    isError: true);
              }
            },
            child: const Text(
              'Enable',
              style: TextStyle(
                color: Color(0xFF1A73E8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2746),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bluetooth,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _startScanning() async {
    setState(() {
      isScanning = true;
      scanResults.clear();
    });

    const targetDeviceId = '64:E833:85:7E:1E';

    try {
      FlutterBluePlus.scanResults.listen((results) async {
        for (var result in results) {
          final scannedId = result.device.remoteId.toString().toUpperCase();
          if (scannedId == targetDeviceId) {
            FlutterBluePlus.stopScan();
            await _pairAndConnectDevice(result.device);
            return;
          }
        }

        setState(() {
          scanResults = results;
        });
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));

      await Future.delayed(const Duration(seconds: 6));
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

  Future<void> saveDeviceId(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastConnectedDeviceId', id);
  }

  Widget _buildDeviceIndicator(double angle, ScanResult result) {
    final double radius = 140;
    final double x = radius * math.cos(angle);
    final double y = radius * math.sin(angle);

    String deviceName = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : 'Unknown';

    if (deviceName.length > 12) {
      deviceName = '${deviceName.substring(0, 10)}...';
    }

    final signalStrength = ((result.rssi + 100) / 50).clamp(0.0, 1.0);
    final Color indicatorColor = ColorTween(
      begin: Colors.red.shade700,
      end: Colors.green,
    ).lerp(signalStrength)!;

    return Transform.translate(
      offset: Offset(x, y),
      child: GestureDetector(
        onTap: () => _showDeviceInfo(result),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale:
                      result == scanResults.first ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          indicatorColor.withOpacity(0.8),
                          indicatorColor.withOpacity(0.4),
                        ],
                      ),
                      shape: BoxShape.circle,
                      // boxShadow: [
                      //   BoxShadow(
                      //     color: indicatorColor.withOpacity(0.5),
                      //     spreadRadius: 2,
                      //     blurRadius: 6,
                      //   ),
                      // ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.water_drop,
                              color: Colors.white.withOpacity(0.9),
                              size: 26,
                            ),
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                deviceName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
    String deviceName = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : 'Unknown';

    // Signal strength in percentage
    final signalPercentage = ((result.rssi + 100) / 50).clamp(0.0, 1.0) * 100;
    final Color signalColor = signalPercentage > 50
        ? Colors.greenAccent
        : (signalPercentage > 25 ? Colors.orangeAccent : Colors.redAccent);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2746),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withOpacity(0.8),
                      Colors.blue.withOpacity(0.4),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                deviceName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              _buildDeviceInfoRow(
                icon: Icons.signal_cellular_alt,
                title: 'Signal Strength',
                value: '${signalPercentage.toInt()}%',
                valueColor: signalColor,
              ),
              const Divider(height: 24, color: Colors.white10),
              _buildDeviceInfoRow(
                icon: Icons.fingerprint,
                title: 'Device ID',
                value: result.device.remoteId.toString(),
                valueColor: Colors.white70,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _pairAndConnectDevice(result.device);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white70,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pairAndConnectDevice(BluetoothDevice device) async {
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
      // Attempt to connect with timeout
      await device.connect(timeout: const Duration(seconds: 10));

      // Save device ID for auto-reconnect
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastConnectedDeviceId', device.remoteId.str);

      // Discover services
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

      // ✅ Notify connection successful
      final connectionProvider =
          Provider.of<ConnectionProvider>(context, listen: false);
      connectionProvider.setConnectionStatus(true);

      // ✅ Start listening to distance characteristic
      final distanceProvider =
          Provider.of<DistanceProvider>(context, listen: false);
      distanceProvider.startListening(targetCharacteristic);

      // ✅ Monitor disconnection
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          connectionProvider.setConnectionStatus(false);
        } else if (state == BluetoothConnectionState.connected) {
          connectionProvider.setConnectionStatus(true);
        }
      });

      Navigator.pop(context); // dismiss dialog

      // ✅ Go to display screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileDisplayScreen(),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // close dialog on error

      final connectionProvider =
          Provider.of<ConnectionProvider>(context, listen: false);
      connectionProvider.setConnectionStatus(false);

      _showSnackBar('Failed to connect: $e', isError: true);
    }
  }

  Future<String?> getSavedDeviceId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastConnectedDeviceId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
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
        actions: [
          if (!isBluetoothOn)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled, color: Colors.white),
              onPressed: _showEnableBluetoothDialog,
            ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0E21),
              const Color(0xFF0A0E21).withOpacity(0.9),
              const Color(0xFF0A0E21).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Connect Your Bottle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (connectedDistance != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Distance: $connectedDistance mm',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isScanning
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isScanning
                        ? Colors.blue.withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isScanning)
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(right: 8),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                    Text(
                      isScanning
                          ? 'Scanning for nearby bottles...'
                          : scanResults.isEmpty
                              ? 'No bottles found nearby'
                              : '${scanResults.length} bottle${scanResults.length == 1 ? '' : 's'} found',
                      style: TextStyle(
                        color: isScanning ? Colors.blue : Colors.grey.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 400,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background glow
                        Container(
                          width: 340,
                          height: 340,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isScanning
                                    ? Colors.blue.withOpacity(0.09)
                                    : Colors.transparent,
                                spreadRadius: 10,
                                blurRadius: 60,
                              ),
                            ],
                          ),
                        ),
                        // Outer circle with animated gradient
                        AnimatedBuilder(
                          animation: _pulseAnimationController,
                          builder: (context, child) {
                            return Container(
                              width: 320,
                              height: 320,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isScanning
                                      ? Colors.blue.withOpacity(0.2 +
                                          0.1 * _pulseAnimationController.value)
                                      : Colors.blue.withOpacity(0.1),
                                  width: 1.5,
                                ),
                              ),
                            );
                          },
                        ),
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Center Bluetooth icon with pulsing effect
                        GestureDetector(
                          onTap: isScanning ? null : _startScanning,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: isScanning ? _pulseAnimation.value : 1.0,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        isScanning
                                            ? Colors.blue.shade700
                                            : const Color(0xFF1E2746),
                                        isScanning
                                            ? Colors.blue.shade900
                                            : const Color(0xFF131B38),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: isScanning
                                            ? Colors.blue.withOpacity(0.5)
                                            : Colors.black.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isScanning
                                        ? Icons.bluetooth_searching
                                        : Icons.bluetooth,
                                    color: isScanning
                                        ? Colors.white
                                        : Colors.blue.shade400,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Device indicators
                        if (scanResults.isNotEmpty)
                          ...List.generate(
                            math.min(scanResults.length, 8),
                            (index) {
                              final angle = (2 * math.pi * index) /
                                  math.min(scanResults.length, 8);
                              return _buildDeviceIndicator(
                                  angle, scanResults[index]);
                            },
                          ),
                        // Scanning animation
                        if (isScanning)
                          Container(
                            width: 320,
                            height: 320,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.withOpacity(0.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isScanning)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: ElevatedButton.icon(
                    onPressed: _startScanning,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Scan Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        dailyIntakes: dailyIntakes,
      ),
    );
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}
