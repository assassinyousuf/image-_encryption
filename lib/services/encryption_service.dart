import 'dart:typed_data';

import '../utils/binary_converter.dart';

class EncryptionService {
  Uint8List encryptBytes({
    required Uint8List dataBytes,
    required Uint8List key,
  }) {
    return _xorBytes(dataBytes: dataBytes, key: key);
  }

  Uint8List decryptBytes({
    required Uint8List encryptedBytes,
    required Uint8List key,
  }) {
    return _xorBytes(dataBytes: encryptedBytes, key: key);
  }

  List<int> encryptBits({required List<int> dataBits, required Uint8List key}) {
    return _xorBits(dataBits: dataBits, key: key);
  }

  List<int> decryptBits({
    required List<int> encryptedBits,
    required Uint8List key,
  }) {
    return _xorBits(dataBits: encryptedBits, key: key);
  }

  Uint8List _xorBytes({required Uint8List dataBytes, required Uint8List key}) {
    if (dataBytes.isEmpty) {
      return Uint8List(0);
    }
    if (key.isEmpty) {
      throw ArgumentError('Key must not be empty.');
    }

    final out = Uint8List(dataBytes.length);
    for (var i = 0; i < dataBytes.length; i++) {
      out[i] = dataBytes[i] ^ key[i % key.length];
    }
    return out;
  }

  List<int> _xorBits({required List<int> dataBits, required Uint8List key}) {
    if (dataBits.isEmpty) {
      return <int>[];
    }
    if (key.isEmpty) {
      throw ArgumentError('Key must not be empty.');
    }

    final keyBits = BinaryConverter.bytesToBits(key);
    if (keyBits.isEmpty) {
      throw ArgumentError('Key must produce at least one bit.');
    }

    final out = Uint8List(dataBits.length);
    for (var i = 0; i < dataBits.length; i++) {
      final bit = dataBits[i];
      if (bit != 0 && bit != 1) {
        throw ArgumentError('Bits must be 0 or 1.');
      }
      out[i] = bit ^ keyBits[i % keyBits.length];
    }

    return out;
  }
}
