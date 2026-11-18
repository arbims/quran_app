import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/data/models/mushaf_word_layout.dart';
import 'package:quran_app/features/hifz/hifz_word_matcher.dart';

MushafWord _w(
  String id,
  String text, {
  int? surah = 1,
  int? ayah = 1,
}) {
  return MushafWord(
    id: id,
    text: text,
    line: 1,
    rect: const [0, 0, 10, 10],
    parts: const [],
    surah: surah,
    ayah: ayah,
  );
}

void main() {
  test('basmala reste visible et les ayat sont masqués', () {
    final layout = MushafWordLayout(
      page: 2,
      width: 100,
      height: 100,
      words: [
        _w('b1', 'بسم', ayah: null),
        _w('b2', 'الله', ayah: null),
        _w('a1', 'الحمد'),
        _w('a2', 'لله'),
      ],
    );
    final matcher = HifzWordMatcher(HifzWordMatcher.fromLayout(layout));

    expect(matcher.hiddenIds, {'a1', 'a2'});
    expect(matcher.words[0].status, HifzWordStatus.revealed);
    expect(matcher.words[1].status, HifzWordStatus.revealed);
  });

  test('autocomplétion : révèle les mots reconnus dans l’ordre', () {
    final layout = MushafWordLayout(
      page: 2,
      width: 100,
      height: 100,
      words: [
        _w('a1', 'الحمد'),
        _w('a2', 'لله'),
        _w('a3', 'رب'),
        _w('a4', 'العالمين'),
      ],
    );
    final matcher = HifzWordMatcher(HifzWordMatcher.fromLayout(layout));

    matcher.consumeUtterance('الحمد لله');
    expect(matcher.words[0].status, HifzWordStatus.revealed);
    expect(matcher.words[1].status, HifzWordStatus.revealed);
    expect(matcher.hiddenIds, {'a3', 'a4'});
    expect(matcher.mistakeIds, isEmpty);

    matcher.consumeUtterance('رب العالمين');
    expect(matcher.pageComplete, isTrue);
    expect(matcher.mistakeIds, isEmpty);
  });

  test('souligne comme erreur les mots sautés puis repris', () {
    final layout = MushafWordLayout(
      page: 2,
      width: 100,
      height: 100,
      words: [
        _w('a1', 'إياك'),
        _w('a2', 'نعبد'),
        _w('a3', 'وإياك'),
        _w('a4', 'نستعين'),
      ],
    );
    final matcher = HifzWordMatcher(HifzWordMatcher.fromLayout(layout));

    matcher.consumeUtterance('إياك نستعين');
    expect(matcher.words[0].status, HifzWordStatus.revealed);
    expect(matcher.words[1].status, HifzWordStatus.mistake);
    expect(matcher.words[2].status, HifzWordStatus.mistake);
    expect(matcher.words[3].status, HifzWordStatus.revealed);
  });

  test('bruit ASR sans correspondance ne marque pas d’erreur', () {
    final layout = MushafWordLayout(
      page: 2,
      width: 100,
      height: 100,
      words: [
        _w('a1', 'اهدنا'),
        _w('a2', 'الصراط'),
      ],
    );
    final matcher = HifzWordMatcher(HifzWordMatcher.fromLayout(layout));

    matcher.consumeUtterance('xyz');
    expect(matcher.hiddenIds, {'a1', 'a2'});
    expect(matcher.mistakeIds, isEmpty);
    expect(matcher.cursor, 0);
  });

  test('phrase CTC collée sans espaces', () {
    final layout = MushafWordLayout(
      page: 2,
      width: 100,
      height: 100,
      words: [
        _w('a1', 'ملك'),
        _w('a2', 'يوم'),
        _w('a3', 'الدين'),
      ],
    );
    final matcher = HifzWordMatcher(HifzWordMatcher.fromLayout(layout));

    matcher.consumeUtterance('مَلِكِ يَوْمِ الدِّينِ');
    expect(matcher.pageComplete, isTrue);
    expect(matcher.mistakeIds, isEmpty);
  });
}
