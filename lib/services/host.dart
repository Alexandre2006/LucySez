import 'dart:convert';

import 'package:lucy_sez/services/compression.dart';
import 'package:lucy_sez/services/data_type.dart';
import 'package:lucy_sez/services/encryption.dart';
import 'package:lucy_sez/services/error.dart';
import 'package:lucy_sez/widgets/whiteboard/stroke.dart';

abstract class HostService {
  // Encryption Parameters
  String? pin;

  // Callback
  List<Stroke> Function() onFullDataRequested;
  void Function(LucySezError) onError;

  // Session Management
  Future<void> startSession();
  Future<void> endSession();

  // Transmitting Data (Raw)
  Future<void> send(List<int> data, DataType type);

  // Transmitting Data
  Future<void> sendChanges(Map<String, List<Stroke>> changes) async {
    // Encode JSON
    final json = changes.map((key, value) =>
        MapEntry(key, value.map((stroke) => stroke.toJson()).toList()));
    final data = await prepareData(jsonEncode(json).codeUnits);

    // Send Data
    await send(data, DataType.changes);
  }

  Future<void> sendFull(List<Stroke> strokes) async {
    // Encode JSON
    final json = strokes.map((stroke) => stroke.toJson()).toList();
    final data = await prepareData(jsonEncode(json).codeUnits);

    // Send Data
    await send(data, DataType.full);
  }

  Future<void> sendText(String text) async {
    // Encode JSON
    final data = utf8.encode(text);

    // Send Data
    await send(data, DataType.text);
  }

  Future<void> sendClose() async {
    // Send Close Signal
    await send([], DataType.close);
  }

  // Encryption & Compression
  Future<List<int>> prepareData(List<int> data) async {
    if (pin == null) {
      return compress(data);
    } else {
      final encrypted = await encrypt(data, pin!);
      return compress(encrypted);
    }
  }

  // Constructor
  HostService({
    required this.onFullDataRequested,
    required this.onError,
  });
}
