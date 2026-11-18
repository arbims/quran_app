import 'juzz_data.dart';
import 'models/hizb.dart';

/// 60 أحزاب — page de début : début de juz + milieu approximatif entre deux juz.
final List<Hizb> kHizb = [
  for (var j = 0; j < kJuzz.length; j++) ...[
    Hizb(number: j * 2 + 1, startPage: kJuzz[j].startPage),
    Hizb(
      number: j * 2 + 2,
      startPage: j < kJuzz.length - 1
          ? (kJuzz[j].startPage + kJuzz[j + 1].startPage) ~/ 2
          : kJuzz[j].startPage + 10,
    ),
  ],
];
