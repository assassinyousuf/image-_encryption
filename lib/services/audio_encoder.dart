import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/audio_packet.dart';

class AudioEncoder {
  static const int sampleRate = 44100;
  static const int bitDurationMs = 20;

  static const double freq0Hz = 1500.0;
  static const double freq1Hz = 3000.0;

  static const int _channels = 1;
  static const double _amplitude = 0.8;

  int get samplesPerBit => (sampleRate * bitDurationMs / 1000).round();

  AudioPacket encodeBinaryToAudio(List<int> encryptedBits) {
    if (encryptedBits.isEmpty) {
      throw ArgumentError('Encrypted data is empty.');
    }

    final spb = samplesPerBit;
    if (spb <= 0) {
      throw StateError('Invalid samples-per-bit computed: $spb');
    }

    final totalSamples = encryptedBits.length * spb;
    final samples = Int16List(totalSamples);

    var phase = 0.0;
    final twoPi = 2.0 * math.pi;
    final amp = _amplitude * 32767.0;

    for (var bitIndex = 0; bitIndex < encryptedBits.length; bitIndex++) {
      final bit = encryptedBits[bitIndex];
      if (bit != 0 && bit != 1) {
        throw ArgumentError('Bits must be 0 or 1.');
      }

      final freq = bit == 0 ? freq0Hz : freq1Hz;
      final phaseInc = twoPi * freq / sampleRate;

      final base = bitIndex * spb;
      for (var i = 0; i < spb; i++) {
        phase += phaseInc;
        final sample = (math.sin(phase) * amp).round();
        samples[base + i] = sample < -32768
            ? -32768
            : (sample > 32767 ? 32767 : sample);
      }
    }

    final wavBytes = _writeWavPcm16(
      samples: samples,
      sampleRate: sampleRate,
      channels: _channels,
    );

    return AudioPacket(
      sampleRate: sampleRate,
      bitDurationMs: bitDurationMs,
      frequency0Hz: freq0Hz,
      frequency1Hz: freq1Hz,
      wavBytes: wavBytes,
    );
  }

  Future<File> saveAudioFile(Uint8List wavBytes, {String? fileName}) async {
    final outputDir = await _bestOutputDirectory();
    final name =
        fileName ??
        'encoded_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
    final file = File('${outputDir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(wavBytes, flush: true);
    return file;
  }

  Future<Directory> _bestOutputDirectory() async {
    final external = await getExternalStorageDirectory();
    if (external != null) {
      return external;
    }
    return getApplicationDocumentsDirectory();
  }

  Uint8List _writeWavPcm16({
    required Int16List samples,
    required int sampleRate,
    required int channels,
  }) {
    const bitsPerSample = 16;
    final dataSize = samples.length * 2;
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final riffChunkSize = 36 + dataSize;

    final out = Uint8List(44 + dataSize);
    final bd = ByteData.sublistView(out);

    _writeAscii(bd, 0, 'RIFF');
    bd.setUint32(4, riffChunkSize, Endian.little);
    _writeAscii(bd, 8, 'WAVE');

    _writeAscii(bd, 12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, channels, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, byteRate, Endian.little);
    bd.setUint16(32, blockAlign, Endian.little);
    bd.setUint16(34, bitsPerSample, Endian.little);

    _writeAscii(bd, 36, 'data');
    bd.setUint32(40, dataSize, Endian.little);

    var offset = 44;
    for (var i = 0; i < samples.length; i++) {
      bd.setInt16(offset, samples[i], Endian.little);
      offset += 2;
    }

    return out;
  }

  void _writeAscii(ByteData bd, int offset, String s) {
    final units = s.codeUnits;
    for (var i = 0; i < units.length; i++) {
      bd.setUint8(offset + i, units[i]);
    }
  }
}
