import 'package:cryptography/cryptography.dart';

final algorithm = AesGcm.with256bits();

Future<List<int>> encrypt(List<int> data, String pin) async {
  // Pad pin to 32 bytes
  pin = pin.padRight(32, '0');

  // Generate secret key
  final secretKey = await algorithm.newSecretKeyFromBytes(pin.codeUnits);

  // Encrypt
  final encrypted = await algorithm.encrypt(data, secretKey: secretKey);

  // Concatenate nonce, ciphertext, and mac
  final concatenated = encrypted.concatenation();

  // Return
  return concatenated;
}

// Decrypt
Future<List<int>> decrypt(List<int> data, String pin) async {
  // Pad pin to 32 bytes
  pin = pin.padRight(32, '0');

  // Generate secret key
  final secretKey = await algorithm.newSecretKeyFromBytes(pin.codeUnits);

  // De-concatenate nonce, ciphertext, and mac
  final encrypted =
      SecretBox.fromConcatenation(data, nonceLength: 12, macLength: 16);

  // Decrypt
  final decrypted = await algorithm.decrypt(encrypted, secretKey: secretKey);

  // Return
  return decrypted;
}
