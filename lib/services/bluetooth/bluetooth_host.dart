import 'dart:io';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:lucy_sez/services/bluetooth/characteristics.dart';
import 'package:lucy_sez/services/bluetooth/config.dart';
import 'package:lucy_sez/services/bluetooth/services.dart';
import 'package:lucy_sez/services/data_type.dart';
import 'package:lucy_sez/services/error.dart';
import 'package:lucy_sez/services/host.dart';

class BluetoothHost extends HostService {
  PeripheralManager peripheralManager = PeripheralManager();
  Central? central;
  List<TransmissionRequest> transmissionQueue = [];
  bool closed = false;

  BluetoothHost({required super.onFullDataRequested, required super.onError});

  // Session Management
  @override
  Future<void> startSession() async {
    // Request Authorization (Android Only)
    if (Platform.isAndroid) {
      bool authorized = await peripheralManager.authorize();
      if (!authorized) {
        throw LucySezError(
          title: "Could not start Bluetooth session",
          message:
              "LucySez needs Bluetooth permissions to allow other devices to connect. Please enable Bluetooth permissions for LucySez.",
        );
      }
    }

    // Wait for peripheral manager to be ready
    if (peripheralManager.state == BluetoothLowEnergyState.unknown) {
      // Wait 5s for the peripheral manager to be ready
      await peripheralManager.stateChanged
          .firstWhere(
              (newValue) => newValue.state != BluetoothLowEnergyState.unknown)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw LucySezError(
              title: "Could not start Bluetooth session",
              message:
                  "Bluetooth failed to initialize. Please make sure Bluetooth is enabled on your device.",
            ),
          );
    }

    // Verify that the peripheral manager is authorized and powered on
    if (peripheralManager.state == BluetoothLowEnergyState.unsupported) {
      throw LucySezError(
        title: "Could not start Bluetooth session",
        message:
            "Bluetooth is not supported on this device. Please make sure your device supports Bluetooth Low Energy.",
      );
    } else if (peripheralManager.state ==
        BluetoothLowEnergyState.unauthorized) {
      throw LucySezError(
        title: "Could not start Bluetooth session",
        message:
            "LucySez needs Bluetooth permissions to allow other devices to connect. Please enable Bluetooth permissions for LucySez.",
      );
    } else if (peripheralManager.state == BluetoothLowEnergyState.poweredOff) {
      throw LucySezError(
        title: "Could not start Bluetooth session",
        message:
            "Bluetooth is disabled on your device. Please enable Bluetooth to use LucySez.",
      );
    }

    // Close any existing services
    await peripheralManager.removeAllServices();

    // Register Callbacks for Central Events
    peripheralManager.characteristicNotifyStateChanged.listen((event) {
      print("NOTIFY STATE CHANGED: ${event.characteristic.uuid}");
      central = event.central;
    });

    peripheralManager.characteristicReadRequested.listen((event) async {
      print("READ REQUESTED: ${event.characteristic.uuid}");

      // Respond to request
      peripheralManager.respondReadRequestWithValue(event.request,
          value: Uint8List.fromList([]));

      // Check if the characteristic UUID is the request UUID
      if (event.characteristic.uuid.toString() != requestCharacteristicUUID) {
        return;
      }

      // Check if the request queue already contains a request for full data
      if (transmissionQueue.any((element) => element.type == DataType.full)) {
        return;
      }

      // Add a request for full data to the queue
      await sendFull(onFullDataRequested());

      print("FULL DATA REQUESTED");
    });

    // Add Service
    await peripheralManager.addService(service);

    // Start Advertising
    await peripheralManager.startAdvertising(
      Advertisement(
        serviceUUIDs: [
          UUID.fromString(serviceUUID),
        ],
      ),
    );

    sendDaemon();
  }

  @override
  Future<void> endSession() async {
    // Send Close Signal
    await sendClose();

    // Wait for transmission to finish
    while (transmissionQueue.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Stop Advertising
    await peripheralManager.stopAdvertising();

    // Close Services
    await peripheralManager.removeAllServices();

    // Close Transmission
    closed = true;
  }

  // Transmitting Data (Raw)
  @override
  Future<void> send(List<int> data, DataType type) async {
    // Add to transmission queue (prioritize full data)
    transmissionQueue.add(TransmissionRequest(data, type));
  }

  Future<void> sendDaemon() async {
    while (!closed) {
      // Check if there is anything to transmit
      if (transmissionQueue.isEmpty) {
        print("NOTHING TO TRANSMIT");
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      // Get the first item in the queue
      final TransmissionRequest request = transmissionQueue.removeAt(0);
      print(
          "TRANSMITTING: ${request.type} in ${(request.data.length / 512).floor() + 1} packets");

      // Prepare Header Data (1byte for type, 4bytes for length)
      final header = [
        request.type.index,
        (request.data.length >> 24) & 0xFF,
        (request.data.length >> 16) & 0xFF,
        (request.data.length >> 8) & 0xFF,
        request.data.length & 0xFF,
      ];

      // Transmit Data
      try {
        for (int i = 0; i < request.data.length; i += 512) {
          // Calculate actual end (if not divisible by 512)
          int max = i + 512;
          if (max > request.data.length) {
            max = request.data.length;
          }

          // Send Data
          if (central != null) {
            await peripheralManager.notifyCharacteristic(
              central!,
              dataCharacteristic,
              value: Uint8List.fromList(
                request.data.sublist(i, max),
              ),
            );
          }
        }
      } catch (e) {
        onError(
          LucySezError(
            title: "Failed to transmit data",
            message:
                "Please ensure that Bluetooth is turned on and all permissions are granted.",
            error: e as Error,
          ),
        );

        return;
      }

      // Transmit Header
      try {
        if (central != null) {
          await peripheralManager.notifyCharacteristic(
            central!,
            headerCharacteristic,
            value: Uint8List.fromList(header),
          );
        }
      } catch (e) {
        onError(
          LucySezError(
            title: "Failed to transmit data",
            message:
                "Please ensure that Bluetooth is turned on and all permissions are granted.",
            error: e as Error,
          ),
        );
        return;
      }
    }
  }
}

class TransmissionRequest {
  final List<int> data;
  final DataType type;

  TransmissionRequest(this.data, this.type);
}
