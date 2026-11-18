# quran_app

Mushaf Qaloon — lecture, recherche, audio et hifz (Flutter).

## Prérequis

- Flutter SDK (compatible `sdk: ^3.13.7` dans `pubspec.yaml`)
- Assets runtime non versionnés (voir ci-dessous)

## Assets hors Git (~400 Mo)

Pour garder le dépôt léger, ces fichiers **ne sont pas** sur GitHub :

| Chemin | Contenu |
|--------|---------|
| `assets/mushaf/*.webp` | Pages du mushaf (`page_002.webp` … `page_603.webp`) |
| `assets/models/quran_ctc/model.int8.onnx.part*` | Modèle ASR (parties 16 Mo) |
| `assets/models/vad/silero_vad.onnx` | VAD |

Demande ces dossiers à un membre de l’équipe (zip / Drive), puis place-les aux chemins ci-dessus. Les métadonnées (`bundle.json`, `tokens.txt`, `ATTRIBUTION.txt`) et `assets/mushaf/README.txt` restent dans le repo.

Sans les WebP mushaf, la lecture ne peut pas s’afficher. Sans les modèles ONNX, le hifz ASR ne démarre pas.

## Démarrage

```bash
flutter pub get
flutter run
```

## Contenu versionné utile au dev

- `lib/`, tests, plateformes (`android/`, `ios/`, …)
- `assets/word_data/`, `assets/search/`, `assets/branding/`
- Métadonnées modèles + README mushaf
