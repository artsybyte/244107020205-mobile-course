# Issue, Pull Request, dan Review

Semua nomor issue/PR di bawah adalah **draft** yang dipakai saat membuat issue dan
PR di GitHub. Nomor final dicatat ulang di [`../README.md`](../README.md) setelah
issue/PR benar-benar dibuat.

> **Catatan kejujuran:** pada sesi ini tidak ada pasangan reviewer. Review dilakukan
> sebagai **self-review terstruktur** (checklist 15 menit) ditambah **AI review**
> yang diverifikasi. Tidak ada komentar yang diklaim berasal dari orang lain.

---

## 1. Daftar Issue

### Issue A — Suite test `week5_offline_notes` merah

```
Judul: test(notes): suite test gagal — provider error timeout 30s

Masalah:
`flutter test` gagal pada test "provider error dengan repository palsu":
TimeoutException after 0:00:30 dan StateError "provider was disposed during
loading state".

Reproduksi:
1. cd 05-week-5-local-storage-offline-first/week5_offline_notes
2. flutter test test/note_test.dart

Penyebab:
- container.read(notesProvider.future) tanpa listener → FutureProvider
  auto-dispose dibuang saat masih loading.
- Riverpod 3 me-retry provider gagal dengan backoff eksponensial, sehingga
  future baru selesai setelah puluhan detik.

Definition of done:
- test lulus < 5 detik
- ada test untuk countDirty saat repository error
- `dart format` bersih (6 berkas belum terformat)
```

### Issue B — Judul catatan kosong tetap bisa disimpan

```
Judul: feat(notes): validasi judul kosong pada dialog tambah catatan

Masalah:
Pengguna menekan Save dengan judul kosong. Dialog tertutup, tidak ada catatan
tersimpan, dan tidak ada pesan apa pun — pengguna mengira datanya hilang.

Perilaku diharapkan:
- pesan "Judul tidak boleh kosong" muncul di bawah field
- dialog tetap terbuka sampai input valid
- judul di-trim sebelum disimpan

Cakupan: lib/core/note_validator.dart (fungsi murni) + dialog + test.
```

### Issue C — Kegagalan simpan tidak terlihat pengguna

```
Judul: fix(notes): tampilkan SnackBar saat gagal menyimpan catatan

Masalah:
`addNote()` dipanggil tanpa try/catch. Bila SQLite melempar (disk penuh,
constraint gagal), exception naik ke framework dan tidak ada umpan balik UI.

Definition of done:
- SnackBar "Gagal menyimpan catatan: ..." muncul
- daftar tidak di-invalidate saat gagal
- ada widget test dengan repository yang melempar
```

### Issue D — PR kotor tidak ditolak otomatis

```
Judul: chore(ci): workflow analyze + format + test pada pull request

Masalah:
Belum ada CI. PR dengan unused_import, berkas belum terformat, atau test merah
tetap bisa diminta review.

Definition of done:
- .github/workflows/ci.yml jalan pada pull_request ke develop/main
- memeriksa week5_offline_notes (analyze, format, test) dan
  week7 campus_notify (analyze, test)
```

### Issue E — Dokumentasi mid review belum ada

```
Judul: docs: artefak Mid Project Review Minggu 8

Masalah:
Belum ada folder 08-week-8-mid-project-review/ berisi README, checklist,
peta issue/PR, dan dokumentasi AI review.

Definition of done:
- README memuat status paruh semester, peta issue/PR, cara menjalankan
- docs/review-checklist.md memuat tabel sebelum/sesudah commit + kesiapan
- docs/ai-review-*.md memuat prompt, output awal, dan usulan vs keputusan
- screenshots/ berisi bukti aplikasi berjalan
```

### Issue F — Koneksi database dibuka per operasi (follow-up)

```
Judul: perf(notes): cache Future<Database> agar tidak membuka koneksi per operasi

Masalah:
NoteRepository memanggil `await _openDb()` di setiap method. sqflite akan
menjalankan openDatabase() berulang. Terlihat jelas pada test in-memory: setiap
operasi mendapat database kosong yang berbeda.

Catatan: sengaja tidak dikerjakan pada PR Minggu 8 karena mengubah lifecycle
koneksi berdampak ke seluruh alur aplikasi.
```

---

## 2. Pull Request

### PR #1 — `fix/notes-green-suite` → `develop`

```
Judul: fix(notes): hijaukan suite test dan terapkan dart format

Masalah:
- `flutter test` merah: satu test timeout 30 detik karena FutureProvider
  auto-dispose + retry otomatis Riverpod 3.
- 6 berkas belum sesuai `dart format`.
- Tidak ada test yang menyentuh SQLite sungguhan (semua pakai fake).

Solusi:
- Provider: matikan retry otomatis (`retry: _noRetry`) agar error database
  lokal langsung tampil sebagai AsyncError, bukan spinner panjang.
- Test: pasang listener sebelum membaca `.future`, tambah kasus countDirty.
- Format: `dart format lib test`.
- Test baru: `test/note_repository_test.dart` menguji addNote, markAllSynced,
  urutan fetchNotes, fetchNote, dan deleteNote terhadap SQLite in-memory.

Cara uji:
1. cd 05-week-5-local-storage-offline-first/week5_offline_notes
2. flutter analyze                      → No issues found!
3. dart format --set-exit-if-changed lib test → exit 0
4. flutter test                         → 13 test lulus

Dampak: tidak ada perubahan perilaku yang terlihat pengguna, kecuali error
database kini muncul lebih cepat (sebelumnya bisa > 30 detik).

Closes #<A>
```

### PR #2 — `feat/notes-validation` → `develop` (bergantung pada PR #1)

```
Judul: feat(notes): validasi judul kosong + tindak lanjut review

Masalah:
1. Save dengan judul kosong menutup dialog tanpa pesan dan tanpa data.
2. Kegagalan simpan tidak memberi umpan balik.
3. `syncNotesFromProvider(WidgetRef)` tinggal di lib/data sehingga data layer
   bergantung pada Flutter.
4. Label status di halaman detail tidak konsisten kapitalisasinya.

Solusi:
1. `lib/core/note_validator.dart` — fungsi murni `validateNoteTitle`
   (trim, kosong, batas 80 karakter) + `normalizeNoteTitle`.
2. `lib/widgets/add_note_dialog.dart` — Form + TextFormField + validator;
   dialog tetap terbuka saat input belum valid.
3. `_addNote` menangkap error dan menampilkan SnackBar.
4. Orkestrasi sync dipindah ke `lib/pages/notes_page.dart`; `syncNotes()` tetap
   di data layer karena tidak menyentuh Flutter.
5. Label disamakan menjadi "Tersinkron".

Cara uji:
1. Tekan +, kosongkan judul, tekan Save → "Judul tidak boleh kosong",
   dialog tetap terbuka.
2. Isi judul dengan spasi saja → pesan yang sama.
3. Isi judul "  Belanja  " → tersimpan sebagai "Belanja".
4. flutter test test/note_validator_test.dart test/add_note_dialog_test.dart
5. flutter test test/notes_page_test.dart   (SnackBar saat simpan gagal)
6. git grep -n "WidgetRef" -- lib/data      → 0 temuan

Ukuran: 8 berkas, +303 / -51 baris (± 60% di antaranya test baru).

Closes #<B>
Closes #<C>
```

### PR #3 — `chore/ci` → `develop`

```
Judul: chore(ci): jalankan analyze, format, dan test pada pull request

Masalah:
PR kotor masih bisa diminta review karena belum ada pemeriksaan otomatis.

Solusi:
.github/workflows/ci.yml dengan dua job (working-directory per project):
- week5_offline_notes: flutter analyze, dart format --set-exit-if-changed,
  flutter test
- week7 campus_notify: flutter analyze, flutter test

Cara uji:
- Buka PR ini sendiri; job "week5_offline_notes" dan "week7_campus_notify"
  harus hijau.

Catatan: pengecekan `dart format` untuk week7 belum diaktifkan karena masih ada
15 berkas belum terformat (issue lanjutan).

Closes #<D>
```

### PR #4 — `docs/week8-mid-review` → `develop`

```
Judul: docs: artefak Mid Project Review Minggu 8

Masalah:
Belum ada dokumentasi paruh semester, peta issue/PR, dan bukti verifikasi AI.

Solusi:
- 08-week-8-mid-project-review/README.md — status paruh semester, peta
  issue/PR, fitur, stack, cara menjalankan, hasil mesin.
- docs/review-checklist.md — tabel sebelum/sesudah commit + checklist kesiapan
  + bukti tiga grep sterilitas.
- docs/branching.md — model branching dan aturan.
- docs/pr-issue.md — issue, template PR, dan hasil review.
- docs/ai-review-*.md — prompt, output awal, usulan vs keputusan.
- screenshots/ — bukti aplikasi berjalan.

Cara uji:
- Baca README lalu jalankan langkah "Cara menjalankan" dari nol.

Closes #<E>
```

---

## 3. Review 15 Menit (Self-review)

Dilakukan dengan `git diff develop...feat/notes-validation` dan menjalankan
aplikasi. Format: **observasi → dampak → usulan konkret**.

### Kebenaran (2 temuan)

**R1 — blocker**

> **Observasi:** `lib/data/note_providers.dart:34` berisi
> `syncNotesFromProvider(WidgetRef ref)`. Data layer mengimpor `WidgetRef`.
> **Dampak:** `lib/data` tidak bisa dipakai tanpa Flutter; fungsi tidak bisa
> diuji tanpa widget tree; dependency rule rusak (presentasi → data, bukan
> sebaliknya).
> **Usulan:** pindahkan fungsi ke `lib/pages/notes_page.dart` sebagai `_syncNotes`;
> `syncNotes()` tetap di `lib/data/sync.dart`.
> **Verifikasi:** `git grep -n "WidgetRef" -- lib/data` harus 0 temuan.

**R2 — blocker**

> **Observasi:** test "provider error" gagal `TimeoutException after 0:00:30`.
> **Dampak:** CI tidak mungkin hijau; suite test tidak bisa dipercaya.
> **Usulan:** pasang `container.listen` sebelum membaca `.future`, dan matikan
> retry otomatis Riverpod pada provider.
> **Verifikasi:** `flutter test test/note_test.dart` selesai < 1 detik.

### Arsitektur (1 temuan)

**R3 — saran**

> **Observasi:** `_addNote` memanggil repository langsung dari widget dan hanya
> menangani jalur sukses.
> **Dampak:** jalur error tidak punya umpan balik maupun test.
> **Usulan:** bungkus dengan try/catch + SnackBar, dan tambahkan widget test
> dengan repository yang melempar.
> **Catatan:** memindahkan seluruh akses repository ke use case **tidak** saya
> minta di PR ini — itu akan menjadi PR refactor tersendiri.

### Test (1 temuan)

**R4 — saran**

> **Observasi:** semua test memakai `FakeNoteRepository`; tidak ada test yang
> menyentuh SQLite sungguhan.
> **Dampak:** kesalahan SQL, urutan `ORDER BY`, atau mapping kolom tidak akan
> tertangkap.
> **Usulan:** tambahkan `test/note_repository_test.dart` memakai
> `sqflite_common_ffi` dengan database in-memory.
> **Temuan sampingan:** repository membuka koneksi baru per operasi → dicatat
> sebagai Issue F.

### Keterbacaan (1 saran)

**R5 — saran**

> **Observasi:** `notes_page.dart` sebelumnya menampung dialog, status panel,
> dan daftar dalam satu berkas ±197 baris.
> **Dampak:** sulit direview dan sulit diuji terpisah.
> **Usulan:** ekstrak dialog ke `lib/widgets/add_note_dialog.dart` dan validator
> ke `lib/core/note_validator.dart`.
> **Hasil:** `notes_page.dart` turun dan tiap bagian punya test sendiri.

### Keputusan review

| Putaran | Status | Alasan |
|:--------|:-------|:-------|
| 1 | **Request changes** | R1 dan R2 blocker: dependency rule rusak dan suite test merah |
| 2 (setelah perbaikan) | **Approve** | R1, R2 diperbaiki dengan bukti grep + test; R3–R5 ditindaklanjuti atau dicatat sebagai issue |

### Tindak lanjut

| Temuan | Tindakan | Bukti |
|:-------|:---------|:------|
| R1 | `refactor(notes): pindahkan orkestrasi sync dari data layer ke presentation` | `git grep -n "WidgetRef" -- lib/data` → kosong |
| R2 | `fix(notes): hentikan retry otomatis provider…` + `test(notes): perbaiki test provider error…` | 13 → 23 test lulus, tanpa timeout |
| R3 | `fix(notes): tampilkan SnackBar saat gagal menyimpan catatan + test` | `test/notes_page_test.dart` |
| R4 | `test(notes): tambah test integrasi repository…` | `test/note_repository_test.dart` (5 test) |
| R5 | `feat(notes): validasi judul kosong…` memecah dialog + validator | `lib/widgets/add_note_dialog.dart`, `lib/core/note_validator.dart` |

---

## 4. Kesalahan yang saya hindari saat review

| Jebakan | Yang saya lakukan |
|:--------|:------------------|
| "Kode ini jelek, perbaiki" | Selalu menyebut berkas:baris + dampak + usulan kode |
| Debat spasi/format | Dipindahkan ke `dart format` + CI |
| Menyetujui PR tanpa menjalankan | `flutter analyze`, `dart format`, `flutter test` dijalankan sebelum Approve |
| Menempel saran AI mentah | Setiap temuan diverifikasi dulu (lihat `ai-review-vs-keputusan.md`) |
