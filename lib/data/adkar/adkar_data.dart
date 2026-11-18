import 'package:flutter/material.dart';

import 'adkar_models.dart';

final List<AdkarCategory> kAdkarCategories = [
  const AdkarCategory(
    id: 'morning',
    titleAr: 'أذكار الصباح',
    subtitleAr: 'ما يُقال بعد الفجر',
    icon: Icons.wb_sunny_outlined,
  ),
  const AdkarCategory(
    id: 'evening',
    titleAr: 'أذكار المساء',
    subtitleAr: 'ما يُقال بعد العصر',
    icon: Icons.nights_stay_outlined,
  ),
  const AdkarCategory(
    id: 'sleep',
    titleAr: 'أذكار النوم',
    subtitleAr: 'قبل النوم',
    icon: Icons.bedtime_outlined,
  ),
  const AdkarCategory(
    id: 'after_prayer',
    titleAr: 'أذكار بعد الصلاة',
    subtitleAr: 'أذكار مأثورة',
    icon: Icons.mosque_outlined,
  ),
  const AdkarCategory(
    id: 'misc',
    titleAr: 'أدعية متنوعة',
    subtitleAr: 'لمناسبات مختلفة',
    icon: Icons.auto_awesome_outlined,
  ),
];

const Map<String, List<AdkarItem>> kAdkarByCategory = {
  'morning': [
    AdkarItem(
      textAr:
          'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
      repeat: 1,
    ),
    AdkarItem(
      textAr:
          'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ.',
      repeat: 1,
    ),
    AdkarItem(
      textAr:
          'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.',
      repeat: 1,
      reference: 'سيد الاستغفار',
    ),
    AdkarItem(
      textAr:
          'آيَةُ الْكُرْسِيِّ: اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ...',
      repeat: 1,
      reference: 'البقرة: 255',
    ),
    AdkarItem(
      textAr:
          'قُلْ هُوَ اللَّهُ أَحَدٌ ﴿١﴾ اللَّهُ الصَّمَدُ ﴿٢﴾ لَمْ يَلِدْ وَلَمْ يُولَدْ ﴿٣﴾ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ ﴿٤﴾',
      repeat: 3,
      reference: 'الإخلاص',
    ),
    AdkarItem(
      textAr:
          'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ﴿١﴾ مِنْ شَرِّ مَا خَلَقَ ﴿٢﴾...',
      repeat: 3,
      reference: 'الفلق',
    ),
    AdkarItem(
      textAr:
          'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ﴿١﴾ مَلِكِ النَّاسِ ﴿٢﴾...',
      repeat: 3,
      reference: 'الناس',
    ),
    AdkarItem(
      textAr: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.',
      repeat: 100,
    ),
  ],
  'evening': [
    AdkarItem(
      textAr:
          'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ...',
      repeat: 1,
    ),
    AdkarItem(
      textAr:
          'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ.',
      repeat: 1,
    ),
    AdkarItem(
      textAr: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.',
      repeat: 3,
    ),
    AdkarItem(
      textAr:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ...',
      repeat: 1,
    ),
  ],
  'sleep': [
    AdkarItem(
      textAr: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا.',
      repeat: 1,
    ),
    AdkarItem(
      textAr:
          'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ.',
      repeat: 3,
    ),
    AdkarItem(
      textAr:
          'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا، وَكَفَانَا، وَآوَانَا، فَكَمْ مِمَّنْ لَا كَافِيَ لَهُ وَلَا مُؤْوِي.',
      repeat: 1,
    ),
    AdkarItem(
      textAr: 'آيَةُ الْكُرْسِيِّ.',
      repeat: 1,
      reference: 'البقرة: 255',
    ),
    AdkarItem(
      textAr: 'قُلْ هُوَ اللَّهُ أَحَدٌ — و المعوذتان.',
      repeat: 3,
      reference: 'الإخلاص · الفلق · الناس',
    ),
  ],
  'after_prayer': [
    AdkarItem(
      textAr: 'أَسْتَغْفِرُ اللَّهَ.',
      repeat: 3,
    ),
    AdkarItem(
      textAr:
          'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.',
      repeat: 1,
    ),
    AdkarItem(
      textAr:
          'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ...',
      repeat: 1,
      reference: 'التسبيح',
    ),
    AdkarItem(
      textAr: 'سُبْحَانَ اللَّهِ.',
      repeat: 33,
    ),
    AdkarItem(
      textAr: 'الْحَمْدُ لِلَّهِ.',
      repeat: 33,
    ),
    AdkarItem(
      textAr: 'اللَّهُ أَكْبَرُ.',
      repeat: 33,
    ),
  ],
  'misc': [
    AdkarItem(
      textAr:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.',
      repeat: 1,
    ),
    AdkarItem(
      textAr:
          'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَأَعُوذُ بِكَ مِنَ الْعَجْزِ وَالْكَسَلِ...',
      repeat: 1,
    ),
    AdkarItem(
      textAr: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ.',
      repeat: 1,
    ),
    AdkarItem(
      textAr:
          'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ ۖ عَلَيْهِ تَوَكَّلْتُ ۖ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ.',
      repeat: 7,
    ),
  ],
};

AdkarCategory? adkarCategoryById(String id) {
  try {
    return kAdkarCategories.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}

List<AdkarItem> adkarItemsForCategory(String id) =>
    kAdkarByCategory[id] ?? [];
