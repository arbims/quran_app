import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/constants/mushaf_page_image_crop.dart';
import 'package:quran_app/features/reading/widgets/mushaf_page_coordinate_transform.dart';

void main() {
  test('marges crop.py — paire / impaire', () {
    expect(MushafPageImageCrop.leftForPage(2), 190);
    expect(MushafPageImageCrop.rightForPage(2), 95);
    expect(MushafPageImageCrop.contentWidthForPage(2), 1615);

    expect(MushafPageImageCrop.leftForPage(3), 96);
    expect(MushafPageImageCrop.rightForPage(3), 195);
    expect(MushafPageImageCrop.contentWidthForPage(3), 1609);

    expect(MushafPageImageCrop.top, 99);
    expect(MushafPageImageCrop.bottom, 124);
    expect(MushafPageImageCrop.contentHeight, 2464);
  });

  test('word_data → WebP recadré : hors marges, pas de mapping linéaire brut', () {
    const layoutSize = Size(2481, 3509);
    const destSize = Size(1615, 2464);

    final transform = MushafPageCoordinateTransform.forLocalDest(
      layoutSize: layoutSize,
      destSize: destSize,
      filePage: 2,
    );

    // Coin layout → doit atterrir après left/top du crop, pas en (0,0).
    final origin = transform.layoutToCropped(0, 0);
    expect(origin.dx, closeTo(-190, 0.01));
    expect(origin.dy, closeTo(-99, 0.01));

    // Point au début de la zone utile source (left, top) → (0,0) croppé.
    final useful = transform.layoutToCropped(
      190 / 1900 * 2481,
      99 / 2687 * 3509,
    );
    expect(useful.dx, closeTo(0, 0.5));
    expect(useful.dy, closeTo(0, 0.5));

    // Différence notable vs mapping linéaire (régression du décalage jaune).
    const word = [1888.0, 2214.0];
    final cropped = transform.layoutToCropped(word[0], word[1]);
    final linearX = word[0] / 2481 * 1615;
    final linearY = word[1] / 3509 * 2464;
    expect((cropped.dx - linearX).abs(), greaterThan(20));
    expect((cropped.dy - linearY).abs(), greaterThan(20));

    final screen = transform.layoutToScreen(word[0], word[1]);
    expect(screen.dx, closeTo(cropped.dx, 0.01));
    expect(screen.dy, closeTo(cropped.dy, 0.01));
  });

  test('ordre vertical basmala puis ayah conservé après crop', () {
    final transform = MushafPageCoordinateTransform.forLocalDest(
      layoutSize: const Size(2481, 3509),
      destSize: const Size(400, 580),
      filePage: 2,
    );

    final basmala = transform.layoutRectToScreen([1503, 543, 367, 120]);
    final ayah = transform.layoutRectToScreen([2091, 2826, 122, 209]);
    expect(ayah.top, greaterThan(basmala.bottom));
  });
}
