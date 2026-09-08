# Grand Chess

Aplikasi catur multiplatform open-source untuk Android, Windows, macOS, dan Linux. Dibangun dengan Flutter.

Dokumen produk & arsitektur: `Grand-Chess-PRD.md` dan `Grand-Chess-ADR.md`.

Status saat ini: **Phase 1 — Project Foundation.** Belum ada fitur catur; ini kerangka proyek yang bisa dibuild dan dijalankan.

## Toolchain

- **Flutter 3.44.x** (channel stable)
- **Dart 3.12.x** — dibundel otomatis bersama Flutter, tidak perlu instalasi terpisah

Versi patch (`.x`) sengaja tidak dikunci ke angka tertentu — pakai rilis stable terbaru di jalur minor tersebut. Sebelum mulai, verifikasi versi yang benar-benar terinstal di komputer kamu (bukan asumsi dari dokumen ini):

```
flutter --version
dart --version
```

Prasyarat tambahan per platform:
- Build Android: Android Studio + Android SDK
- Build Windows: Windows 10/11 dengan Visual Studio 2022 (workload "Desktop development with C++")

## Setup awal (sekali saja)

Paket ini **belum menyertakan folder `android/` dan `windows/`.** Folder itu dihasilkan oleh `flutter create` dan isinya sangat spesifik terhadap versi SDK yang kamu pakai — supaya tidak ketinggalan zaman atau salah, generate langsung dari Flutter SDK kamu sendiri:

1. Clone/salin folder proyek ini ke lokasi kerja kamu.
2. Di lokasi TERPISAH (bukan di dalam folder proyek ini), jalankan:
   ```
   flutter create --platforms=android,windows --project-name grand_chess --org com.example.grandchess /tmp/gc_platform_gen
   ```
   (Ganti `com.example.grandchess` dengan domain/org kamu sendiri kalau ada.)
3. Salin folder `android/` dan `windows/` hasil generate itu ke root proyek Grand Chess ini. **Jangan salin `lib/`, `test/`, atau `pubspec.yaml`-nya** — punya proyek ini yang dipakai.
4. Dari root proyek Grand Chess:
   ```
   flutter pub get
   flutter run
   ```

## Perintah yang berguna

```
flutter analyze                              # cek lint & error statis
dart format .                                # format semua kode
dart format --output=none --set-exit-if-changed .   # cek format tanpa mengubah file (dipakai CI)
flutter test                                 # jalankan semua test
```

## Struktur folder

```
lib/
├── core/          → utilitas umum (belum ada isi di Phase 1)
├── chess_engine/  → logika catur murni, tanpa dependensi UI (Phase 2)
├── game/          → domain model Game State (Phase 2)
├── ai/            → integrasi Stockfish via ChessAI interface (Phase 4, lihat ADR-002)
├── ui/            → widget, layar, tema (Phase 3+)
├── audio/         → audio manager (Version 1.0)
├── database/      → integrasi Drift (Version 1.0, lihat ADR-003)
├── network/       → fitur online (Fase 6, paling akhir)
└── settings/      → preferensi pengguna (Version 1.0)
```

Folder-folder di atas sengaja masih kosong (hanya berisi `.gitkeep`) — ini kerangka akhir yang akan diisi bertahap per fase, bukan folder yang terlewat.

## Yang sudah ada di Phase 1

- Project shell yang bisa dibuild & dijalankan (`lib/main.dart`)
- Konfigurasi lint (`analysis_options.yaml`, pakai `flutter_lints`)
- Infrastruktur testing (`test/app_test.dart`, satu test yang memverifikasi app shell)
- CI (`.github/workflows/ci.yml`): format check, analyze, test — plus build verification Android & Windows yang otomatis aktif begitu folder `android/`/`windows/` ada di repo (lihat catatan di bawah)
- Struktur folder final untuk seluruh proyek

**Catatan soal CI build verification:** job `build-android` dan `build-windows` mengecek dulu apakah folder platform terkait sudah ada. Kalau belum (kondisi saat ini), job itu menuliskan warning dan berhenti — bukan gagal, tapi juga bukan benar-benar menguji apa pun. Begitu kamu generate & commit `android/`/`windows/` (lihat bagian Setup di atas), build sungguhan otomatis mulai berjalan di push/PR berikutnya tanpa perlu mengubah file CI lagi.

## Yang belum ada (menyusul di fase berikutnya)

Chess engine, integrasi Stockfish, papan catur, database, audio, sistem tema, dan fitur online — lihat `Grand-Chess-PRD.md` untuk pembagian fase lengkap.
