import 'dart:convert';

import 'package:lucy_sez/services/compression.dart';
import 'package:lucy_sez/services/data_type.dart';
import 'package:lucy_sez/services/encryption.dart';
import 'package:lucy_sez/services/error.dart';
import 'package:lucy_sez/widgets/whiteboard/stroke.dart';

abstract class ClientService {
  // Encryption Parameters
  String? pin;

  // Initial Data
  bool initialDataReceived = false;

  // Callbacks
  void Function(LucySezError) onError;
  void Function(Map<String, List<Stroke>>) onWhiteboardUpdated;
  void Function(List<Stroke>) onWhiteboardImport;
  void Function(String) onTextReceived;

  // Session Management
  Future<void> joinSession();
  Future<void> leaveSession();

  // Encryption & Compression
  Future<void> unpackData(List<int> data, DataType type) async {
    // Decrypt & Decompress Data
    late final List<int> unpacked;
    if (pin == null) {
      unpacked = decompress(data);
    } else {
      final decrypted = await decrypt(data, pin!);
      unpacked = decompress(decrypted);
    }

    // Send data to appropriate handler
    switch (type) {
      case DataType.full:
        final strokes = jsonDecode(utf8.decode(unpacked))
            .map<Stroke>((e) => Stroke.fromJson(e))
            .toList();
        onWhiteboardImport(strokes);
        break;
      case DataType.changes:
        final changes = jsonDecode(utf8.decode(unpacked))
            .map<String, List<Stroke>>((key, value) => MapEntry(
                key,
                (value as List)
                    .map<Stroke>((e) => Stroke.fromJson(e))
                    .toList()));
        onWhiteboardUpdated(changes);
        break;
      case DataType.text:
        onTextReceived(utf8.decode(unpacked));
        break;
      case DataType.close:
        await leaveSession();
        break;
    }
  }

  // Constructor
  ClientService({
    required this.onError,
    required this.onWhiteboardUpdated,
    required this.onWhiteboardImport,
    required this.onTextReceived,
  });
}
