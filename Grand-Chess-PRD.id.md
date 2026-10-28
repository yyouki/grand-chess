# Grand Chess — Rencana Produk

**Bahasa / Language:** [Bahasa Indonesia](Grand-Chess-PRD.id.md) | [English](Grand-Chess-PRD.md)

## 1. Tujuan

Grand Chess adalah aplikasi catur multiplatform yang dibangun dengan Flutter dan Dart. Rilis awal berfokus pada permainan lokal yang rapi untuk dua orang dalam satu perangkat.

## 2. Pengguna yang dituju

- Orang yang ingin bermain catur di ponsel atau komputer tanpa membuat akun.
- Pemain pemula yang membutuhkan petunjuk langkah dan status permainan yang jelas.
- Developer yang belajar Flutter dan ingin mempelajari struktur proyek yang mudah diikuti.

## 3. Lingkup saat ini

Aplikasi mencakup mesin aturan catur, pengendali permainan, UI responsif, riwayat langkah, dialog promosi dan hasil permainan, serta papan perspektif 3D. Geser area kosong papan untuk memutar kamera; material buah putih dan hitam dibuat konsisten.

Tes aturan mencakup validasi langkah legal, skak, skakmat, remis, rokade, en passant, promosi pion, aturan hasil remis, dan notasi langkah. Scene 3D menggunakan Flutter Canvas agar renderer yang sama dapat digunakan di platform Flutter yang didukung.

## 4. Cerita pengguna

- Sebagai pemain, saya bisa memulai permainan lokal baru dan mengisi nama pemain bila perlu.
- Saya bisa melihat giliran dan tujuan langkah legal.
- Saya bisa memindahkan buah dengan mengetuk kotak atau drag.
- Saya bisa memutar papan 3D sampai 360 derajat dan mengembalikan sudut awal.
- Saya bisa melihat riwayat, membalik orientasi papan, memilih promosi pion, dan melihat hasil pertandingan.
- Sebagai developer, saya bisa menjalankan tes aturan dan build platform melalui GitHub Actions.

## 5. Syarat rilis

Rilis publik harus memenuhi semua syarat berikut:

1. Format Dart, analisis statis, dan tes berhasil.
2. Build release berhasil untuk Android, Windows, Linux, macOS, kompilasi iOS, dan web.
3. Input papan, rotasi 3D, legalitas langkah, dialog, dan tata letak responsif diperiksa melalui tes otomatis.
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

### Versi 1.x — Kenyamanan bermain

- Menyimpan dan melanjutkan permainan lokal.
- Mengekspor dan mengimpor permainan PGN.
- Menambahkan bahan papan, set buah, preset kamera, dan highlight yang ramah buta warna.
- Menambahkan suara, pengaturan animasi, dan pemeriksaan aksesibilitas keyboard/mouse.
- Menambahkan UI aplikasi yang diterjemahkan dan pilihan bahasa.

### Rilis berikutnya

- Lawan komputer opsional setelah kekuatan dan performa mesin dievaluasi.
- Permainan online hanya setelah keamanan, akun, sinkronisasi, dan pencegahan kecurangan ditinjau.
- Sinkronisasi cloud hanya dengan pilihan privasi yang jelas serta penanganan konflik yang andal.

## 7. Prinsip

Utamakan kode sederhana, state yang jelas, label aksesibel, tes aturan catur, dan permainan lokal tanpa akun wajib. Hindari dependensi besar bila fitur bawaan Flutter sudah memadai.
