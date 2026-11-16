# Verifikasi Mesin dan Manual

Semua keluaran di bawah diambil dari eksekusi nyata di mesin pengembang
(Flutter 3.47.2 / Dart 3.13.2), bukan dari AI.

---

## 1. Sebelum perbaikan (kode hasil AI apa adanya)

### `flutter analyze`

```
$ flutter analyze
Analyzing week5_offline_notes...

  error - The named parameter 'caseSensitive' isn't defined. Try correcting the
  name to an existing named parameter's name, or defining a named parameter with
  the name 'caseSensitive' - lib\pages\notes_page.dart:88:25 -
  undefined_named_parameter

1 issue found. (ran in 44.4s)
```

### `flutter test test/note_search_test.dart`

```
00:00 +1 -1: searchNotes query berisi spasi saja dianggap kosong [E]
  Expected: an object with length of <3>
    Actual: []
00:00 +2 -2: searchNotes mengabaikan huruf besar/kecil [E]
  Expected: an object with length of <2>
    Actual: [Instance of 'Note']
00:00 +2 -3: searchNotes mengabaikan spasi di awal dan akhir query [E]
  Expected: an object with length of <1>
    Actual: []
00:00 +3 -4: searchNotes urutan catatan tidak berubah setelah difilter [E]
  Expected: [1, 2]
    Actual: MappedListIterable<Note, int?>:[2]
00:00 +4 -4: Some tests failed.
```

---

## 2. Sesudah refactor

### `flutter analyze`

```
$ flutter analyze
Analyzing week5_offline_notes...
No issues found! (ran in 2.4s)
```

### `dart format --set-exit-if-changed`

```
$ dart format --output=none --set-exit-if-changed lib test
Formatted 31 files (0 changed) in 0.12 seconds.
# exit code 0
```

### `flutter test`

```
$ flutter test
00:06 +36: All tests passed!
```

Rincian: 23 test lama (Minggu 5–8) tetap lulus, ditambah 13 test baru:

| Berkas | Jumlah | Isi |
|:-------|:------:|:----|
| `test/note_search_test.dart` | 10 | kosong, spasi saja, sebagian, kapitalisasi, trim, tanpa hasil, spasi ganda (query), spasi ganda (judul), urutan, list kosong |
| `test/notes_page_search_test.dart` | 3 | menyaring daftar, empty state + hapus filter, belum ada catatan |

---

## 3. Bukti logika tidak lagi di widget

```
$ git grep -n "toLowerCase" -- lib/pages
(kosong)

$ git grep -n "contains(" -- lib/pages
(kosong)

$ git grep -n "\.where(" -- lib/pages
(kosong)
```

Satu-satunya tempat aturan pencarian:

```
$ git grep -n "toLowerCase" -- lib/core
lib/core/note_search.dart:19:  final needle = _normalize(query);
lib/core/note_search.dart:22:      .where((note) => _normalize(note.title).contains(needle))
```

---

## 4. Uji manual (Chrome, aplikasi web hasil `flutter build web`)

| Langkah | Hasil | Screenshot |
|:--------|:------|:-----------|
| Buka aplikasi, tambah 3 catatan | daftar tampil, `Dirty: 3` | `01-daftar-catatan.png` |
| Ketik `tugas` | hanya `Tugas Mobile` tampil | `02-hasil-pencarian.png` |
| Ketik `zzz-tidak-ada` | empty state + tombol `Hapus filter` | `03-empty-state.png` |
| Ketik `tugas  mobile` (dua spasi) | `Tugas Mobile` tetap tampil | `04-spasi-ganda.png` |
| Kosongkan kolom | semua catatan tampil lagi | — |

Screenshot diambil dari aplikasi yang benar-benar berjalan (`flutter build web`
+ Chrome DevTools Protocol), bukan mockup.

---

## 5. CI

| Run | Branch | Kesimpulan |
|:---:|:-------|:-----------|
| #21 | `feat/notes-search` | ✅ success |
| #22 | `develop` | ✅ success |
| #23 | `fix/notes-search-whitespace` | ✅ success |

Workflow memakai toolchain yang dipin (`flutter-version: 3.47.2`) dan
`flutter pub get --enforce-lockfile`, sehingga hasil di runner sama dengan lokal.

---

## 6. Regresi yang dicek

| Yang dicek | Hasil |
|:-----------|:------|
| `test/widget_test.dart` (kontrol halaman) | lulus — kolom pencarian tidak menggeser `Offline Notes` / `Force offline` / `Sync now` |
| `test/notes_page_test.dart` (SnackBar gagal simpan) | lulus |
| `test/note_repository_test.dart` (SQLite in-memory) | lulus, tidak tersentuh |
| `test/add_note_dialog_test.dart` | lulus |
| Project `07-week-7-clean-architecture/campus_notify` | `analyze` bersih, 14 test lulus (tidak diubah) |
