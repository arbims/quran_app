import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Pochette notification / écran verrouillé (`lecturebg.jpg`).
class MediaArtwork {
  MediaArtwork._();

  static Uri? _cached;

  static Future<Uri> uri() async {
    if (_cached != null) return _cached!;
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'lecturebg.jpg'));
    if (!await file.exists()) {
      final data = await rootBundle.load('assets/branding/lecturebg.jpg');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    _cached = file.uri;
    return _cached!;
  }
}
