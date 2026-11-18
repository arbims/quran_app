# quran_app

Mushaf Qaloon — lecture, recherche, audio et hifz (Flutter).

## Prérequis

- Flutter SDK (compatible `sdk: ^3.13.7` dans `pubspec.yaml`)
- `curl`, `unzip`, `sha256sum`
- Assets runtime (~367 Mo compressés) — hors de `main`

## Assets runtime

Les pages mushaf (`.webp`) et les modèles ONNX ne sont pas sur `main`.  
Ils sont sur la branche [`runtime-assets`](https://github.com/arbims/quran_app/tree/runtime-assets).

Depuis la racine du repo :

```bash
./scripts/fetch_runtime_assets.sh
```

Cette commande télécharge l’archive, vérifie le SHA256, puis extrait `assets/mushaf/` et `assets/models/`.

Sans ces fichiers, la lecture mushaf et le hifz ASR ne fonctionnent pas.  
Les métadonnées (`bundle.json`, `tokens.txt`, `ATTRIBUTION.txt`) restent versionnées sur `main`.

## Démarrage

```bash
./scripts/fetch_runtime_assets.sh
flutter pub get
flutter run
```

## Contenu versionné sur `main`

- `lib/`, tests, plateformes (`android/`, `ios/`, …)
- `assets/word_data/`, `assets/search/`, `assets/branding/`
- Métadonnées modèles + README mushaf
