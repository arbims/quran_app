import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> _quadrantImage() {
  const int size = 2;
  final pixels = Uint8List.fromList(<int>[
    255, 0, 0, 255, // haut gauche : rouge
    0, 255, 0, 255, // haut droite : vert
    0, 0, 255, 255, // bas gauche  : bleu
    255, 255, 0, 255, // bas droite : jaune
  ]);
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    size,
    size,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

Future<ui.Image> _solidImage(int r, int g, int b) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    Uint8List.fromList(<int>[r, g, b, 255]),
    1,
    1,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

Future<ByteData> _render(ui.FragmentShader shader, double side) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, side, side),
    Paint()..shader = shader,
  );
  final image =
      await recorder.endRecording().toImage(side.toInt(), side.toInt());
  return (await image.toByteData())!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le shader échantillonne les pages en coordonnées normalisées',
      () async {
    final program =
        await ui.FragmentProgram.fromAsset('shaders/mushaf_page_curl.frag');
    final shader = program.fragmentShader();
    final page = await _quadrantImage();

    const double side = 64;
    // `uCurlPos.x = 1` laisse toute la surface à plat : chaque pixel affiche
    // directement `uCurrentPage` échantillonné en `uv`.
    shader
      ..setFloat(0, side)
      ..setFloat(1, side)
      ..setFloat(2, 1)
      ..setFloat(3, 0.5)
      ..setFloat(4, 1)
      ..setFloat(5, 0)
      ..setFloat(6, 0.085)
      ..setFloat(7, 0.12)
      ..setFloat(8, 0.55)
      ..setFloat(9, 0)
      ..setImageSampler(0, page)
      ..setImageSampler(1, page);

    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, side, side),
      Paint()..shader = shader,
    );
    final rendered =
        await recorder.endRecording().toImage(side.toInt(), side.toInt());
    final data = await rendered.toByteData();

    int channel(int x, int y, int c) =>
        data!.getUint8((y * side.toInt() + x) * 4 + c);

    // Les quatre quadrants doivent se retrouver aux quatre coins : la page
    // remplit le rectangle au lieu d'être échantillonnée au pixel près.
    expect(channel(8, 8, 0), greaterThan(200)); // rouge
    expect(channel(56, 8, 1), greaterThan(200)); // vert
    expect(channel(8, 56, 2), greaterThan(200)); // bleu
    expect(channel(56, 56, 0), greaterThan(200)); // jaune
    expect(channel(56, 56, 1), greaterThan(200));
  });

  test('le pli d’avance découvre la page suivante par le bord gauche', () async {
    final program =
        await ui.FragmentProgram.fromAsset('shaders/mushaf_page_curl.frag');
    final shader = program.fragmentShader();
    final front = await _solidImage(255, 0, 0);
    final back = await _solidImage(0, 0, 255);

    const double side = 64;
    // Même réglage que MushafPageCurl pour l’avance : cylindre à mi-course,
    // direction vers la gauche (bord libre à gauche).
    shader
      ..setFloat(0, side)
      ..setFloat(1, side)
      ..setFloat(2, 0.5)
      ..setFloat(3, 0.5)
      ..setFloat(4, -1)
      ..setFloat(5, 0)
      ..setFloat(6, 0.085)
      ..setFloat(7, 0.12)
      ..setFloat(8, 0.55)
      ..setFloat(9, 0)
      ..setImageSampler(0, front)
      ..setImageSampler(1, back);

    final data = await _render(shader, side);
    int channel(int x, int y, int c) =>
        data.getUint8((y * side.toInt() + x) * 4 + c);

    // Gauche : page suivante découverte.
    expect(channel(6, 32, 2), greaterThan(150));
    expect(channel(6, 32, 0), lessThan(60));
    // Droite : page courante encore à plat.
    expect(channel(58, 32, 0), greaterThan(200));
    expect(channel(58, 32, 2), lessThan(60));
  });
}
