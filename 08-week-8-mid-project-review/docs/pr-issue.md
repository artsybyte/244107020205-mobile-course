# Issue, Pull Request, dan Review

Semua nomor di bawah adalah nomor **final** yang sudah dibuat di GitHub. Issue dan
PR berbagi urutan nomor yang sama: PR #1–#4 dibuat lebih dulu, sehingga issue baru
mendapat nomor **#5–#10**.

> **Catatan kejujuran:** pada sesi ini tidak ada pasangan reviewer. Review dilakukan
> sebagai **self-review terstruktur** (checklist 15 menit) ditambah **AI review**
> yang diverifikasi. Tidak ada komentar yang diklaim berasal dari orang lain.

---

## 1. Daftar Issue

### Issue #5 — Suite test `week5_offline_notes` merah

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

### Issue #6 — Judul catatan kosong tetap bisa disimpan

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

### Issue #7 — Kegagalan simpan tidak terlihat pengguna

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

### Issue #8 — PR kotor tidak ditolak otomatis

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

### Issue #9 — Dokumentasi mid review belum ada

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

### Issue #10 — Koneksi database dibuka per operasi (follow-up)

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

| PR | Branch → base | Terkait | Status | CI |
|:---|:--------------|:--------|:-------|:---|
| #1 | `fix/notes-green-suite` → `develop` | Closes #5 | merged | merah (SDK drift) |
| #2 | `chore/ci` → `develop` | Closes #8 | merged | merah (SDK drift) |
| #3 | `docs/week8-mid-review` → `develop` | Closes #9 | merged | merah (SDK drift) |
| #4 | `feat/notes-validation` → `develop` | Closes #6, #7 | merged | hijau (setelah sinkron `develop`) |
| #11 | `fix/ci-pin-toolchain` → `develop` | Closes #8 | merged | hijau |
| #12 | `docs/week8-corrections` → `develop` | — | merged | hijau |
| #13 | `docs/merge-and-issue-notes` → `develop` | — | merged | hijau |
| #14 | `docs/week8-final-sync` → `develop` | — | merged | hijau |

> **Catatan jujur soal CI:** PR #1–#3 di-merge saat semua workflow masih merah.
> Penyebabnya bukan kode PR, melainkan `channel: stable` yang bergeser ke Flutter
> 3.50 (lihat `review-checklist.md` bagian 2b). PR #11 memperbaikinya, dan sejak
> itu semua run hijau. Urutan yang seharusnya: CI hijau dulu, baru merge.

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

Closes #5
```

### PR #2 — `chore/ci` → `develop`

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

Closes #8
```

### PR #3 — `docs/week8-mid-review` → `develop`

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

Closes #9
```

### PR #4 — `feat/notes-validation` → `develop`

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

Ukuran: 8 berkas, +308 / -51 baris (± 60% di antaranya test baru).

Closes #6
Closes #7
```

### PR #11 — `fix/ci-pin-toolchain` → `develop`

```
Judul: chore(ci): pin Flutter 3.47.2 agar analyze tidak merah karena SDK drift

Masalah:
Seluruh CI run merah (5 dari 5) tanpa ada perubahan kode. Semua gagal di langkah
`flutter analyze`, termasuk run pada commit lama yang sebelumnya hijau.

Penyebab: workflow memakai `channel: stable` tanpa versi. Pada 11 Nov 2026 stable
naik ke Flutter 3.50.0 / Dart 3.14.0, dan rilis itu men-deprecate
`package:flutter/material.dart` serta `package:flutter/cupertino.dart`.
Akibatnya setiap import Material menghasilkan info `deprecated_member_use` dan
`flutter analyze` keluar dengan exit code 1.

Bukti:
- Lokal (3.47.2 / Dart 3.13.2): No issues found!
- CI (stable = 3.50.0 / Dart 3.14.0): flutter analyze exit 1
- Clone bersih + pub get fresh di 3.47.2: tetap bersih (bukan masalah dependency)

Solusi:
1. Pin `flutter-version: 3.47.2` pada kedua job, dengan komentar alasan.
2. Commit `pubspec.lock` untuk dua project yang diperiksa CI, dan pakai
   `flutter pub get --enforce-lockfile`.
3. `.gitattributes` dengan `eol=lf` agar `dart format` konsisten antara Windows
   (core.autocrlf=true) dan runner Linux.
4. `.gitignore`: buang pubspec.lock dari daftar ignore (kecuali project lain),
   tambahkan hs_err_pid*.log dan replay_pid*.log.

Cara uji:
cd 05-week-5-local-storage-offline-first/week5_offline_notes
flutter pub get --enforce-lockfile   -> Got dependencies!
flutter analyze                      -> No issues found!
dart format --output=none --set-exit-if-changed lib test -> exit 0
flutter test                         -> All tests passed!

cd ../../../07-week-7-clean-architecture/campus_notify
flutter pub get --enforce-lockfile   -> Got dependencies!
flutter analyze                      -> No issues found!
flutter test                         -> 14 tests passed

CI pada PR ini sendiri hijau di kedua job.

Catatan: migrasi ke `material_ui` tidak dikerjakan di sini karena menyentuh
puluhan berkas di dua project; dilacak sebagai follow-up di #10.

Closes #8
```

### PR #12 — `docs/week8-corrections` → `develop`

```
Judul: docs: koreksi nomor issue/PR dan catat temuan SDK drift

Masalah:
Dokumen minggu 8 masih memakai placeholder (#<A>, "menunggu merge") dan nomor PR
yang tertukar: `feat/notes-validation` tertulis PR #2 padahal sebenarnya PR #4.

Solusi:
- README: peta issue/PR memakai nomor final + tautan, ditambah tabel PR terpisah.
- docs/branching.md: nomor PR disamakan dengan kenyataan.
- docs/pr-issue.md: renumber + status CI jujur (PR #1-#3 merge saat CI merah).
- docs/review-checklist.md: bagian baru 2b tentang SDK drift dan cara pinning.

Cara uji:
- Bandingkan setiap nomor di dokumen dengan halaman issue/PR di GitHub.
```

### PR #13 — `docs/merge-and-issue-notes` → `develop`

```
Judul: docs: catat penggunaan merge commit dan penutupan issue manual

Masalah:
README minggu 8 menyebut alur berakhir dengan "squash merge" dan bahwa issue
tertutup otomatis oleh PR. Dua-duanya tidak sesuai kenyataan:
1. Semua PR di-merge dengan merge commit, bukan squash.
2. Issue #5-#9 tidak tertutup otomatis karena keyword `Closes #N` hanya berlaku
   saat merge ke default branch (`main`), sedangkan PR masuk ke `develop`.

Solusi:
- Menambah alasan memakai merge commit: SHA branch tetap utuh sehingga
  `feat/notes-validation` yang dibangun di atas `fix/notes-green-suite` tidak
  perlu di-rebase ulang.
- Menjelaskan mengapa issue ditutup manual, plus opsi otomatisasi (`develop`
  dijadikan default branch, atau issue ditutup saat rilis ke `main`).

Cara uji:
- Baca bagian "Peta Issue / PR" di README dan bandingkan dengan halaman
  issue/PR di GitHub.
```

### PR #14 — `docs/week8-final-sync` → `develop`

```
Judul: docs(week8): sinkronkan status issue/PR dan tambah bukti CI

Masalah:
Isi folder minggu 8 ditulis sebelum PR terakhir di-merge, sehingga:
- PR #4, #11, #12 masih berstatus open padahal sudah merged;
- PR #13 belum tercatat;
- review-checklist menyebut "PR #2" untuk perubahan milik PR #4;
- issue disebut tertutup otomatis padahal ditutup manual;
- belum ada bukti CI hijau di README.

Solusi:
- README: status final issue/PR, tabel PR dengan kolom CI, bagian "Bukti CI
  Hijau" (8 run success), dan tabel "Kesesuaian dengan Definisi Selesai Codelab".
- review-checklist: koreksi nomor PR dan status penutupan issue.
- branching: semua branch merged + aturan merge commit vs squash.
- pr-issue: status final, tambah PR #13 dan #14, "Issue F" -> "Issue #10".

Cara uji:
grep -rn "#<" 08-week-8-mid-project-review/     -> kosong
grep -rn "open |" 08-week-8-mid-project-review/ -> kosong
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
> sebagai Issue #10.

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
