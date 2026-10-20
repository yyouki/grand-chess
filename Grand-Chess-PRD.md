# Product Requirements Document — Grand Chess

**Revisi:** 3 (finalisasi teknis, 18 Agustus 2026)
**Draft pertama:** 9 Agustus 2026
**Status:** Final — siap lanjut ke Fase 1
**Dokumen terkait:** Grand-Chess-ADR.md (Architecture Decision Record — ADR-001 sampai ADR-006)

---

## 1. Visi Produk

Grand Chess adalah aplikasi catur multiplatform open-source yang menghadirkan pengalaman bermain, berlatih, dan menyimpan riwayat permainan catur dengan kualitas visual, kehalusan animasi, dan kenyamanan pemakaian setara aplikasi catur komersial papan atas (Chess.com, Lichess) — dijalankan secara native (bukan pembungkus web) di Android, Windows, macOS, dan Linux dari satu basis kode.

Tiga hal yang membedakan Grand Chess:

- **Native & konsisten di 4 platform**, termasuk Linux — platform yang jarang mendapat aplikasi catur desktop modern berkualitas tinggi.
- **Open-source sepenuhnya** — kode dan arsitekturnya bisa dipelajari dan dikembangkan siapa saja.
- **Dibangun bertahap di atas fondasi arsitektur yang kokoh**, dirilis sebagai Alpha yang fokus lalu disempurnakan ke Version 1.0 — bukan demo cepat yang sulit dikembangkan lebih lanjut.

## 2. Target Pengguna

| Segmen | Kebutuhan utama | Relevan mulai |
|---|---|---|
| Pemain kasual–menengah lintas perangkat | Aplikasi yang sama enaknya dipakai di HP maupun laptop | MVP Alpha |
| Pemain pass-and-play lokal | Dua orang main di satu perangkat yang sama, tanpa papan fisik | MVP Alpha |
| Pengguna Linux/desktop | Selama ini opsinya terbatas ke aplikasi lawas atau browser | Version 1.0 (setelah Linux tersedia) |

Yang **belum** jadi fokus sampai jauh ke depan: pemain kompetitif yang butuh rating online dan lawan manusia acak — ini baru relevan setelah Fase 6 (online, di luar cakupan dokumen ini).

## 3. MVP Alpha

**Tujuan:** validasi inti pengalaman bermain catur — cepat, benar, dan terasa premium — sebelum menambah lapisan lain. Ini adalah rilis paling minim yang tetap terasa seperti produk, bukan potongan demo.

- **Project foundation** — struktur folder, arsitektur dasar, konfigurasi CI
- **Chess engine** — aturan catur lengkap & benar: legal move, check/checkmate/stalemate, castling, en passant, promotion, threefold repetition, fifty-move rule; representasi FEN/PGN internal
- **Playable board** — papan interaktif (drag-and-drop + tap-to-move), indikator langkah legal, highlight langkah terakhir, animasi capture/check; mode vs Manusia (lokal, 1 perangkat) dan vs AI
- **Stockfish integration** — AI lawan dengan beberapa level kesulitan, waktu berpikir natural
- **Kontrol dasar** — resign, supaya game bisa diakhiri secara sukarela tanpa harus menunggu checkmate

**Sengaja tidak termasuk di Alpha** (asumsi saya, tolong koreksi kalau meleset): tema, suara, statistik, riwayat/replay, pengaturan, dan database — setiap game di Alpha dimulai fresh, tidak tersimpan. Undo/redo dan draw offer juga saya golongkan ke Version 1.0, karena bukan kebutuhan inti untuk "papan bisa dimainkan."

**Platform:** Android dan Windows saja (lihat ADR-004).

**Catatan lisensi:** karena Stockfish (GPLv3) sudah aktif sejak Alpha, disclosure lisensi minimal (bukan halaman "Tentang" penuh) tetap perlu ada sejak rilis Alpha — lihat ADR-002.

## 4. Version 1.0

**Tujuan:** melengkapi pengalaman jadi produk utuh sesuai visi awal, setelah inti permainan di Alpha terbukti solid.

- **Data layer** — database lokal (Drift), simpan & lanjutkan game
- **Themes** — tema papan & bidak (minimal 2–3), dark/light mode
- **Audio** — suara langkah, capture, check, kemenangan
- **Statistics** — menang/kalah/seri, jumlah game dimainkan
- **Replay** — riwayat game tersimpan, navigasi maju-mundur per langkah
- **Settings** — halaman pengaturan terpusat (tema, suara, bahasa)
- **Kontrol tambahan** — undo/redo request, draw offer, timer opsional
- **PGN import/export** *(baru)* — ekspor game ke file .pgn, impor .pgn untuk dilihat atau dianalisis
- **Analysis Board mode** *(baru)* — papan bebas gerak dengan evaluasi Stockfish real-time, untuk eksplorasi posisi atau analisis pasca-game

**Platform:** menambahkan Linux dan macOS, setelah Android + Windows stabil (lihat ADR-004).

## 5. Fitur yang Masih Ditunda (Post-1.0)

- Akun pengguna, rating, multiplayer online, matchmaking, friends, leaderboard — Fase 6, butuh backend/server
- Best-move suggestion otomatis & mistake detection (laporan visual game review lengkap ala Chess.com)
- Puzzle trainer, opening trainer, lessons/kurikulum belajar terstruktur
- Sharing PGN ke komunitas — beda dari import/export file biasa (yang sudah masuk v1.0), ini butuh infrastruktur sosial/online
- Tema papan/bidak tambahan yang bisa diunduh
- Sinkronisasi cloud antar perangkat

## 6. User Flow

**Flow A — Main baru vs AI**
Home → tap "Main Baru" → Game Setup (pilih "Lawan Komputer" → level kesulitan → warna → timer opsional*) → tap "Mulai" → Game Screen → main sampai selesai → Hasil Game → pilih: Main Lagi / Lihat Replay* / Simpan* & Kembali ke Home
*(timer, replay, simpan game baru aktif di v1.0 — di Alpha, hasil game hanya bisa "Main Lagi" atau kembali ke Home)*

**Flow B — Main lokal 2 pemain**
Sama seperti Flow A, tapi di Game Setup pilih "Lawan Teman" (tanpa memilih level AI)

**Flow C — Lanjutkan game tersimpan** *(v1.0)*
Home → "Lanjutkan Game" (jika ada game belum selesai), atau Home → Riwayat → pilih game → Lanjutkan / Lihat Replay

**Flow D — Ubah pengaturan** *(v1.0)*
Home/nav → Pengaturan → ubah tema/suara/dsb → otomatis tersimpan, kembali ke layar sebelumnya

**Flow E — Analysis Board** *(v1.0, baru)*
Home/nav → Analysis Board → mulai dari posisi awal atau impor file PGN → gerak bebas sambil melihat evaluasi Stockfish real-time

**Flow F — Import/Export PGN** *(v1.0, baru)*
Dari Riwayat Game atau Analysis Board → "Ekspor PGN" (simpan file) / "Impor PGN" (buka file)

## 7. Halaman Aplikasi

| Halaman | Tujuan & isi utama | Tersedia mulai |
|---|---|---|
| Splash | Logo aplikasi saat startup | Alpha |
| Home | Menu utama, mulai game baru | Alpha |
| Game Setup | Pilih mode, level kesulitan, warna | Alpha |
| Game (Papan) | Layar utama bermain, tombol resign | Alpha |
| Hasil Game | Ringkasan hasil, opsi main lagi | Alpha |
| Riwayat Game | Daftar game tersimpan | v1.0 |
| Replay | Navigasi maju-mundur per langkah | v1.0 |
| Analysis Board | Papan bebas gerak + evaluasi Stockfish, impor/ekspor PGN | v1.0 |
| Statistik | Ringkasan menang/kalah/seri | v1.0 |
| Pengaturan | Tema, suara, bahasa | v1.0 |
| Tentang | Versi, lisensi lengkap, atribusi Stockfish | v1.0 (disclosure minimal sudah ada sejak Alpha) |

## 8. Struktur Navigasi

```
Root Navigation (adaptif: bottom nav di mobile, nav rail di desktop)
├── Home (tab default) — Alpha
│   └── New Game → Game Setup → Game Screen (full-screen) — Alpha
├── Analysis Board — v1.0
├── Riwayat — v1.0
│   └── Detail Game → Replay Screen — v1.0
├── Statistik — v1.0
└── Pengaturan — v1.0
    └── Tentang Aplikasi — v1.0
```

Struktur di atas adalah desain akhir untuk v1.0, dibuat sejak awal supaya tidak perlu dirombak ulang saat fitur baru ditambahkan. Di Alpha, secara praktis nav hanya berisi Home karena destinasi lain belum ada isinya. Game Screen sengaja full-screen tanpa nav chrome, dengan tombol keluar eksplisit — supaya pengguna tidak sengaja keluar dari game yang sedang berjalan.

## 9. Design System

Prinsip dan arahan tingkat tinggi (bukan spesifikasi visual detail — itu masuk ke Fase 3):

- **Bahasa desain dasar**: Material Design 3 (didukung native oleh Flutter), dengan identitas visual custom supaya tidak terlihat seperti aplikasi Material generik
- **Prioritas interaksi Alpha**: karena Alpha menyasar Android (touch) dan Windows (mouse + keyboard) sekaligus, papan perlu mendukung dua pola input ini setara sejak awal — tap-to-move untuk touch, click + drag untuk mouse, navigasi keyboard dasar untuk aksesibilitas desktop
- **Mode warna**: dark mode sebagai default, light mode tersedia penuh (v1.0; di Alpha cukup satu tampilan default)
- **Tema papan & bidak**: minimal 2–3 skema warna papan dan 2–3 gaya bidak (v1.0)
- **Tipografi**: sans-serif geometris yang bersih, hierarki jelas antara judul, isi, dan notasi catur
- **Motion**: transisi antar halaman ~200–300ms, animasi gerak bidak ~150–250ms, semua menyasar 60fps
- **Breakpoint responsif**: mobile (<600dp, nav bawah), desktop (>1024dp, nav rail); breakpoint tablet menyusul saat Linux/macOS masuk di v1.0
- **Ikonografi**: satu set ikon outline yang konsisten di seluruh aplikasi

## 10. Technical Constraints

Keputusan arsitektur utama didokumentasikan lengkap di **Grand-Chess-ADR.md**. Ringkasan:

- **Framework & bahasa**: Flutter (Dart) — ADR-001
- **Chess engine**: mesin aturan custom (Dart murni, tanpa dependensi UI) + Stockfish di balik lapisan abstraksi (`ChessAiEngine` interface → `StockfishAdapter` → implementasi per-platform) — ADR-002 (strategi hybrid) & ADR-005 (lapisan abstraksi)
- **Domain model & persistensi**: `GameState` sebagai domain model in-memory murni sejak Alpha, tanpa pengetahuan soal Drift — ADR-006. Drift baru masuk di Version 1.0 sebagai lapisan penyimpanan terpisah, tanpa mengubah domain logic — ADR-003
- **Urutan rilis platform**: Android + Windows (Alpha) → tambah Linux + macOS (v1.0) — ADR-004
- **Target minimum platform** *(draft, akan dipastikan saat konfigurasi Android/Windows di Fase 1)*: Android 7.0 (API 24)+, Windows 10+; macOS dan distribusi Linux menyusul di Version 1.0
- **Ketersediaan offline**: seluruh aplikasi, Alpha maupun v1.0, berfungsi 100% tanpa koneksi internet
- **Lisensi**: proyek open-source; kompatibilitas dengan Stockfish (GPLv3) sudah dipertimbangkan di ADR-002
- **Performa target**: 60fps animasi, startup cepat, RAM & baterai efisien — klaim performa Flutter di ADR-001 bersifat kualitatif, belum diukur langsung
- **Testing**: 7 kategori test untuk chess_engine (unit, FEN, special-move, draw/repetition, PGN round-trip, perft, regression) — detail tiap kategori ada di catatan metodologi bawah Milestone A2. Lolos semuanya meningkatkan keyakinan kebenaran engine secara signifikan, **bukan klaim "100% correctness"**

## 11. Development Milestones

### MVP Alpha (Android + Windows)

| Milestone | Fokus | Kriteria selesai |
|---|---|---|
| A1 — Fondasi | Struktur folder, setup CI, kerangka aplikasi kosong | Build & jalan tanpa error di Android + Windows |
| A2 — Chess engine | Semua aturan catur, FEN/PGN | Seluruh 7 kategori test (lihat catatan di bawah) lolos — meningkatkan keyakinan kebenaran engine, bukan klaim 100% correctness |
| A3 — Papan interaktif | UI papan, drag-and-drop, vs Manusia lokal | Dua pemain bisa main 1 game penuh di satu perangkat |
| A4 — Integrasi Stockfish | AI lawan (lewat `ChessAiEngine`/`StockfishAdapter`, ADR-005), level kesulitan, resign | Bisa main lawan AI dari level termudah–tersulit dengan hasil terasa natural |

**Alpha rilis** ketika A1–A4 selesai dan lolos playtest manual penuh di Android & Windows.

**Catatan metodologi testing — Milestone A2, 7 kategori:**

1. *Unit test aturan* — tiap jenis bidak & aturan dasar diuji terpisah
2. *FEN position test* — load posisi spesifik dari FEN, verifikasi board state & legal move yang dihasilkan benar
3. *Special-move test* — castling (termasuk kasus tidak sah, misal lewat kotak yang diserang), en passant, promotion ke semua jenis bidak
4. *Draw/repetition test* — threefold repetition, fifty-move rule, stalemate, insufficient material
5. *PGN round-trip test* — parse PGN → hasilkan ulang PGN dari state hasil parse → harus konsisten dengan aslinya
6. *Perft test* — teknik standar di chess programming: hitung total posisi yang bisa dicapai dari posisi awal setelah N langkah (pure move generation, tanpa evaluasi), dibandingkan dengan reference value yang sudah diketahui benar untuk posisi-posisi standar. Validasi paling ketat untuk move generator — satu bug kecil (misal salah update hak castling) akan membuat angka perft meleset di suatu kedalaman
7. *Regression test* — tiap bug yang ditemukan & diperbaiki, ditambahkan test spesifik supaya tidak terulang diam-diam

Lolos ketujuhnya adalah bukti keyakinan tinggi, **bukan bukti formal "100% benar"** — testing menunjukkan tidak ditemukan bug pada skenario yang diuji, bukan pembuktian matematis tanpa celah.

### Version 1.0 (+ Linux, macOS)

| Milestone | Fokus | Kriteria selesai |
|---|---|---|
| B1 — Data layer | Implementasi Drift di belakang repository, simpan/lanjutkan game | Game bisa ditutup & dilanjutkan tanpa kehilangan state |
| B2 — Statistik & Replay | Riwayat game, replay per langkah, statistik menang/kalah/seri | Statistik akurat setelah 10+ game percobaan |
| B3 — Tema & Audio | Tema papan/bidak, dark/light, audio manager | Semua suara & tema teruji tidak mengganggu performa 60fps |
| B4 — Pengaturan | Halaman settings terpusat | Semua preferensi tersimpan & diterapkan ulang saat app dibuka |
| B5 — PGN import/export | Ekspor & impor file .pgn | File hasil ekspor bisa dibuka di software catur lain (validasi kompatibilitas) |
| B6 — Analysis Board | Mode analisis bebas gerak + evaluasi Stockfish | Evaluasi update real-time saat posisi diubah |
| B7 — Ekspansi platform | Build & stabilisasi Linux + macOS | Semua fitur B1–B6 setara kualitasnya di 4 platform |
| B8 — Persiapan rilis | Packaging, testing menyeluruh, dokumentasi open-source | Installer/APK siap distribusi untuk 4 platform |

**Version 1.0 rilis** ketika B1–B8 selesai di 4 platform. Fitur online (Fase 6 pada roadmap Fase 0) tetap jadi target besar berikutnya setelah v1.0 — belum berubah dari analisis sebelumnya.
