# Architecture Decision Record — Grand Chess

Dokumen ini mencatat keputusan teknis utama beserta konteks, alasan, dan konsekuensinya. Dokumen produk (fitur, scope, milestone) ada di **Grand-Chess-PRD.md**.

---

## ADR-001: Framework lintas platform — Flutter

**Status:** Diterima
**Tanggal:** 9 Agustus 2026 — direvisi 21 Agustus 2026 (wording diperketat + verifikasi sumber resmi)

**Konteks:** Grand Chess perlu berjalan native di Android, Windows, macOS, dan Linux dari satu basis kode, dengan performa yang baik, animasi halus, dan UI "aplikasi" penuh (bukan cuma game).

**Opsi yang dipertimbangkan:** Flutter, Compose Multiplatform, React Native, Godot, Unity.

**Keputusan:** Flutter (Dart).

**Alasan** *(direvisi supaya tidak berlebihan/absolut — lihat "Sumber" di bawah)*:

- **Model kompilasi.** Build release Flutter dikompilasi Ahead-of-Time (AOT) ke kode mesin native, bukan diinterpretasi saat runtime seperti mode debug. Menurut FAQ resmi Flutter, ini berarti kode Dart (dan Flutter engine-nya) langsung dimuat sebagai library native saat aplikasi dijalankan, tanpa lapisan interpretasi tambahan. **Koreksi dari draft sebelumnya:** ini bukan berarti "tanpa runtime sama sekali" — Dart tetap punya runtime ringan (pengelola memori/garbage collector) yang aktif bahkan di build release. Yang hilang di AOT hanyalah interpreter/JIT, bukan seluruh runtime. Dibanding pendekatan berbasis JVM penuh seperti Compose Multiplatform, runtime Dart ini jauh lebih ramping — tapi klaim "startup cepat" dan "hemat RAM" adalah kecenderungan umum dari model ini, bukan angka yang dijamin; performa aktual tetap bergantung pada desain aplikasi.
- **Dukungan desktop.** Pada Google I/O 2026, tim Flutter resmi mengumumkan Canonical (perusahaan di balik Ubuntu) mengambil peran sebagai pengelola utama dan penentu roadmap jangka panjang untuk Flutter di desktop, mencakup Linux, Windows, dan macOS sekaligus. **Koreksi dari draft sebelumnya:** klaim "paling matang" saya lunakkan — riset Fase 0 juga menemukan Compose Multiplatform punya rendering desktop dengan akselerasi hardware di ketiga OS yang sama, jadi keduanya sama-sama punya fondasi desktop yang solid. Diferensiator Flutter yang lebih akurat: ada sinyal investasi jangka panjang yang eksplisit dan bisa diverifikasi (kemitraan resmi dengan Canonical), bukan klaim "satu-satunya pilihan matang".
- **React Native.** Dokumentasi resmi React Native sendiri (halaman "Out-of-Tree Platforms") menyatakan dukungan Linux hanya tersedia lewat proyek renderer alternatif yang belum masuk rilis utama, bukan dukungan resmi dari tim inti. Karena Linux adalah target wajib proyek ini, ini gap yang signifikan. **Koreksi dari draft sebelumnya:** kata "fatal" saya ganti jadi "signifikan" — tetap gap nyata, tapi framing sebelumnya terlalu dramatis untuk dokumen teknis.
- **Godot/Unity.** Keduanya game engine yang terbukti mampu lintas platform. Pola UI "aplikasi" (form, halaman setting, integrasi database) pada umumnya butuh lebih banyak kerja manual dibanding toolkit yang memang dirancang untuk app — ini pengamatan umum dari desain engine-nya, bukan keterbatasan mutlak (Godot sendiri bisa dipakai untuk software non-game, hanya bukan kasus umum).
- **Dart vs JS/TS.** Dart cukup dekat secara sintaks dengan JavaScript/TypeScript (struktur class, async/await), yang membantu kurva belajar — meski tetap bahasa baru yang perlu waktu untuk dikuasai, bukan "langsung bisa".

**Konsekuensi:**
- Perlu mempelajari Dart — bahasa baru, walau kurva belajarnya relatif landai bagi developer berlatar JS/TS
- Paket pihak ketiga khusus desktop (terutama Linux) kemungkinan belum sebanyak untuk Android — perlu diuji sejak awal, bukan diasumsikan otomatis bekerja

**Sumber yang diverifikasi (21 Agustus 2026):**
- Pengumuman kemitraan Canonical: blog resmi Flutter — flutter.dev/blog/whats-new-in-flutter-3-44
- Model kompilasi AOT & runtime: FAQ resmi Flutter — docs.flutter.dev/resources/faq
- Status dukungan Linux React Native: dokumentasi resmi React Native — reactnative.dev/docs/out-of-tree-platforms

---

## ADR-002: Strategi chess engine — mesin aturan custom + Stockfish

**Status:** Diterima

**Konteks:** Aplikasi butuh (1) mesin aturan catur yang benar, dan (2) "otak" AI yang kuat dan terasa natural.

**Opsi yang dipertimbangkan:** bangun AI sendiri dari nol (minimax + alpha-beta), pakai Stockfish untuk aturan sekaligus AI, atau hybrid.

**Keputusan:** Hybrid — mesin aturan catur (board, legal move, FEN/PGN) ditulis sendiri dalam Dart murni tanpa dependensi UI; kekuatan bermain AI memakai Stockfish via protokol UCI (Universal Chess Interface).

**Alasan:**
- Mesin aturan wajib ada terlepas dari siapa "otak" AI-nya, dan jadi medium belajar algoritma yang baik
- Stockfish sudah teruji dan punya fitur *limit strength* untuk mensimulasikan level kesulitan yang terasa manusiawi
- Mobile pakai FFI (Foreign Function Interface), desktop pakai proses terpisah lewat UCI

**Update 21 Agustus 2026 — abstraksi komunikasi AI (wajib, sebelum Fase 4 dimulai):**

Chess engine (domain) dan UI tidak boleh terikat langsung ke mekanisme komunikasi Stockfish. Struktur lapisan yang mengikat implementasi Fase 4 nanti:

```
ChessAI (interface abstrak)
        ↓
StockfishAdapter (implementasi ChessAI, bicara protokol UCI)
        ↓
implementasi spesifik platform (FFI di mobile, subprocess di desktop)
```

`ChessAI` mendefinisikan kontrak sederhana (contoh: minta langkah terbaik untuk suatu posisi, atur level kesulitan) tanpa tahu apa pun soal UCI, FFI, atau proses sistem. `StockfishAdapter` yang menerjemahkan kontrak itu ke protokol UCI. Detail "bagaimana Stockfish benar-benar dijalankan" (FFI vs proses terpisah) disembunyikan di lapisan implementasi paling bawah, di belakang adapter.

**Alasan:** kalau nanti mekanisme komunikasi perlu diganti (atau bahkan Stockfish diganti engine lain), perubahan berhenti di adapter — chess_engine (domain) dan ui tidak perlu disentuh sama sekali.

**Catatan implementasi:** interface dan adapter ini BELUM dibuat di Fase 1 — chess engine baru masuk Fase 2, Stockfish baru masuk Fase 4. Dicatat sekarang supaya keputusan desainnya sudah jelas sebelum implementasi dimulai.

**Konsekuensi (tidak berubah):** dependensi pada Stockfish (GPL-3.0) — kompatibel karena proyek memang direncanakan open-source, tapi tetap perlu disclosure lisensi sejak rilis Alpha.

---

## ADR-003: Database lokal — Drift

**Status:** Diterima (berlaku mulai Version 1.0)

**Konteks:** Perlu menyimpan riwayat game, statistik, dan pengaturan secara lokal, dengan skema yang bisa berkembang tanpa merusak data lama.

**Keputusan:** Drift — ORM SQL untuk Dart/Flutter dengan sistem migration bawaan.

**Alasan:** type-safe (kesalahan tipe data terdeteksi saat compile, bukan saat aplikasi jalan), migration schema tersedia out-of-the-box, terintegrasi baik dengan Flutter.

**Konsekuensi:** MVP Alpha sengaja tidak memakai database sama sekali — setiap game dimulai fresh. Lihat ADR-005 untuk bagaimana Game State didesain supaya persistensi ini bisa ditambah di Version 1.0 tanpa membongkar domain logic.

---

## ADR-004: Urutan rilis platform — Android & Windows dulu, baru Linux & macOS

**Status:** Diterima

**Konteks:** Draft awal mengasumsikan rilis 4 platform sekaligus sejak Alpha. Developer solo dengan waktu terbatas, tanpa tim QA.

**Keputusan:** MVP Alpha hanya menyasar Android dan Windows. Linux dan macOS ditambahkan di Version 1.0.

**Alasan:**
- Android & Windows kemungkinan besar adalah perangkat yang paling mudah diakses developer untuk testing harian
- macOS butuh hardware Apple untuk build & test — menunda ini mengurangi hambatan di fase paling awal
- Menyempitkan target platform di Alpha mengurangi permukaan bug sebelum inti gameplay solid

**Konsekuensi:**
- Arsitektur kode tetap platform-agnostic sejak awal (tidak berubah dari ADR-001) — yang berubah hanya urutan testing & rilis
- Linux dan macOS butuh alokasi waktu pengujian khusus di Version 1.0

---

## ADR-005: Game State sebagai domain model in-memory

**Status:** Diterima

**Konteks:** MVP Alpha tidak memakai database (ADR-003), tapi state permainan yang sedang berjalan (posisi, giliran, riwayat langkah) tetap harus disimpan di suatu tempat selama aplikasi berjalan. Desainnya perlu memastikan Version 1.0 bisa menambah persistensi tanpa membongkar ulang logika inti.

**Keputusan:** Game State adalah domain model murni (plain Dart object, bukan widget, bukan model database), hidup di lapisan `game/`, sepenuhnya terpisah dari UI maupun database. Untuk Alpha, model ini hanya disimpan in-memory — hilang saat aplikasi ditutup.

**Alasan:** kalau Game State didesain bersih sejak awal — tidak tercampur dengan state widget, tidak langsung bergantung pada Drift — menambah persistensi di Version 1.0 nantinya tinggal soal menyimpan/memuat objek itu, bukan mendesain ulang cara game berjalan.

**Konsekuensi:**
- Di Alpha, menutup aplikasi berarti kehilangan game yang sedang berjalan — ini konsekuensi yang disengaja (lihat PRD bagian MVP Alpha), bukan bug
- Struktur model ini BELUM dibuat di Fase 1 — baru masuk Fase 2 bersama chess_engine. Dicatat di sini sebagai prinsip desain yang mengikat implementasi nanti, bukan kode yang sudah ada

---

## ADR-006: Strategi testing chess engine

**Status:** Diterima (berlaku mulai Fase 2, saat chess_engine mulai ditulis)

**Konteks:** Chess engine adalah bagian paling kritis untuk benar — satu bug di move generation bisa membuat permainan curang atau macet tanpa terlihat jelas. Unit test biasa saja tidak cukup untuk membuktikan mesin catur bebas bug.

**Keputusan:** Chess engine diuji dengan beberapa lapis pengujian:

| Jenis test | Yang diuji |
|---|---|
| Unit test aturan dasar | Setiap aturan catur satu per satu (pola gerak tiap bidak, dsb) |
| FEN position test | Parsing & serialisasi FEN menghasilkan posisi yang benar, dari berbagai posisi acuan |
| Special-move test | Castling, en passant, promotion — kasus yang sering jadi sumber bug |
| Draw/repetition test | Threefold repetition, fifty-move rule, stalemate terdeteksi dengan benar |
| PGN round-trip test | Game ditulis ke PGN lalu dibaca ulang menghasilkan urutan langkah yang identik |
| Perft test | Menghitung total langkah legal dari suatu posisi sampai kedalaman tertentu, dibandingkan angka referensi yang sudah diketahui benar — standar de-facto di dunia chess programming untuk memvalidasi move generator bebas bug |
| Regression test | Setiap bug yang pernah ditemukan ditambahkan sebagai test permanen, supaya tidak muncul lagi |

**Alasan:** perft test khususnya adalah cara paling andal untuk memvalidasi move generator — satu bug sekecil apa pun (langkah ilegal yang ikut terhitung, atau langkah legal yang terlewat) hampir selalu membuat angka perft berbeda dari angka referensi di suatu kedalaman.

**Catatan penting — batasan klaim:** lolos seluruh lapisan test ini TIDAK berarti "100% correctness" secara absolut. Artinya benar terhadap seluruh skenario yang sudah diuji — bukan pembuktian matematis atas semua kemungkinan posisi catur yang jumlahnya jauh lebih besar dari yang bisa diuji satu per satu. Dokumen proyek ke depan (PRD, laporan progres) tidak akan memakai frasa "100% correctness"; klaim yang valid adalah "lolos seluruh lapisan test yang didefinisikan di ADR ini".

**Konsekuensi:** test spesifik (bukan cuma infrastrukturnya) baru ditulis di Fase 2. Fase 1 hanya menyiapkan test runner/tooling.

---

## ADR-007: Board representation — 8x8 array, not bitboards

**Status:** Diterima
**Tanggal:** 21 Agustus 2026 (Fase 2)

**Konteks:** Chess engine butuh representasi papan. Opsi umum di dunia chess programming: array 8x8 sederhana, 0x88, atau bitboard (64-bit integer per jenis bidak/warna, sangat cepat tapi jauh lebih rumit dibaca dan di-debug).

**Keputusan:** Array 8x8 flat (`List<Piece?>` panjang 64, index = `rank*8+file`).

**Alasan:**
- Brief proyek eksplisit meminta simplicity/correctness/maintainability diprioritaskan di atas performa mentah, dan secara eksplisit melarang memilih bitboard "karena terdengar lebih advanced"
- Grand Chess tidak melakukan pencarian jutaan node per detik (itu tugas Stockfish di Fase 4 lewat proses terpisah) — engine ini hanya perlu generate legal move untuk UI dan memvalidasi aturan, beban kerja yang jauh lebih ringan
- Array 8x8 paling mudah dibaca, di-debug, dan diajarkan — relevan karena proyek ini juga media belajar
- Immutable (lihat ADR-008) menghapus sebagian besar alasan performa untuk memilih representasi bit-level

**Konsekuensi:** Beberapa operasi (misal "apakah kotak ini diserang") butuh iterasi eksplisit alih-alih operasi bit tunggal — dampaknya diterima karena skala papan catur (64 kotak) membuat perbedaan performa nyaris tidak terasa untuk kasus pemakaian proyek ini.

---

## ADR-008: Position dan GameState immutable, bukan mutable make/unmake

**Status:** Diterima
**Tanggal:** direvisi 6 September 2026 (Fase 2.2 — celah implementasi ditutup)

**Konteks:** Engine butuh cara menerapkan move dan (secara internal) mendukung undo, deteksi repetisi, dan determinism. Pendekatan klasik chess engine adalah mutable board dengan make/unmake move (efisien tapi rawan bug "lupa mengembalikan salah satu bagian state saat unmake").

**Keputusan:** `Position.applyMove()` selalu mengembalikan objek `Position` baru, tidak pernah memutasi yang lama. `GameState.applyMove()` sama — mengembalikan `GameState` baru.

**Alasan:**
- Menghapus seluruh kategori bug "unmake tidak lengkap" secara struktural — tidak ada apa pun untuk di-unmake, riwayat lama tetap utuh selama referensinya dipegang
- Undo jadi gratis: cukup pakai referensi `GameState` sebelumnya, tidak perlu method `undo()` terpisah
- Cocok dengan requirement determinism ("posisi sama + move sama = state sama") secara alami — `applyMove` adalah fungsi murni
- Mendukung kebutuhan Analysis Board di Version 1.0 (eksplorasi variasi/cabang dari satu posisi) tanpa risiko satu cabang merusak cabang lain
- Requirement performa proyek eksplisit meminta "jangan premature optimization" dan "ukur dulu sebelum micro-optimize" — alokasi objek baru per move diterima sebagai trade-off yang disengaja, bukan diabaikan

**Revisi 6 September 2026 (Fase 2.2):** audit menemukan `GameState.positionHistory` dan `moveHistory` dideklarasikan `final List<...>` tapi tidak pernah dibungkus `List.unmodifiable` — `final` hanya mencegah field di-assign ulang, bukan mencegah `.add()`/`.clear()` pada list yang ditunjuknya. Ini celah implementasi terhadap keputusan immutability di atas, bukan perubahan keputusan. Diperbaiki di konstruktor `GameState._` (satu tempat, berlaku untuk semua factory). `Position._board` sudah benar sejak awal (sudah pakai `List.unmodifiable`) — celahnya spesifik di `GameState`, bukan `Position`. Regression test ada di `regression_test.dart`.

**Konsekuensi:** Setiap move mengalokasikan array papan baru (lihat ADR-007 soal ukurannya — 64 elemen, murah). Kalau nanti profiling menunjukkan ini jadi bottleneck nyata (misalnya AI search dalam butuh generate ribuan posisi/detik), ini titik yang terdokumentasi untuk dipertimbangkan ulang — bukan diasumsikan aman selamanya.

---

## ADR-009: Identitas Move — (from, to, promotion) saja

**Status:** Diterima

**Konteks:** `Move` punya beberapa flag turunan (isCapture, isEnPassant, isCastleKingside/Queenside, isDoublePawnPush) yang diisi otomatis oleh `MoveGenerator`. Pertanyaannya: apakah flag-flag ini ikut menentukan kesamaan (`==`) dua Move?

**Keputusan:** Kesamaan `Move` hanya berdasar `(from, to, promotion)` — trio yang sama dipakai notasi UCI.

**Alasan:**
- Semua flag lain bisa diturunkan sepenuhnya dari `(from, to, promotion)` plus konteks posisi (pion bergerak diagonal ke kotak kosong pasti en passant; king bergerak 2 kotak pasti castling; dst) — bukan bagian identitas, hanya metadata
- Kalau flag ikut menentukan kesamaan, pemanggil yang membuat `Move` minimal (misalnya dari input UI di fase berikutnya, tanpa tahu flag mana yang relevan) bisa gagal cocok dengan move kanonis dari `MoveGenerator`, membuat move yang sah tampak ilegal — ini ditemukan dan diperbaiki saat code review (lihat regression_test.dart)

**Konsekuensi:** `Position.applyMove()` tetap mengasumsikan flag pada `Move` yang diterimanya sudah benar (didokumentasikan eksplisit di kode) — `GameState.applyMove()` bertanggung jawab menyocokkan move minimal dari pemanggil ke move kanonis (lengkap dengan flag) dari `MoveGenerator` sebelum meneruskannya. Pemanggil low-level yang melewati `GameState` tidak mendapat jaminan ini.

---

## ADR-010: Identitas repetisi dan aturan draw yang disederhanakan

**Status:** Diterima
**Tanggal:** 21 Agustus 2026 — direvisi 6 September 2026 (Fase 2.1, presisi definisi en passant)

**Konteks:** Threefold repetition butuh definisi persis "posisi yang sama". Fifty-move rule dan insufficient material juga punya beberapa variasi aturan resmi.

**Keputusan:**
- **Repetition key**: piece placement + side to move + castling rights + en passant target — en passant HANYA dihitung kalau ada minimal satu langkah en passant yang **legal** dari posisi itu (lolos filter king-safety yang sama dipakai `MoveGenerator`), bukan sekadar ada bidak yang secara geometris berada di kotak yang tepat. Halfmove/fullmove counter TIDAK ikut dibandingkan.
- **Fifty-move rule**: diperlakukan sebagai draw otomatis begitu halfmove clock mencapai 100, bukan draw yang harus di-claim pemain — karena belum ada lapisan UI/interaksi pemain di Fase 2 untuk memodelkan "klaim"
- **Insufficient material**: hanya kombinasi yang diakui universal — K vs K, K+B vs K, K+N vs K, K+B vs K+B dengan bishop di kotak warna sama. TIDAK mengimplementasikan "dead position" secara umum (masalah algoritmik yang jauh lebih sulit dan jarang terjadi dalam praktik)

**Revisi 6 September 2026 (Fase 2.1):** wording "en passant HANYA dihitung kalau benar-benar bisa dieksekusi" pada draft sebelumnya ambigu — bisa dibaca sebagai "ada pawn yang secara geometris menyerang kotak itu" (cek posisi saja) alih-alih "langkah itu benar-benar legal" (cek posisi + king-safety). Audit menemukan implementasi sempat memakai interpretasi pertama, yang salah: pawn bisa geometris menyerang kotak en passant tapi capture-nya tetap ilegal kalau itu pinned (king sendiri jadi ter-attack setelah capture). Diperbaiki memakai `MoveGenerator.generateLegalMoves` yang sudah divalidasi perft, bukan re-implementasi logic king-safety terpisah — lihat `GameRules._hasLegalEnPassantCapture`. Regression test untuk kedua arah (pinned harus diabaikan, legal harus tetap dihitung) ada di `regression_test.dart`.

**Alasan:** setiap penyederhanaan di atas didokumentasikan eksplisit sesuai instruksi "jangan implementasi repetition yang naif" dan "dokumentasikan rule yang dipakai agar tidak ambigu" — supaya tidak ada asumsi tersembunyi soal aturan mana yang benar-benar diimplementasikan.

**Konsekuensi:** Kalau nanti dibutuhkan mode "klaim draw manual" (fifty-move sebagai hak pemain, bukan otomatis) atau deteksi dead-position penuh, ini titik yang perlu direvisit — bukan sesuatu yang sudah tercakup diam-diam. Memanggil `generateLegalMoves` di dalam pengecekan repetisi (dipanggil sekali per posisi di riwayat, per pengecekan status) punya biaya lebih dari cek geometris murni — diterima sebagai trade-off correctness-over-speed yang sama seperti ADR-008, bukan diabaikan; belum ada bukti ini jadi bottleneck nyata.
