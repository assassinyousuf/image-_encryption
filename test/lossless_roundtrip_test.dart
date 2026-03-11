import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:image_to_audio/services/audio_decoder.dart';
import 'package:image_to_audio/services/audio_encoder.dart';
import 'package:image_to_audio/services/combined_key_service.dart';
import 'package:image_to_audio/services/encryption_service.dart';
import 'package:image_to_audio/services/image_processor.dart';
import 'package:image_to_audio/services/image_reconstructor.dart';
import 'package:image_to_audio/services/noise_resistant_transmission_service.dart';
import 'package:image_to_audio/utils/binary_converter.dart';

void main() {
  test(
    'Lossless I2A2 round-trip through WAV (clean file)',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'i2a_lossless_roundtrip_',
      );
      addTearDown(() async {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {
          // Best-effort cleanup.
        }
      });

      // Create a tiny but non-trivial PNG so the byte stream is realistic.
      const width = 2;
      const height = 2;
      final rgba = Uint8List(width * height * 4);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = (y * width + x) * 4;
          rgba[i + 0] = (x * 120 + 10) & 0xff; // R
          rgba[i + 1] = (y * 120 + 20) & 0xff; // G
          rgba[i + 2] = ((x + y) * 80 + 30) & 0xff; // B
          rgba[i + 3] = 255; // A
        }
      }

      final image = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: rgba.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );
      final originalPngBytes = Uint8List.fromList(img.encodePng(image));

      final imageFile = File(
        '${tempDir.path}${Platform.pathSeparator}sample.png',
      );
      await imageFile.writeAsBytes(originalPngBytes, flush: true);

      final processor = ImageProcessor();
      final payload = await processor.convertImageToBinary(imageFile);
      expect(payload.extension, equals('png'));

      final biometricKey = Uint8List.fromList(
        List<int>.generate(32, (i) => (i * 31 + 17) & 0xff),
      );
      final key = CombinedKeyService().deriveCombinedKey(
        biometricKey: biometricKey,
        pin: '1234',
      );
      final encryption = EncryptionService();
      final encryptedBytes = encryption.encryptBytes(
        dataBytes: payload.payloadBytes,
        key: key,
      );

      final nrsts = NoiseResistantTransmissionService(
        correctableSymbols: 8,
        repetitions: 3,
      );
      final protectedBytes = nrsts.protectEncryptedBytes(encryptedBytes);
      final protectedBits = BinaryConverter.bytesToBits(protectedBytes);

      final encoder = AudioEncoder();
      final packet = encoder.encodeBinaryToAudio(protectedBits);

      final wavFile = File(
        '${tempDir.path}${Platform.pathSeparator}encoded.wav',
      );
      await wavFile.writeAsBytes(packet.wavBytes!, flush: true);

      final decoder = AudioDecoder();
      final receivedBits = await decoder.decodeAudioToBinary(wavFile);

      final recoveredEncryptedBits = nrsts.recoverEncryptedBits(receivedBits);
      final decryptedBits = encryption.decryptBits(
        encryptedBits: recoveredEncryptedBits,
        key: key,
      );

      final reconstructor = ImageReconstructor();
      final decoded = reconstructor.reconstructImageFromBinaryBits(
        decryptedBits,
      );

      expect(decoded.extension, equals('png'));
      expect(decoded.payloadMagic, equals('I2A3'));
      expect(decoded.integrityVerified, isTrue);
      expect(decoded.bytes, equals(originalPngBytes));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
