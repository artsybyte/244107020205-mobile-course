# Prompt AI Review (Minggu 8)

Prompt yang dipakai untuk meminta review awal pada PR `feat/notes-validation`.
Prompt asli dari codelab disesuaikan dengan stack project ini (Riverpod 3, SQLite
via `sqflite`, Dio, `go_router`) dan konteks `week5_offline_notes` yang masih
berstruktur *layer-first*, bukan feature-first.

## Prompt

```text
Review PR Flutter ini sebagai senior Flutter dev.

Konteks:
- Project: week5_offline_notes (offline-first notes app).
- Struktur: layer-first (lib/data, lib/pages, lib/widgets), belum feature-first.
  Refactor feature-first sudah dikerjakan di project lain (week7 campus_notify),
  jadi JANGAN menyarankan migrasi struktur penuh di PR ini.
- State management: Riverpod 3 (FutureProvider, NotifierProvider).
- Storage: sqflite untuk tabel `notes`, shared_preferences untuk preferensi tema.
- Networking: Dio (hanya untuk cache posts).
- Navigasi: go_router.
- PR berisi: perbaikan test yang timeout, penerapan dart format, fitur validasi
  judul kosong pada dialog tambah catatan, dan perpindahan orkestrasi sync.

Fokus review: kebenaran, arsitektur, dan test. Abaikan style (sudah ditangani
`dart format` + CI).

Berikan 5 temuan teratas, masing-masing dengan:
1. level (blocker / saran),
2. lokasi berkas dan baris,
3. alasan,
4. usulan potongan kode perbaikan.
```

## Aturan yang saya pegang saat menilai hasil AI

1. Temuan hanya diterima bila bisa **dibuktikan**: `grep`, test yang gagal, atau
   reproduksi manual.
2. Usulan yang melanggar *dependency rule* (domain/data mengimpor Flutter)
   ditolak walau terlihat "lebih bersih".
3. Nitpick style yang sudah dicakup `dart format`/CI diabaikan.
4. Keputusan akhir tetap milik saya dan dicatat di
   [`ai-review-vs-keputusan.md`](ai-review-vs-keputusan.md).
