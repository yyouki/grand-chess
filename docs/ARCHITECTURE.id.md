# Grand Chess — Keputusan Teknis

**Bahasa / Language:** [Bahasa Indonesia](ARCHITECTURE.id.md) | [English](ARCHITECTURE.md)

ADR (Architecture Decision Record) menjelaskan alasan proyek memilih pendekatan teknis tertentu. Dokumen ini memakai bahasa sederhana agar developer baru memahami keputusan dan konsekuensinya.

## ADR-001: Flutter dan Dart

**Keputusan:** Gunakan Flutter dan Dart untuk aplikasi serta mesin catur.

**Alasan:** Satu basis kode dapat menargetkan perangkat mobile, desktop, dan web. Aturan catur juga dapat dites tanpa merender layar.

**Konsekuensi:** Folder platform native dan penandatanganan paket tetap membutuhkan alat khusus platform. Dukungan Flutter tidak berarti seluruh target otomatis dibangun atau ditandatangani.

## ADR-002: Mesin catur tidak bergantung pada UI

**Keputusan:** Aturan catur, posisi papan, dan validasi langkah legal disimpan di folder mesin/domain, bukan di widget layar.

**Alasan:** Aturan lebih cepat dites, bisa digunakan kembali, dan dapat diperiksa tanpa bergantung pada tata letak.

**Konsekuensi:** Aksi UI harus melalui pengendali permainan, bukan mengubah posisi secara langsung.

## ADR-003: Render papan 3D menggunakan Flutter Canvas

**Keputusan:** Buat renderer perspektif sendiri dengan geometri 3D yang diproyeksikan dan digambar melalui Canvas.

**Alasan:** Papan dan buah catur membutuhkan tinggi, kedalaman, shading material, dan kamera yang dapat diputar 360 derajat. Renderer khusus menghindari ketergantungan wajib pada mesin 3D native dan bisa digunakan pada target mobile, desktop, serta web Flutter.

**Konsekuensi:** Ini adalah scene yang dirender dengan kode sendiri, bukan mesin 3D fisik lengkap. Bayangan canggih, pantulan realistis, model 3D impor, dan performa di perangkat lama harus dievaluasi terpisah.

## ADR-004: Satu pengendali permainan

**Keputusan:** Pengendali permainan memegang posisi saat ini, pilihan buah, tujuan langkah legal, riwayat, dan hasil permainan.

**Alasan:** Papan, status, dialog, dan riwayat harus menampilkan state yang sama. Tes juga dapat memeriksa pengendali tanpa harus berinteraksi dengan seluruh aplikasi.

**Konsekuensi:** Pengendali perlu memberi tahu UI saat state berubah dan dibersihkan ketika layar ditutup.

## ADR-005: Build dan tes melalui GitHub Actions

**Keputusan:** Gunakan GitHub Actions untuk format, analisis, tes, dan build semua target yang didukung.

**Alasan:** Pengelola dapat memeriksa perubahan tanpa harus memiliki setiap sistem operasi.

**Konsekuensi:** Kompilasi CI tidak menggantikan tes perangkat nyata, kunci penandatanganan, peninjauan toko, atau pengiriman ke app store.

## ADR-006: Permainan lokal tidak memerlukan akun atau layanan online

**Keputusan:** Rilis pertama tetap lokal tanpa akun atau backend wajib.

**Alasan:** Setup sederhana dan tidak mengumpulkan data pribadi sebelum dibutuhkan.

**Konsekuensi:** Sinkronisasi cloud, matchmaking, dan fitur akun memerlukan rancangan privasi serta keamanan tersendiri.
