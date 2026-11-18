/// Marges du scan source Dhibi (1900×2687), identiques à `images_all/crop.py`.
///
/// Les WebP du projet sont déjà recadrés (paire : 1615×2464 ; impaire : 1609×2464).
/// Le `word_data` reste calé sur la page complète : le surlignage retranche
/// ces marges avant le mapping vers l’image affichée.
class MushafPageImageCrop {
  MushafPageImageCrop._();

  static const double sourceWidth = 1900;
  static const double sourceHeight = 2687;
  static const double top = 99;
  static const double bottom = 124;

  static double leftForPage(int filePage) => filePage.isEven ? 190 : 96;

  static double rightForPage(int filePage) => filePage.isEven ? 95 : 195;

  static double contentWidthForPage(int filePage) =>
      sourceWidth - leftForPage(filePage) - rightForPage(filePage);

  static const double contentHeight = sourceHeight - top - bottom;
}
