# Verifikasi — Fitur Chat AI

Semua keluaran di bawah diambil dari mesin lokal
(Windows 11, Flutter 3.47.2, Dart 3.13.2).

---

## 1. `flutter analyze`

```
$ flutter analyze
Analyzing week5_offline_notes...
No issues found! (ran in 2.2s)
```

## 2. `dart format`

```
$ dart format --output=none --set-exit-if-changed lib test
Formatted 56 files (0 changed) in 0.07 seconds.
# exit code 0
```

## 3. `flutter test`

```
$ flutter test
00:02 +95: All tests passed!
```

Test yang menyangkut fitur AI (59 test):

| Berkas | Cakupan |
|:-------|:--------|
| `test/ai/privacy_filter_test.dart` | email, NIK, telepon `08`/`62`/`+62`, NIK yang diawali `08`, teks aman |
| `test/ai/prompt_builder_test.dart` | susunan konteks, batas jumlah catatan, pemotongan body/pertanyaan, penyamaran data |
| `test/ai/sse_parser_test.dart` | chunk valid, multi-part, keep-alive, JSON rusak, `[DONE]`, chunk tanpa teks |
| `test/ai/local_answer_test.dart` | kata kunci, skor judul vs isi, jawaban kosong, titik desimal `10.00` |
| `test/ai/ai_cache_test.dart` | kunci deterministik, normalisasi, invalidasi sidik jari, prune 20 entri |
| `test/ai/ai_quota_test.dart` | batas harian, reset saat ganti hari, reset manual |
| `test/ai/ai_chat_controller_test.dart` | streaming, cache hit, kuota habis, error + retry, fallback offline, key belum ada (regresi retry Riverpod) |
| `test/ai/ai_chat_page_test.dart` | layar awal, kirim pesan, chip saran, banner error + mode offline |

## 4. `flutter build web`

```
$ flutter build web --release
Compiling lib/main.dart for the Web...   53.7s
√ Built build\web
```

## 5. Uji manual (aplikasi web berjalan, Chrome DevTools Protocol)

Aplikasi disajikan lewat `python -m http.server` di `build/web`, lalu dijalankan
di Chrome headless dengan CDP. Screenshot diambil dari kanvas Flutter yang
benar-benar berjalan, bukan mockup.

| Langkah | Hasil | Screenshot |
|:--------|:------|:-----------|
| Buka aplikasi, tambah 3 catatan | daftar tampil, `Dirty: 3` | `01-daftar-catatan.png` |
| Tekan ikon ✨ | layar chat kosong + 3 chip saran + pengingat privasi | `02-chat-kosong.png` |
| Tekan chip `Catatan tentang tugas?` | balon pengguna, jawaban tumbuh bertahap + kursor `▌` | `03-jawaban-streaming.png` |
| Tunggu 4 detik | jawaban lengkap dua kalimat | `04-jawaban-lengkap.png` |
| Tanya pertanyaan yang sama lagi | jawaban instan, label `dari cache lokal`, kuota tidak bertambah | `05-jawaban-cache.png` |
| Buka Pengaturan | mode demo aktif, `1 dari 30 request`, `1 jawaban tersimpan` | `06-pengaturan-ai.png` |
| Matikan mode demo | field API key muncul, status `key belum tersedia` | `07-pengaturan-tanpa-key.png` |
| Kirim pertanyaan tanpa key | banner `Fitur AI belum siap` + tombol `Mode offline` | `08-fallback-error.png` |
| Tekan `Mode offline` | jawaban dari catatan lokal, tetap ditandai cache lokal | `09-mode-offline.png` |

### Catatan kejujuran

- Tidak ada API key Gemini yang dipakai pada sesi ini. Karena itu screenshot
  jalur sukses memakai **mode demo** (jawaban dibangun dari catatan lokal), dan
  jalur error diuji dengan mematikan mode demo tanpa mengisi key — kondisi nyata
  yang dialami pengguna baru.
- Klien Gemini sendiri diverifikasi lewat unit test parser SSE + pemetaan
  kode error, bukan lewat panggilan jaringan berbayar.

## 6. CI

Job `week5_offline_notes` di `.github/workflows/ci.yml` menjalankan
`flutter analyze`, `dart format --set-exit-if-changed`, dan `flutter test` untuk
project yang sama, sehingga fitur ini otomatis ikut diverifikasi pada setiap
push ke `develop` dan setiap PR.
