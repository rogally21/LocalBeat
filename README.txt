LocalBeat - progetto Flutter (Windows + Android)

REQUISITI (una volta sola)
- Flutter SDK >= 3.27 nel PATH  (flutter doctor deve essere verde)
- Android: Android Studio/SDK + JDK 17 + licenze:  flutter doctor --android-licenses
- Windows: Visual Studio 2022 con "Sviluppo di applicazioni desktop con C++" + Modalita sviluppatore attiva

USO (Windows)
1) doppio clic su setup.bat   -> crea build_app, applica patch Android, scarica pacchetti, genera icone
2) doppio clic su build.bat   -> compila APK + EXE   (solo uno: build.bat android | build.bat windows)
Output in dist\ : APK (arm64-v8a, armeabi-v7a, x86_64) e cartella LocalBeat-Windows\ (LocalBeat.exe: distribuisci TUTTA la cartella)

USO (Linux/macOS, solo APK)
  ./setup.sh && ./build.sh

NOTE
- Loader e page-switch sono approssimazioni degli esempi uiverse (non scaricabili): vedi lib/ui/widgets/loader.dart e page_switcher.dart
- Lyrics: LRCLIB; metadati: MusicBrainz + Cover Art Archive (nessuna chiave API)

BUILD SU GITHUB (senza installare nulla)
1) Crea un repository su github.com e carica TUTTO il contenuto della cartella (incluso .github/workflows/build.yml)
2) Tab "Actions" -> "Build LocalBeat" -> "Run workflow" (parte anche da solo a ogni caricamento)
3) A fine build (~10-15 min) apri l'esecuzione -> sezione "Artifacts" -> scarica LocalBeat-Android-APK e LocalBeat-Windows
Se la cartella .github non si carica dal sito: "Add file" -> "Create new file", nome  .github/workflows/build.yml  e incolla il contenuto di build.yml.txt
