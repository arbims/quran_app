import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Prépare les modèles ONNX (parties concaténées) dans le stockage local.
class HifzModelAssets {
  HifzModelAssets._();

  static const _ctcAssetDir = 'assets/models/quran_ctc';
  static const _vadAsset = 'assets/models/vad/silero_vad.onnx';

  static Future<({String modelPath, String tokensPath, String vadPath})>
      ensureReady() async {
    final docs = await getApplicationSupportDirectory();
    final outDir = Directory(p.join(docs.path, 'hifz_models'));
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    final bundleRaw = await rootBundle.loadString('$_ctcAssetDir/bundle.json');
    final bundle = jsonDecode(bundleRaw) as Map<String, dynamic>;
    final files = bundle['files'] as Map<String, dynamic>;
    final modelMeta = files['model.int8.onnx'] as Map<String, dynamic>;
    final expectedBytes = modelMeta['bytes'] as int;
    final parts = (modelMeta['parts'] as List<dynamic>).cast<String>();

    final modelPath = p.join(outDir.path, 'model.int8.onnx');
    final modelFile = File(modelPath);
    if (!await modelFile.exists() || await modelFile.length() != expectedBytes) {
      final sink = modelFile.openWrite();
      try {
        for (final part in parts) {
          final data = await rootBundle.load('$_ctcAssetDir/$part');
          sink.add(data.buffer.asUint8List());
        }
      } finally {
        await sink.close();
      }
    }

    final tokensPath = p.join(outDir.path, 'tokens.txt');
    final tokensFile = File(tokensPath);
    if (!await tokensFile.exists()) {
      final data = await rootBundle.load('$_ctcAssetDir/tokens.txt');
      await tokensFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }

    final vadPath = p.join(outDir.path, 'silero_vad.onnx');
    final vadFile = File(vadPath);
    if (!await vadFile.exists()) {
      final data = await rootBundle.load(_vadAsset);
      await vadFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }

    return (modelPath: modelPath, tokensPath: tokensPath, vadPath: vadPath);
  }
}
