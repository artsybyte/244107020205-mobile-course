# Usulan AI vs Keputusan Final

Setiap temuan dari [`ai-review-initial-output.md`](ai-review-initial-output.md)
diverifikasi lebih dulu, baru diputuskan. Kolom **Bukti** berisi perintah atau
keluaran nyata yang bisa dijalankan ulang.

| # | Temuan AI | Level | Keputusan | Bukti / Alasan |
|:-:|:----------|:-----:|:---------:|:---------------|
| 1 | `WidgetRef` bocor ke data layer | blocker | **Diterima** | `git grep -n "WidgetRef" -- lib` → sebelum: `lib/data/note_providers.dart:34`; sesudah: **0 temuan di `lib/data`** (hanya tersisa di `lib/pages`). |
| 2 | Test provider error timeout 30 detik | blocker | **Diterima** | Sebelum: `flutter test` → `TimeoutException after 0:00:30` + `StateError: The provider FutureProvider<List<Note>>#fbcaf was disposed during loading state`. Sesudah: 5 test `note_test.dart` lulus dalam < 1 detik. |
| 3 | Retry otomatis Riverpod 3 menahan error | saran | **Diterima** | Akar masalah Temuan 2. Dibuktikan lewat test debug: state tetap `AsyncLoading(retrying)` setelah 50 ms. Setelah `retry: _noRetry`, state langsung `AsyncError`. |
| 4 | Jalur error `_addNote` tidak ditangani | saran | **Diterima** | Ditambah test `test/notes_page_test.dart` dengan repository yang melempar → `find.textContaining('Gagal menyimpan catatan')` `findsOneWidget`. |
| 5 | Cabang panjang di validator = dead branch | saran | **Ditolak (sebagian)** | Lihat bagian "Temuan 5" di bawah. |
| 6 | Migrasi penuh ke feature-first Clean Architecture | — | **Ditolak** | Lihat bagian "Saran tambahan" di bawah. |

**Rekap:** 4 temuan diterima dengan bukti, 2 ditolak dengan alasan tertulis.

---

## Temuan 5 — ditolak (sebagian)

**Klaim AI:** cabang `if (title.length > maxNoteTitleLength)` tidak pernah
tercapai karena `TextFormField` sudah memakai `maxLength`, jadi dead code.

**Verifikasi:**

```bash
git grep -n "maxNoteTitleLength" -- lib test
# lib/core/note_validator.dart:9   const int maxNoteTitleLength = 80;
# lib/core/note_validator.dart:19  if (title.length > maxNoteTitleLength) {
# lib/widgets/add_note_dialog.dart:58  maxLength: maxNoteTitleLength,
# test/note_validator_test.dart:22  final title = 'a' * maxNoteTitleLength;
# test/note_validator_test.dart:27  final title = 'a' * (maxNoteTitleLength + 1);
```

**Penilaian:** klaim bahwa cabang itu tidak tercapai **dari widget** benar.
Tetapi menyebutnya "dead code" tidak tepat: `validateNoteTitle` adalah fungsi
murni yang juga diuji langsung (`test/note_validator_test.dart`) dan menjadi
kontrak aturan bisnis, sedangkan `maxLength` hanyalah pembatas UX di satu
widget. Kalau salah satu dihapus:

- hapus `maxLength` → pengguna bisa mengetik 500 karakter lalu ditolak setelah
  selesai mengetik (UX buruk),
- hapus cabang panjang → kontrak tidak lagi menjaga bila validator dipakai di
  form lain atau dipanggil dari kode non-UI.

**Keputusan:** **pertahankan keduanya**, tetapi tambahkan komentar di validator
agar pembaca tahu `maxLength` adalah lapis pertama dan validator adalah kontrak.
Ini juga menutup celah "test gap" yang disebut AI, karena kedua sisi kini diuji.

---

## Saran tambahan — ditolak

**Klaim AI:** `week5_offline_notes` sebaiknya dimigrasikan ke
`features/notes/{domain,data,presentation}` lengkap dengan `datasources/` dan use
case per operasi.

**Alasan penolakan:**

1. **Di luar lingkup PR.** PR ini memperbaiki test, format, dan satu validasi.
   Migrasi struktur menyentuh hampir semua berkas dan mustahil direview < 15 menit.
2. **Sudah dikerjakan di tempat yang benar.** Refactor feature-first ada di
   `07-week-7-clean-architecture/campus_notify` dengan bukti tiga grep sterilitas
   (`docs/review-checklist.md` bagian 3). Mengulangnya di project Minggu 5
   menggandakan pekerjaan tanpa menambah bukti apa pun.
3. **Bertentangan dengan prinsip yang sudah saya tulis di refleksi Minggu 7.**
   Use case untuk operasi satu-baris dan `datasources/` tanpa multi-source nyata
   adalah over-engineering untuk project 6 berkas. Saya menolak pola yang sama
   saat review Minggu 7, jadi konsisten menolaknya di sini.
4. **Risiko regresi.** `week5_offline_notes` dipakai sebagai bahan demo offline
   (screenshot & skenario di README). Migrasi besar tanpa kebutuhan membuat demo
   berisiko rusak menjelang UTS.

**Yang saya ambil dari saran ini:** satu bagian yang memang murah dan benar —
memindahkan orkestrasi `sync` yang menyentuh `WidgetRef` keluar dari `lib/data`
(Temuan 1). Itu memperbaiki arah dependensi tanpa memindahkan seluruh project.

---

## Catatan: temuan yang tidak muncul dari AI tetapi saya temukan sendiri

Saat menulis test integrasi repository, saya menemukan bahwa
`NoteRepository` membuka **koneksi database baru pada setiap pemanggilan**
(`await _openDb()` di tiap method). Untuk `sqflite` ini berarti
`openDatabase()` dipanggil berulang. Di test in-memory hal ini terlihat jelas:
setiap operasi mendapat database kosong yang berbeda.

Ini **belum** saya perbaiki di PR ini karena mengubah lifecycle koneksi
berdampak ke seluruh alur aplikasi. Dicatat sebagai issue lanjutan:
_"cache Future<Database> di NoteRepository agar tidak membuka koneksi per operasi"_.
