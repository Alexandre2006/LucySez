import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/material.dart';
import 'package:lucy_sez/services/bluetooth/bluetooth_client.dart';
import 'package:lucy_sez/services/bluetooth/bluetooth_host.dart';
import 'package:lucy_sez/services/bluetooth/config.dart';
import 'package:lucy_sez/services/bluetooth/services.dart';
import 'package:lucy_sez/services/error.dart';
import 'package:lucy_sez/widgets/whiteboard/stroke.dart';
import 'package:lucy_sez/widgets/whiteboard/whiteboard.dart';
import 'package:lucy_sez/widgets/whiteboard/whiteboard_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LucySez',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final WhiteboardController _whiteboardController = WhiteboardController();
  final CentralManager _centralManager = CentralManager();
  bool isHosting = false;
  bool isClient = false;
  BluetoothHost? _host;
  BluetoothClient? _client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Whiteboard
            SizedBox(
              width: 200,
              height: 200,
              child: Whiteboard(
                controller: _whiteboardController,
                onWhiteboardUpdated: (changes) {
                  if (isHosting) {
                    _host?.sendChanges(changes);
                  }
                },
              ),
            ),
            Switch(
                value: isHosting,
                onChanged: (newValue) {
                  setState(() {
                    isHosting = newValue;
                    if (isHosting) {
                      _whiteboardController.clear();
                      // Disable Client
                      _client?.leaveSession();
                      _client = null;
                      isClient = false;

                      // Start Host
                      _host = BluetoothHost(
                        onFullDataRequested: () =>
                            _whiteboardController.export(),
                        onError: (error) {
                          print(error);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error.message),
                            ),
                          );
                        },
                      );

                      try {
                        _host?.startSession();
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text((error as LucySezError).message),
                          ),
                        );
                      }
                    } else {
                      _host?.endSession().then((output) {
                        print("SESSION ENDED");
                      });
                    }
                  });
                }),
            Switch(
                value: isClient,
                onChanged: (newValue) {
                  setState(() {
                    isClient = newValue;
                    if (isClient) {
                      _whiteboardController.clear();
                      // Disable Host
                      _host?.endSession();
                      _host = null;
                      isHosting = false;

                      // Scan for devices
                      _centralManager.startDiscovery(
                          serviceUUIDs: [UUID.fromString(serviceUUID)]);

                      _centralManager.discovered.forEach((discovered) {
                        print("DISCOVERED DEVICE");
                        _centralManager.stopDiscovery();
                        _client = BluetoothClient(discovered.peripheral,
                            onError: (LucySezError error) {
                          print(error);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error.message),
                            ),
                          );
                        }, onWhiteboardUpdated:
                                (Map<String, List<Stroke>> changes) {
                          _whiteboardController.importChanges(changes);
                        }, onWhiteboardImport: (List<Stroke> strokes) {
                          _whiteboardController.import(strokes);
                        }, onTextReceived: (String text) {
                          print("TEXT RECEIVED: $text");
                        });

                        _client?.joinSession().whenComplete(() {
                          print("JOINED SESSON");
                        });
                      });
                    } else {
                      _client?.leaveSession();

                      // Stop scanning
                      _centralManager.stopDiscovery();
                    }
                  });
                }),
          ],
        ),
      ),
    );
  }
}
