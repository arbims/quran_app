/// Fichiers : `page_002.webp` … `page_604.webp`.
/// Le numéro de page = suffixe XXX dans `page_XXX.webp`.
class MushafConstants {
  MushafConstants._();

  static const int firstPage = 2;
  static const int lastPage = 604;
  static const int pageCount = lastPage - firstPage + 1;

  static const String pageImageExtension = 'webp';

  /// Taille réelle des WebP du mushaf (les `word_data` sont calibrés sur ~2481×3509).
  static const double mushafImagePixelWidth = 1615;
  static const double mushafImagePixelHeight = 2464;

  static String assetPathForPage(int page) {
    final clamped = resolveFilePage(page);
    return 'assets/mushaf/page_${clamped.toString().padLeft(3, '0')}.$pageImageExtension';
  }

  static int resolveFilePage(int page) {
    if (page < firstPage) return firstPage;
    if (page > lastPage) return lastPage;
    return page;
  }

  static int pageIndexFromFilePage(int filePage) =>
      resolveFilePage(filePage) - firstPage;

  /// Côté du feuillet dans le mushaf : la page 2 (début) est à **gauche**.
  /// Paires = gauche, impaires = droite.
  static bool isLeftPage(int filePage) => resolveFilePage(filePage).isEven;
}
