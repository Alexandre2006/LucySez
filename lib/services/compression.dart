import 'package:archive/archive_io.dart';

List<int> compress(List<int> data) {
  final encoder = XZEncoder();
  return encoder.encode(data);
}

List<int> decompress(List<int> data) {
  final decoder = XZDecoder();
  return decoder.decodeBytes(data);
}
