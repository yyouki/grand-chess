# Grand Chess — Rencana Produk

**Bahasa / Language:** [Bahasa Indonesia](PRODUCT_PLAN.id.md) | [English](PRODUCT_PLAN.md)

## 1. Tujuan

Grand Chess adalah aplikasi catur multiplatform yang dibangun dengan Flutter dan Dart. Rilis awal berfokus pada permainan lokal yang rapi untuk dua orang dalam satu perangkat.

## 2. Pengguna yang dituju

- Orang yang ingin bermain catur di ponsel atau komputer tanpa membuat akun.
- Pemain pemula yang membutuhkan petunjuk langkah dan status permainan yang jelas.
- Developer yang belajar Flutter dan ingin mempelajari struktur proyek yang mudah diikuti.

## 3. Lingkup saat ini

Aplikasi saat ini mencakup mesin aturan catur, layar landscape imersif di perangkat seluler yang mendukungnya, kontrol ketuk-buah-lalu-tujuan, bot offline sederhana, undo/redo, teks ekspor FEN/PGN, pilihan material visual, animasi langkah, dan papan perspektif 3D. Geser area kosong papan hanya menggerakkan kamera, tidak menjalankan langkah catur.

3D Arcade terpisah saat ini memiliki Cube Tic-Tac-Toe dan Tower Builder yang dapat dimainkan. Tes catur mencakup legalitas langkah, skak, skakmat, remis, rokade, en passant, promosi, aturan remis, dan notasi. Renderer memakai Flutter Canvas di target Flutter yang didukung.

## 4. Cerita pengguna

- Sebagai pemain, saya bisa memulai permainan lokal baru dan mengisi nama pemain bila perlu.
- Saya bisa melihat giliran dan tujuan langkah legal.
- Saya memilih buah dengan mengetuknya, lalu mengetuk tujuan legal; drag papan mengendalikan kamera.
- Saya bisa memutar/memiringkan papan 3D, mereset sudut pandang, dan memilih material papan/buah.
- Saya bisa undo/redo langkah dan menyalin posisi sebagai FEN atau riwayat sebagai teks PGN.
- Saya bisa memilih kontrol waktu standar, melihat kedua jam, dan kalah berdasarkan waktu ketika jam aktif mencapai nol.
- Saya bisa bermain lokal melawan bot offline sederhana atau membuka 3D Arcade.
- Saya bisa melihat riwayat, membalik orientasi papan, memilih promosi pion, dan melihat hasil pertandingan.
- Sebagai developer, saya bisa menjalankan tes aturan dan build platform melalui GitHub Actions.

## 5. Syarat rilis

Rilis publik harus memenuhi semua syarat berikut:

1. Format Dart, analisis statis, dan tes berhasil.
2. Build release berhasil untuk Android, Windows, Linux, macOS, kompilasi iOS, dan web.
3. Input papan, rotasi 3D, legalitas langkah, dialog, increment jam, kehabisan waktu, dan tata letak responsif diperiksa melalui tes otomatis.
4. Pengelola menguji tampilan dan input sentuh/mouse pada perangkat nyata.
5. Pemilik proyek memilih lisensi source code dan memperbarui deskripsi repositori GitHub.
6. Paket untuk toko aplikasi ditandatangani oleh pemilik; kompilasi iOS tanpa tanda tangan bukan berarti aplikasi siap diunggah ke App Store.

## 6. Peta jalan

### Versi 0.x — Permainan lokal

- [x] Membuat mesin catur Dart dan status permainan.
- [x] Membuat alur dua pemain lokal dan riwayat langkah.
- [x] Menambahkan tes mesin dan UI.
- [ ] Memeriksa renderer 3D melalui CI dan pengujian langsung pada perangkat.
- [ ] Menyelesaikan metadata rilis, lisensi, dan aksesibilitas.
- [x] Menambahkan preset jam dan penanganan kalah waktu.

### Versi 1.x — Kenyamanan bermain

- Menyimpan dan melanjutkan permainan lokal.
- Mengekspor dan mengimpor permainan PGN.
- [x] Menambahkan pilihan tampilan/material papan dan buah catur.
- Menambahkan preset kamera dan highlight yang ramah buta warna.
- Menambahkan suara, pengaturan animasi, dan pemeriksaan aksesibilitas keyboard/mouse.
- Menambahkan UI aplikasi yang diterjemahkan dan pilihan bahasa.

### Rilis berikutnya

- Tingkatkan bot bawaan atau integrasikan Stockfish setelah evaluasi performa serta packaging lintas platform.
- Tambahkan simpan/lanjut permainan, pengaturan animasi, serta pipeline model/material 3D yang lebih lengkap.
- Permainan online hanya setelah keamanan, akun, sinkronisasi, dan pencegahan kecurangan ditinjau.
- Sinkronisasi cloud hanya dengan pilihan privasi yang jelas serta penanganan konflik yang andal.

## 7. Prinsip

Utamakan kode sederhana, state yang jelas, label aksesibel, tes aturan catur, dan permainan lokal tanpa akun wajib. Hindari dependensi besar bila fitur bawaan Flutter sudah memadai.
