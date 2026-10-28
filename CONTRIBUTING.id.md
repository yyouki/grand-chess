# Berkontribusi ke Grand Chess

**Bahasa / Language:** [Bahasa Indonesia](CONTRIBUTING.id.md) | [English](CONTRIBUTING.md)

Terima kasih sudah membantu mengembangkan Grand Chess. Langkah-langkah ini dibuat agar mudah diikuti developer yang baru belajar Flutter.

## Sebelum mengedit

1. Baca [README](README.id.md) dan [keputusan teknis](Grand-Chess-ADR.id.md).
2. Pasang Flutter stable SDK dan alat yang dibutuhkan platform target.
3. Buat folder runner native yang belum tersedia dari root proyek bila diperlukan:

~~~sh
flutter create . --project-name grand_chess --platforms=android,ios,web,windows,linux,macos
flutter pub get
~~~

## Panduan kode

- Jangan menaruh aturan catur di dalam widget UI.
- Gunakan nama yang menjelaskan maksud dan fungsi kecil dengan satu tanggung jawab.
- Tambahkan tes saat memperbaiki bug atau mengubah perilaku.
- Batasi dependensi baru dan jelaskan alasannya.
- Gunakan formatter Dart agar format konsisten.
- Jangan commit kunci penandatanganan, kata sandi, token API, atau data pribadi.

## Memeriksa perubahan

Jalankan perintah berikut sebelum membuat pull request:

~~~sh
dart format .
flutter analyze
flutter test
~~~

Build target yang diubah bila sistem operasi yang dibutuhkan tersedia. GitHub Actions juga menjalankan pemeriksaan otomatis dan build rilis.

## Pull request

Jelaskan masalah, ringkas perubahan, dan daftar tes yang dijalankan. Sertakan screenshot atau rekaman layar singkat ketika perubahan visual perlu ditinjau. Fokuskan satu pull request pada satu topik dan tanggapi masukan review sebelum merge.
