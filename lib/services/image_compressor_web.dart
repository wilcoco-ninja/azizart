import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:web/web.dart' as web;

/// Compresse via le navigateur : décodage natif (orientation EXIF et profil
/// couleur → sRGB), réduction par paliers, encodage JPEG sur fond blanc.
/// Renvoie `null` au moindre échec : l'appelant bascule sur le pipeline Dart.
Future<Uint8List?> compressWithBrowser(
  Uint8List bytes, {
  required int maxLongSide,
  required double quality,
}) async {
  web.ImageBitmap? bitmap;
  final canvases = <web.HTMLCanvasElement>[];

  try {
    final blob = web.Blob([bytes.toJS].toJS);

    try {
      bitmap = await web.window
          .createImageBitmap(
            blob,
            web.ImageBitmapOptions(
              imageOrientation: 'from-image',
              colorSpaceConversion: 'default',
            ),
          )
          .toDart;
    } catch (_) {
      // Navigateur ancien : options non reconnues.
      bitmap = await web.window.createImageBitmap(blob).toDart;
    }

    final srcW = bitmap.width;
    final srcH = bitmap.height;
    if (srcW <= 0 || srcH <= 0) return null;

    final longest = math.max(srcW, srcH);
    final scale = longest > maxLongSide ? maxLongSide / longest : 1.0;
    final targetW = math.max(1, (srcW * scale).round());
    final targetH = math.max(1, (srcH * scale).round());

    web.HTMLCanvasElement draw(
      JSObject source,
      int w,
      int h, {
      required bool flatten,
    }) {
      final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
      canvas.width = w;
      canvas.height = h;
      canvases.add(canvas);
      final ctx = canvas.getContext('2d');
      if (ctx == null) throw StateError('Canvas 2D indisponible');
      final c2d = ctx as web.CanvasRenderingContext2D;
      c2d.imageSmoothingEnabled = true;
      c2d.imageSmoothingQuality = 'high';
      if (flatten) {
        c2d.fillStyle = '#ffffff'.toJS;
        c2d.fillRect(0, 0, w, h);
      }
      c2d.drawImage(source, 0, 0, w, h);
      return canvas;
    }

    // Réduction par paliers de moitié : évite le crénelage d'une réduction
    // unique très forte (Safari notamment).
    JSObject source = bitmap;
    var curW = srcW;
    var curH = srcH;
    while (curW ~/ 2 >= targetW && curH ~/ 2 >= targetH) {
      final nextW = (curW / 2).ceil();
      final nextH = (curH / 2).ceil();
      source = draw(source, nextW, nextH, flatten: false);
      curW = nextW;
      curH = nextH;
    }
    final result = draw(source, targetW, targetH, flatten: true);

    final completer = Completer<web.Blob?>();
    result.toBlob(
      ((web.Blob? blob) {
        if (!completer.isCompleted) completer.complete(blob);
      }).toJS,
      'image/jpeg',
      quality.toJS,
    );
    final out = await completer.future.timeout(const Duration(seconds: 60));
    if (out == null) return null;

    final buffer = await out.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  } catch (e) {
    debugPrint('[Compression] navigateur indisponible, repli Dart : $e');
    return null;
  } finally {
    bitmap?.close();
    // Libère la mémoire des canvas (fuite connue sur Safari iOS).
    for (final canvas in canvases) {
      canvas.width = 0;
      canvas.height = 0;
    }
  }
}