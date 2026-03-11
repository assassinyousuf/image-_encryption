import 'dart:io';
import 'dart:typed_data';

import '../utils/signal_utils.dart';

class AudioDecoder {
  static const int bitDurationMs = 20;
  static const double freq0Hz = 1500.0;
  static const double freq1Hz = 3000.0;

  Future<List<int>> decodeAudioToBinary(
    File wavFile, {
    int? bitDurationMsOverride,
    double? frequency0HzOverride,
    double? frequency1HzOverride,
  }) async {
    final bytes = await wavFile.readAsBytes();
    final wav = _parseWavPcm16(bytes);

    final durationMs = bitDurationMsOverride ?? bitDurationMs;
    final f0 = frequency0HzOverride ?? freq0Hz;
    final f1 = frequency1HzOverride ?? freq1Hz;

    final spb = (wav.sampleRate * durationMs / 1000).round();
    if (spb <= 0) {
      throw StateError('Invalid samples-per-bit: $spb');
    }

    final totalBits = wav.samples.length ~/ spb;
    if (totalBits <= 0) {
      throw const FormatException('Audio too short to decode.');
    }

    final out = List<int>.filled(totalBits, 0, growable: false);

    for (var bitIndex = 0; bitIndex < totalBits; bitIndex++) {
      final start = bitIndex * spb;
      final p0 = SignalUtils.goertzelPowerInt16(
        samples: wav.samples,
        start: start,
        length: spb,
        sampleRate: wav.sampleRate,
        targetFrequencyHz: f0,
      );
      final p1 = SignalUtils.goertzelPowerInt16(
        samples: wav.samples,
        start: start,
        length: spb,
        sampleRate: wav.sampleRate,
        targetFrequencyHz: f1,
      );
      out[bitIndex] = p1 > p0 ? 1 : 0;
    }

    return out;
  }
}

class _WavPcm16 {
  final int sampleRate;
  final int channels;
  final Int16List samples;

  const _WavPcm16({
    required this.sampleRate,
    required this.channels,
    required this.samples,
  });
}

_WavPcm16 _parseWavPcm16(Uint8List bytes) {
  if (bytes.length < 44) {
    throw const FormatException('Not a valid WAV file (too short).');
  }

  final bd = ByteData.sublistView(bytes);
  final riff = _readAscii(bytes, 0, 4);
  final wave = _readAscii(bytes, 8, 4);
  if (riff != 'RIFF' || wave != 'WAVE') {
    throw const FormatException('Not a RIFF/WAVE file.');
  }

  int? sampleRate;
  int? channels;
  int? bitsPerSample;
  int? audioFormat;
  int? dataOffset;
  int? dataSize;

  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final chunkId = _readAscii(bytes, offset, 4);
    final chunkSize = bd.getUint32(offset + 4, Endian.little);
    final chunkDataStart = offset + 8;

    if (chunkDataStart + chunkSize > bytes.length) {
      break;
    }

    if (chunkId == 'fmt ') {
      if (chunkSize < 16) {
        throw const FormatException('Invalid fmt chunk size.');
      }
      audioFormat = bd.getUint16(chunkDataStart, Endian.little);
      channels = bd.getUint16(chunkDataStart + 2, Endian.little);
      sampleRate = bd.getUint32(chunkDataStart + 4, Endian.little);
      bitsPerSample = bd.getUint16(chunkDataStart + 14, Endian.little);
    } else if (chunkId == 'data') {
      dataOffset = chunkDataStart;
      dataSize = chunkSize;
      break;
    }

    offset = chunkDataStart + chunkSize;
    if (chunkSize.isOdd) {
      offset += 1;
    }
  }

  if (audioFormat == null ||
      channels == null ||
      bitsPerSample == null ||
      sampleRate == null ||
      dataOffset == null ||
      dataSize == null) {
    throw const FormatException('Missing required WAV chunks.');
  }

  if (audioFormat != 1) {
    throw const FormatException('Only PCM WAV is supported.');
  }
  if (channels != 1) {
    throw FormatException(
      'Only mono WAV is supported (got $channels channels).',
    );
  }
  if (bitsPerSample != 16) {
    throw FormatException(
      'Only 16-bit WAV is supported (got $bitsPerSample bits).',
    );
  }

  var safeDataSize = dataSize;
  if (dataOffset + safeDataSize > bytes.length) {
    safeDataSize = bytes.length - dataOffset;
  }
  safeDataSize -= safeDataSize % 2;

  final sampleCount = safeDataSize ~/ 2;
  final samples = Int16List(sampleCount);

  var sampleOffset = dataOffset;
  for (var i = 0; i < sampleCount; i++) {
    samples[i] = bd.getInt16(sampleOffset, Endian.little);
    sampleOffset += 2;
  }

  return _WavPcm16(
    sampleRate: sampleRate,
    channels: channels,
    samples: samples,
  );
}

String _readAscii(Uint8List bytes, int offset, int length) {
  if (offset < 0 || offset + length > bytes.length) {
    return '';
  }
  return String.fromCharCodes(bytes.sublist(offset, offset + length));
}
