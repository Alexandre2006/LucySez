import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:lucy_sez/services/bluetooth/config.dart';
import 'package:lucy_sez/services/client.dart';
import 'package:lucy_sez/services/compression.dart';
import 'package:lucy_sez/services/data_type.dart';
import 'package:lucy_sez/services/encryption.dart';
import 'package:lucy_sez/services/error.dart';
import 'package:lucy_sez/widgets/whiteboard/stroke.dart';

class BluetoothClient extends ClientService {
  BluetoothClient(this.device,
      {required super.onError,
      required super.onWhiteboardUpdated,
      required super.onWhiteboardImport,
      required super.onTextReceived});

  // Buffer
  Uint8List _buffer = Uint8List(0);

  // Bluetooth Device
  final Peripheral device;
  CentralManager centralManager = CentralManager();

  // Session Management
  @override
  Future<void> joinSession() async {
    // Authorization (Android Only)
    if (Platform.isAndroid) {
      bool authorized = await centralManager.authorize();
      if (!authorized) {
        throw LucySezError(
          title: "Could not join Bluetooth session",
          message:
              "LucySez needs Bluetooth permissions to connect to the host. Please enable Bluetooth permissions for LucySez.",
        );
      }
    }

    // Wait for central manager to be ready
    if (centralManager.state == BluetoothLowEnergyState.unknown) {
      // Wait 5s for the central manager to be ready
      await centralManager.stateChanged
          .firstWhere(
              (newValue) => newValue.state != BluetoothLowEnergyState.unknown)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw LucySezError(
              title: "Could not join Bluetooth session",
              message:
                  "Bluetooth failed to initialize. Please make sure Bluetooth is enabled on your device.",
            ),
          );
    }

    // Verify that the central manager is authorized and powered on
    if (centralManager.state == BluetoothLowEnergyState.unsupported) {
      throw LucySezError(
        title: "Could not join Bluetooth session",
        message:
            "Bluetooth is not supported on this device. Please make sure your device supports Bluetooth Low Energy.",
      );
    } else if (centralManager.state == BluetoothLowEnergyState.unauthorized) {
      throw LucySezError(
        title: "Could not join Bluetooth session",
        message:
            "LucySez needs Bluetooth permissions to connect to the host. Please enable Bluetooth permissions for LucySez.",
      );
    } else if (centralManager.state == BluetoothLowEnergyState.poweredOff) {
      throw LucySezError(
        title: "Could not join Bluetooth session",
        message:
            "Bluetooth is disabled on your device. Please enable Bluetooth to use LucySez.",
      );
    }

    // Connect to Host
    await centralManager.connect(device);

    // Wait for connection
    // await centralManager.connectionStateChanged
    //     .firstWhere(
    //       (newValue) => (newValue.state == ConnectionState.connected &&
    //           newValue.peripheral.uuid == device.uuid),
    //     )
    //     .timeout(
    //       const Duration(seconds: 5),
    //       onTimeout: () => throw LucySezError(
    //         title: "Could not join Bluetooth session",
    //         message:
    //             "Failed to connect to the host. Please make sure the host is available and try again.",
    //       ),
    //     );

    // Get Services
    final List<GATTService> services =
        await centralManager.discoverGATT(device);

    // Get Characteristics
    late final GATTCharacteristic headerCharacteristic;
    late final GATTCharacteristic dataCharacteristic;
    late final GATTCharacteristic requestCharacteristic;

    try {
      headerCharacteristic =
          services.expand((service) => service.characteristics).lastWhere(
                (characteristic) =>
                    characteristic.uuid.toString().toUpperCase() ==
                    headerCharacteristicUUID,
              );

      dataCharacteristic =
          services.expand((service) => service.characteristics).lastWhere(
                (characteristic) =>
                    characteristic.uuid.toString().toUpperCase() ==
                    dataCharacteristicUUID,
              );

      requestCharacteristic =
          services.expand((service) => service.characteristics).lastWhere(
                (characteristic) =>
                    characteristic.uuid.toString().toUpperCase() ==
                    requestCharacteristicUUID,
              );
    } catch (e) {
      throw LucySezError(
        title: "Could not join Bluetooth session",
        message:
            "Failed to find required characteristics. Please make sure the host is available and try again.",
        error: e as Error,
      );
    }

    // Subscribe to characteristics
    await centralManager.setCharacteristicNotifyState(
      device,
      headerCharacteristic,
      state: true,
    );

    await centralManager.setCharacteristicNotifyState(
      device,
      dataCharacteristic,
      state: true,
    );

    // Register Callbacks for Peripheral Events
    centralManager.characteristicNotified.listen((event) {
      print("NOTIFIED");
      if (event.characteristic.uuid ==
          UUID.fromString(headerCharacteristicUUID)) {
        print("HEADER NOTIFIED");
        _handleHeaderNotification(event.value);
      } else if (event.characteristic.uuid ==
          UUID.fromString(dataCharacteristicUUID)) {
        print("DATA NOTIFIED");
        _handleDataNotification(event.value);
      }
    });

    // Request host to send initial data
    await centralManager.readCharacteristic(device, requestCharacteristic);
  }

  @override
  Future<void> leaveSession() async {
    // Disconnect
    await centralManager.disconnect(device);
  }

  void _handleDataNotification(Uint8List data) {
    // Append to buffer
    _buffer = Uint8List.fromList([..._buffer, ...data]);

    // Check if buffer exceeds maximum size
    if (_buffer.length > maxBufferSize) {
      _buffer = _buffer.sublist(
        _buffer.length - maxBufferSize,
      );
    }
  }

  void _handleHeaderNotification(Uint8List data) {
    // Get Data Type (1st Byte)
    final type = DataType.values[data[0]];

    // Get Data Length (2nd-5th Byte)
    final length = (data[1] << 24) + (data[2] << 16) + (data[3] << 8) + data[4];

    // Check if buffer contains enough data
    if (_buffer.length < length) {
      return;
    }

    // Ensure full data has been received
    if (!initialDataReceived && type != DataType.full) {
      return;
    }

    // Check if close signal was received
    if (type == DataType.close) {
      leaveSession();
      return;
    }

    // Unpack Data
    List<int> packedData = _buffer.sublist(_buffer.length - length);

    try {
      unpackData(packedData, type);
    } catch (e) {
      onError(LucySezError(
        title: "Failed to unpack data",
        message: "Failed to unpack data from host.",
        error: e as Error,
      ));

      // Close Session
      leaveSession();
    }

    // Process Data
    print("GOT HERE");
    if (type == DataType.full) {
      initialDataReceived = true;

      // Decode JSON Strokes
      final strokes = jsonDecode(utf8.decode(packedData)) as List<Stroke>;

      // Send Strokes to Whiteboard
      onWhiteboardImport(strokes);
    } else if (type == DataType.changes) {
      // Decode JSON Changes
      final changes =
          jsonDecode(utf8.decode(packedData)) as Map<String, List<Stroke>>;

      print("CHANGES");

      // Send Changes to Whiteboard
      onWhiteboardUpdated(changes);
    } else if (type == DataType.text) {
      // Decode Text
      final text = utf8.decode(packedData);

      // Send Text to Whiteboard
      onTextReceived(text);
    }
  }
}
