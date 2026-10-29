# Grand Chess

**Bahasa / Language:** [Bahasa Indonesia](README.id.md) | [English](README.md)

Grand Chess adalah aplikasi catur Flutter lintas platform dengan mesin aturan Dart, papan perspektif 3D, dan bot offline. Pada ponsel yang mendukungnya, meja catur dibuka dalam mode landscape layar penuh.

Menurut [daftar platform resmi Flutter](https://docs.flutter.dev/reference/supported-platforms), Flutter mendukung Android, iOS, Windows, macOS, Linux, dan web. Workflow GitHub di repositori ini membangun target-target tersebut agar dukungannya diperiksa oleh CI, bukan hanya diasumsikan dari label Flutter.

## Fitur saat ini

- Permainan lokal dua pemain pada satu perangkat atau melawan bot offline dengan gaya Easy dan Tactical. Bot memakai daftar langkah legal dari mesin yang sama; ini bot ringan, bukan Stockfish.
- Papan perspektif 3D dan buah catur bervolume yang dirender dengan Flutter Canvas.
- Ketuk sebuah buah untuk memilihnya, lalu ketuk kotak tujuan yang disorot. Drag buah tidak akan memindahkannya.
- Geser area kosong papan untuk memutar kamera hingga 360 derajat dan mengubah kemiringan. Gunakan tombol reset untuk kembali ke sudut awal.
- Koordinat A–H dan 1–8 yang datar dan tegak, animasi langkah, serta pilihan material papan dan buah.
- Riwayat langkah, membalik papan, undo/redo, promosi pion, skak/skakmat/remis, rokade, en passant, serta salin/ekspor teks FEN dan PGN.
- Jam catur opsional: Unlimited, Bullet 1+0, Blitz 3+2 atau 5+3, dan Rapid 10+0 atau 15+10. Bonus waktu ditambahkan setelah langkah; pemain yang waktunya habis kalah pada jam.
- Catur memakai mode landscape imersif di perangkat seluler yang mendukungnya. Di desktop, layar permainan memakai tata letak lebar tetapi tidak memaksa ukuran jendela OS menjadi fullscreen.
- 3D Arcade terpisah dengan Cube Tic-Tac-Toe dan Tower Builder yang bisa dimainkan.
- Pemeriksaan format kode, analisis statis, tes, dan build platform melalui GitHub Actions.

## Status platform

Tujuannya adalah memakai satu basis kode Dart. Hasil workflow yang berhasil adalah bukti utama bahwa target tersebut saat ini bisa dibangun.

| Target | Perintah build | Catatan penting |
| --- | --- | --- |
| Android | `flutter build apk --release` | APK bisa dipasang pada perangkat Android yang kompatibel. |
| Windows | `flutter build windows --release` | Build perlu dijalankan di Windows dengan Visual Studio C++ tools. |
| Linux | `flutter build linux --release` | Memerlukan Clang, CMake, Ninja, GTK development files, dan pkg-config. |
| macOS | `flutter build macos --release` | Build harus dijalankan di macOS dengan Xcode. |
| iOS | `flutter build ios --release --no-codesign` | CI memeriksa kompilasi; distribusi perlu tanda tangan Apple. |
| Web | `flutter build web --release` | Berjalan di browser modern yang didukung. |

Flutter menyediakan keluarga target tersebut, tetapi build CI yang sukses tidak menggantikan pengujian di perangkat asli. Lihat [daftar platform resmi Flutter](https://docs.flutter.dev/reference/supported-platforms).

## Mencoba aplikasi

### Mengunduh build uji

1. Buka [halaman Actions repositori](https://github.com/yyouki/grand-chess/actions).
2. Pilih run yang berhasil pada commit yang ingin diuji.
3. Buka bagian **Artifacts** dan unduh artefak Android release.
4. Ekstrak ZIP yang diunduh. Pasang file bernama `app-release.apk`, bukan ZIP artefak luarnya.

Artefak adalah hasil CI sementara. Tag versi yang diawali `v` akan memicu workflow rilis setelah seluruh tes dan build wajib berhasil.

### Build dari source code

Pasang Flutter stable SDK terlebih dahulu. Persyaratan khusus platform tersedia di [panduan setup Flutter](https://docs.flutter.dev/platform-integration).

Folder runner native yang dihasilkan Flutter tidak disimpan di repo. Buat folder itu sekali dari root proyek:

~~~sh
flutter create . --project-name grand_chess --platforms=android,ios,web,windows,linux,macos
flutter pub get
~~~

Perintah build dasar:

~~~sh
flutter run
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter build apk --release
flutter build web --release
~~~

Build desktop Windows harus dijalankan di Windows. Build macOS dan iOS harus dijalankan di macOS. Build desktop Linux memerlukan paket yang dicantumkan dalam [panduan Linux Flutter](https://docs.flutter.dev/platform-integration/linux/setup).

## Struktur proyek

~~~text
lib/
  app/             Entry point dan setup aplikasi
  chess_engine/    Aturan catur dan validasi langkah
  game/            Status permainan dan aksi pemain
  ui/
    screens/       Layar beranda, setup, dan permainan
    theme/         Warna papan dan aplikasi
    widgets/       Kontrol yang dapat dipakai ulang dan renderer papan 3D
test/
  chess_engine/    Tes aturan catur
  game/            Tes pengendali permainan
  integration/     Tes alur permainan lengkap
  ui/               Tes papan, layar, dan tata letak
.github/
  workflows/       Otomatisasi CI, rilis, dan pemeliharaan branch
~~~

Pisahkan aturan catur dari widget UI. Letakkan logika tampilan yang dapat dipakai ulang di `ui/widgets`, alur layar di `ui/screens`, dan tambahkan tes setiap kali perilaku berubah.

## Batasan sebelum rilis publik 1.0

Bot bawaan adalah lawan offline sederhana, bukan mesin setara Stockfish. Matchmaking online, akun cloud, simpan/lanjut permainan secara permanen, efek suara, pipeline model 3D/PBR lengkap, serta paket App Store yang sudah ditandatangani belum tersedia. Penandatanganan iOS dan pengiriman ke toko aplikasi membutuhkan kredensial milik pengelola proyek.

Pemilik masih perlu menentukan lisensi source code sebelum mengumumkan rilis publik. Build CI sudah berhasil, tetapi pemeriksaan visual pada perangkat Android/iOS serta komputer desktop tetap diperlukan.

## Dokumen proyek

- Rencana produk: [Bahasa Indonesia](docs/PRODUCT_PLAN.id.md) | [English](docs/PRODUCT_PLAN.md)
- Keputusan teknis: [Bahasa Indonesia](docs/ARCHITECTURE.id.md) | [English](docs/ARCHITECTURE.md)
- Panduan kontribusi: [Bahasa Indonesia](CONTRIBUTING.id.md) | [English](CONTRIBUTING.md)
- Catatan perubahan: [Bahasa Indonesia](docs/CHANGELOG.id.md) | [English](docs/CHANGELOG.md)
- Kebijakan keamanan: [Bahasa Indonesia](.github/SECURITY.id.md) | [English](.github/SECURITY.md)

## Kontribusi

Baca panduan kontribusi sebelum mengubah kode. Jaga perubahan tetap fokus, jalankan formatter, analisis, dan tes, lalu buat pull request dengan penjelasan singkat serta hasil pengujiannya.
