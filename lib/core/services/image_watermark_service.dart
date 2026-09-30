import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class ImageWatermarkService {
  const ImageWatermarkService();

  Future<Uint8List> applyCenteredLogoWatermark(
    Uint8List sourceBytes, {
    String logoAssetPath = 'assets/images/malaya_logo.png',
    double logoWidthRatio = 0.25,
    double logoOpacity = 0.28,
  }) async {
    final base = img.decodeImage(sourceBytes);
    if (base == null) {
      throw StateError('Could not read selected image.');
    }

    final logoAsset = await rootBundle.load(logoAssetPath);
    final logo = img.decodeImage(logoAsset.buffer.asUint8List());
    if (logo == null) {
      throw StateError('Logo asset could not be loaded.');
    }

    final targetLogoWidth =
        (base.width * logoWidthRatio).round().clamp(1, base.width);
    final resizedLogo = img.copyResize(logo, width: targetLogoWidth);
    final transparentLogo = _applyOpacity(
      resizedLogo,
      logoOpacity.clamp(0.2, 0.35),
    );

    final dstX = ((base.width - transparentLogo.width) / 2).round();
    final dstY = ((base.height - transparentLogo.height) / 2).round();
    img.compositeImage(base, transparentLogo, dstX: dstX, dstY: dstY);

    return Uint8List.fromList(img.encodeJpg(base, quality: 92));
  }

  img.Image _applyOpacity(img.Image image, double opacity) {
    final adjusted = img.Image.from(image);
    for (var y = 0; y < adjusted.height; y++) {
      for (var x = 0; x < adjusted.width; x++) {
        final px = adjusted.getPixel(x, y);
        final alpha = (px.a * opacity).round().clamp(0, 255);
        adjusted.setPixelRgba(x, y, px.r, px.g, px.b, alpha);
      }
    }
    return adjusted;
  }
}
