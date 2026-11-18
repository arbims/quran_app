/// Normalisation pour la recherche (alignée sur `searchText` des données Dhibi).
String normalizeArabicForSearch(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (_isIgnorable(rune)) continue;
    buffer.writeCharCode(_canonicalLetter(rune));
  }
  return buffer.toString();
}

bool _isIgnorable(int rune) {
  if (rune == 0x0640) return true; // tatweel
  if (rune >= 0x064B && rune <= 0x065F) return true; // harakat
  if (rune >= 0x0670 && rune <= 0x0674) return true;
  if (rune == 0x0657 || rune == 0x0658) return true;
  if (rune == 0x06D6 || rune == 0x06D7) return true; // pause marks
  if (rune >= 0x06D9 && rune <= 0x06ED) return true;
  if (rune == 0x08F0 || rune == 0x08F1 || rune == 0x08F2) return true;
  if (rune == 0x08F3 || rune == 0x08F4) return true;
  if (rune == 0x0610 || rune == 0x0611 || rune == 0x0612) return true;
  if (rune == 0x0613 || rune == 0x0614 || rune == 0x0615) return true;
  if (rune == 0x0656) return true;
  if (rune == 0x06E5 || rune == 0x06E6) return true;
  if (rune == 0x06DF || rune == 0x06E0 || rune == 0x06E2) return true;
  if (rune == 0x06E3 || rune == 0x06E4) return true;
  if (rune == 0x06E7 || rune == 0x06E8) return true;
  if (rune == 0x06EA || rune == 0x06EB || rune == 0x06EC) return true;
  if (rune == 0x06D8) return true;
  if (rune == 0xFDEF) return true;
  if (rune == 0x08D4 || rune == 0x08D5 || rune == 0x08D6) return true;
  if (rune == 0x08D7 || rune == 0x08D8 || rune == 0x08D9) return true;
  if (rune == 0x08DA || rune == 0x08DB || rune == 0x08DC) return true;
  if (rune == 0x08DD || rune == 0x08DE || rune == 0x08DF) return true;
  if (rune == 0x08E0 || rune == 0x08E1) return true;
  if (rune == 0x08E3 || rune == 0x08E4 || rune == 0x08E5) return true;
  if (rune == 0x08E6 || rune == 0x08E7 || rune == 0x08E8) return true;
  if (rune == 0x08E9 || rune == 0x08EA || rune == 0x08EB) return true;
  if (rune == 0x08EC || rune == 0x08ED || rune == 0x08EE) return true;
  if (rune == 0x08EF) return true;
  if (rune == 0x08F8 || rune == 0x08F9 || rune == 0x08FA) return true;
  if (rune == 0x08FB || rune == 0x08FC || rune == 0x08FD) return true;
  if (rune == 0x08FE) return true;
  if (rune == 0x06DD) return true;
  if (rune == 0x06DE) return true;
  if (rune == 0x06DC) return true;
  if (rune == 0x06D6) return true;
  // espaces & ponctuation courante
  if (rune == 0x20 || rune == 0xA0) return true;
  if (rune == 0x060C || rune == 0x061B || rune == 0x061F) return true;
  if (rune == 0x06D4) return true;
  return false;
}

int _canonicalLetter(int rune) {
  switch (rune) {
    case 0x0622: // آ
    case 0x0623: // أ
    case 0x0625: // إ
    case 0x0671:
      return 0x0627; // ا
    case 0x0629: // ة
      return 0x0647; // ه
    case 0x0649: // ى
    case 0x06CC: // ی persian
      return 0x064A; // ي
    case 0xFB50:
    case 0xFB51:
      return 0x0627;
    default:
      return rune;
  }
}

String collapseSearchSpaces(String s) =>
    s.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).join(' ');
