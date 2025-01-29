/* 
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const BottlePageApp());
}

class BottlePageApp extends StatelessWidget {
  const BottlePageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bottle',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      debugShowCheckedModeBanner: false,
      home: const BottlePage(),
    );
  }
}

class BottlePage extends StatefulWidget {
  const BottlePage({super.key});

  @override
  BottlePageState createState() => BottlePageState();
}

class BottlePageState extends State<BottlePage> {
  Future<void> _checkAndRequestBluetooth() async {
    BluetoothAdapterState adapterState =
        await FlutterBluePlus.adapterState.first;

    if (adapterState == BluetoothAdapterState.on) {
      // Navigate to BluetoothDeviceListScreen when Bluetooth is on
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const BluetoothDeviceListScreen()),
      );
    } else {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.blueGrey.shade200,
          title: const Text('Bluetooth is Off',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 9, 47, 103),
              )),
          content: Text(
            'Would you like to turn on Bluetooth?',
            style: TextStyle(
                color: Colors.blueGrey.shade800, fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FlutterBluePlus.turnOn();
                BluetoothAdapterState newState =
                    await FlutterBluePlus.adapterState.first;
                if (newState == BluetoothAdapterState.on) {
                  print('Bluetooth has been turned on!');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const BluetoothDeviceListScreen()),
                  );
                } else {
                  print('Bluetooth is still off. Cannot proceed.');
                }
              },
              child: const Text('Yes',
                  style: TextStyle(
                    color: Color.fromARGB(255, 9, 47, 103),
                    fontWeight: FontWeight.w600,
                  )),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'No',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade100,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.blueGrey.shade100,
        title: Text(
          'Bottle',
          style: TextStyle(
            color: Colors.blueGrey.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 50),
            SizedBox(
              width: 270,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.asset(
                  'lib/images/bottle2.jpg',
                  height: 270,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(
              width: 270,
              child: ElevatedButton(
                onPressed: _checkAndRequestBluetooth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 9, 47, 103),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bluetooth,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 1),
                    Text(
                      'Connect Bottle',
                      style: TextStyle(
                        color: Colors.blueGrey.shade100,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BluetoothDeviceListScreen extends StatefulWidget {
  const BluetoothDeviceListScreen({super.key});

  @override
  _BluetoothDeviceListScreenState createState() =>
      _BluetoothDeviceListScreenState();
}

class _BluetoothDeviceListScreenState extends State<BluetoothDeviceListScreen> {
  List<BluetoothDevice> pairedDevices = [];
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;

  // Define the specific device ID and name for filtering
  final String targetDeviceId = 'XX:XX:XX:XX:XX:XX';  // Example ID
  final String targetDeviceName = 'SpecificDeviceName'; // Example name

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final bondedDevices = await FlutterBluePlus.bondedDevices;
    setState(() {
      pairedDevices = bondedDevices
          .where((device) =>
              device.remoteId.toString() == targetDeviceId ||
              device.platformName.contains(targetDeviceName))
          .toList();
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results
            .where((result) =>
                result.device.remoteId.toString() == targetDeviceId ||
                result.device.platformName.contains(targetDeviceName))
            .toList();
      });
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
      });
      Navigator.pop(context); // Close the screen after successful connection
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Connected to ${device.platformName}'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to connect to ${device.platformName}: $e'),
      ));
    }
  }

  Future<void> _pairAndConnectDevice(BluetoothDevice device) async {
    try {
      await device.createBond(); // Bond (pair) with the device
      await _connectToDevice(device);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to pair/connect to ${device.platformName}: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        backgroundColor: Colors.blueGrey.shade100,
        toolbarHeight: 70,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            const Text(
              'Paired Devices:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            ...pairedDevices.map((device) {
              return ListTile(
                title: Text(device.platformName),
                subtitle: Text(device.remoteId.toString()),
                onTap: () => _connectToDevice(device),
              );
            }),
            const Divider(),
            const Text(
              'Available Devices:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            ...scanResults.map((result) {
              return ListTile(
                title: Text(result.device.platformName.isNotEmpty
                    ? result.device.platformName
                    : 'Unknown Device'),
                subtitle: Text(result.device.remoteId.toString()),
                onTap: () => _pairAndConnectDevice(result.device),
              );
            }),
          ],
        ),
      ),
    );
  }
}
*/