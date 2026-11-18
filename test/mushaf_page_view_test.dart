import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_app/core/constants/mushaf_constants.dart';
import 'package:quran_app/features/reading/widgets/mushaf_page_curl.dart';
import 'package:quran_app/features/reading/widgets/mushaf_page_view.dart';

void main() {
  testWidgets('le pli connaît ses pages voisines', (tester) async {
    final controller = MushafPageCurlController();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MushafPageView(
            curlController: controller,
            pageIndex: 0,
            onPageChanged: (_) {},
          ),
        ),
      ),
    );

    // Première page du mushaf : on peut avancer mais pas reculer.
    expect(controller.canGoPrevious, isFalse);
    expect(controller.canGoNext, isTrue);

    final curl = tester.widget<MushafPageCurl>(find.byType(MushafPageCurl));
    expect(curl.pageCount, MushafConstants.pageCount);
  });
}
