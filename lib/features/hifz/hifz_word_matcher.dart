import '../../core/text/arabic_search_normalize.dart';
import '../../data/models/mushaf_word_layout.dart';

enum HifzWordStatus { hidden, revealed, mistake }

class HifzTrackWord {
  HifzTrackWord({
    required this.word,
    required this.normalized,
    this.status = HifzWordStatus.hidden,
    this.isBasmala = false,
    this.isAyahEnd = false,
  });

  final MushafWord word;
  final String normalized;
  HifzWordStatus status;
  final bool isBasmala;
  final bool isAyahEnd;

  bool get isTrackable => !isBasmala && normalized.isNotEmpty;
}

/// Aligne le texte reconnu (CTC) sur la séquence de mots attendus.
///
/// Comportement aligné sur l’ancienne appli :
/// - les mots restent masqués jusqu’à reconnaissance ;
/// - un saut (mot omis puis reprise) marque les mots sautés en erreur ;
/// - un bruit ASR sans correspondance n’avance pas le curseur (pas de fausse erreur).
class HifzWordMatcher {
  HifzWordMatcher(List<HifzTrackWord> words) : words = List.of(words);

  final List<HifzTrackWord> words;
  int cursor = 0;

  static const int lookAhead = 8;

  static List<HifzTrackWord> fromLayout(MushafWordLayout layout) {
    final out = <HifzTrackWord>[];
    for (var i = 0; i < layout.words.length; i++) {
      final w = layout.words[i];
      final text = w.text.trim();
      final normalized = normalizeArabicForSearch(text);
      final isBasmala = w.ayah == null && normalized.isNotEmpty;
      final next = i + 1 < layout.words.length ? layout.words[i + 1] : null;
      final isAyahEnd = w.marker != null ||
          (w.ayah != null &&
              (next == null ||
                  next.ayah != w.ayah ||
                  next.surah != w.surah));
      out.add(
        HifzTrackWord(
          word: w,
          normalized: normalized,
          status: isBasmala ? HifzWordStatus.revealed : HifzWordStatus.hidden,
          isBasmala: isBasmala,
          isAyahEnd: isAyahEnd,
        ),
      );
    }
    return out;
  }

  /// Avance le curseur selon l’énoncé ; souligne les mots sautés.
  void consumeUtterance(String raw) {
    var remaining = _compact(normalizeArabicForSearch(raw));
    if (remaining.isEmpty) return;

    _skipNonTrackable();

    while (cursor < words.length && remaining.isNotEmpty) {
      final hit = _bestPrefixHit(remaining);
      if (hit == null) {
        // Bruit / mauvaise reconnaissance : on attend le prochain énoncé.
        break;
      }

      final (index, consumed) = hit;
      if (index > cursor) {
        for (var i = cursor; i < index; i++) {
          if (!words[i].isTrackable) continue;
          if (words[i].status == HifzWordStatus.hidden) {
            words[i].status = HifzWordStatus.mistake;
          }
        }
      }

      words[index].status = HifzWordStatus.revealed;
      cursor = index + 1;
      remaining = remaining.substring(consumed);
      _skipNonTrackable();
    }
  }

  void _skipNonTrackable() {
    while (cursor < words.length && !words[cursor].isTrackable) {
      if (words[cursor].isBasmala) {
        words[cursor].status = HifzWordStatus.revealed;
      }
      cursor++;
    }
  }

  /// Cherche le premier mot (fenêtre) qui est un préfixe de [remaining].
  (int index, int consumed)? _bestPrefixHit(String remaining) {
    final end = (cursor + lookAhead).clamp(0, words.length);
    for (var i = cursor; i < end; i++) {
      final w = words[i];
      if (!w.isTrackable) continue;
      final consumed = _prefixConsume(remaining, w.normalized);
      if (consumed != null) return (i, consumed);
    }
    return null;
  }

  /// Si [needle] est un préfixe « souple » de [haystack], retourne la longueur
  /// consommée dans [haystack].
  static int? _prefixConsume(String haystack, String needle) {
    if (needle.isEmpty || haystack.isEmpty) return null;
    if (haystack.startsWith(needle)) return needle.length;

    // Préfixe strict trop court (1 lettre) : éviter les faux positifs.
    if (needle.length < 2) return null;

    // Tolérance : le modèle peut coller une lettre parasite en tête
    // (ex. waw de liaison) — on tente de sauter 1 caractère du flux ASR.
    if (haystack.length > needle.length + 1 &&
        haystack.substring(1).startsWith(needle)) {
      return needle.length + 1;
    }

    // Mot attendu légèrement plus long que le fragment reconnu en fin d’énoncé.
    if (needle.startsWith(haystack) && haystack.length >= 3) {
      return haystack.length;
    }

    return null;
  }

  static String _compact(String s) => s.replaceAll(RegExp(r'\s+'), '');

  bool get pageComplete =>
      cursor >= words.length ||
      words.every(
        (w) => !w.isTrackable || w.status != HifzWordStatus.hidden,
      );

  Set<String> get hiddenIds => {
        for (final w in words)
          if (w.status == HifzWordStatus.hidden && w.isTrackable) w.word.id,
      };

  Set<String> get mistakeIds => {
        for (final w in words)
          if (w.status == HifzWordStatus.mistake) w.word.id,
      };

  Set<String> get ayahEndIds => {
        for (final w in words)
          if (w.isAyahEnd) w.word.id,
      };
}
