import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImagePayload {
  static const String magic = 'I2A1';
  static const int headerSizeBytes = 20;

  final int width;
  final int height;
  final int channels;
  final Uint8List payloadBytes;

  const ImagePayload({
    required this.width,
    required this.height,
    required this.channels,
    required this.payloadBytes,
  });
}

class ImageProcessor {
  static const int maxDimension = 32;

  Future<ImagePayload> convertImageToBinary(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw const FormatException('Unsupported or corrupted image file.');
    }

    final prepared = _prepareForTransmission(decoded);

    const channels = 3;
    final rgbBytes = prepared.getBytes(order: img.ChannelOrder.rgb);

    final expectedLen = prepared.width * prepared.height * channels;
    if (rgbBytes.length != expectedLen) {
      throw FormatException(
        'Unexpected RGB byte length. Expected $expectedLen, got ${rgbBytes.length}.',
      );
    }

    final header = ByteData(ImagePayload.headerSizeBytes);
    _writeAscii(header, 0, ImagePayload.magic);
    header.setUint32(4, prepared.width, Endian.little);
    header.setUint32(8, prepared.height, Endian.little);
    header.setUint32(12, channels, Endian.little);
    header.setUint32(16, rgbBytes.length, Endian.little);

    final payloadBytes = Uint8List(
      ImagePayload.headerSizeBytes + rgbBytes.length,
    );
    payloadBytes.setAll(0, header.buffer.asUint8List());
    payloadBytes.setAll(ImagePayload.headerSizeBytes, rgbBytes);

    return ImagePayload(
      width: prepared.width,
      height: prepared.height,
      channels: channels,
      payloadBytes: payloadBytes,
    );
  }

  img.Image _prepareForTransmission(img.Image image) {
    final w = image.width;
    final h = image.height;
    if (w <= maxDimension && h <= maxDimension) {
      return image;
    }

    final scale = math.min(maxDimension / w, maxDimension / h);
    final newW = math.max(1, (w * scale).round());
    final newH = math.max(1, (h * scale).round());

    return img.copyResize(
      image,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.average,
    );
  }

  void _writeAscii(ByteData bd, int offset, String s) {
    final units = s.codeUnits;
    for (var i = 0; i < units.length; i++) {
      bd.setUint8(offset + i, units[i]);
    }
  }
}
