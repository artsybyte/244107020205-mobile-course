# AI Log — Pencarian Judul Catatan

Dokumen ini merekam siklus **prompt → generate → verify → test → refactor →
explain** untuk satu fitur kecil: pencarian judul catatan beserta empty state.

Project: `05-week-5-local-storage-offline-first/week5_offline_notes`
(tidak membuat project baru — fitur ditambahkan ke project Minggu 5 yang sudah
lolos review Minggu 8).

Issue: [#16](https://github.com/artsybyte/244107020205-mobile-course/issues/16)
PR: [#17](https://github.com/artsybyte/244107020205-mobile-course/pull/17)
(fitur) dan [#18](https://github.com/artsybyte/244107020205-mobile-course/pull/18)
(perbaikan hasil review AI pass 2).

---

## 1. Prompt yang dipakai (formula 5 slot)

```
Peran : senior Flutter dev
Konteks: project week5_offline_notes, layer-first (core/data/pages/widgets),
         Riverpod 3, sqflite, data cache-first. Judul catatan ada di
         Note.title (String), daftar sudah dimuat lewat notesProvider
         (FutureProvider<List<Note>>).
Tugas : tambah pencarian judul catatan + empty state yang membedakan
         "belum ada catatan" dan "hasil filter kosong".
Batas : jangan ubah arsitektur, jangan panggil SQLite dari widget,
         maksimal 80 baris kode produksi, sertakan test.
Output: kode + minimal 1 test sukses + 1 test gagal + cara uji manual.
```

Konteks yang ditempel ke AI (potongan nyata, bukan seluruh repo):

```dart
// lib/data/local/note.dart
class Note {
  const Note({this.id, required this.title, this.body = '',
              required this.updatedAt, this.dirty = false});
  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;
}

// lib/data/note_providers.dart
final notesProvider = FutureProvider<List<Note>>(
  (ref) => ref.watch(noteRepositoryProvider).fetchNotes(),
  retry: _noRetry,
);
```

Yang **tidak** ditempel: token, API key, `.env`, dan isi `build/`.

---

## 2. Output awal AI (disimpan apa adanya, belum diperbaiki)

### 2a. `lib/core/note_search.dart` versi AI

```dart
import '../data/local/note.dart';

/// Menyaring catatan berdasarkan judul.
List<Note> searchNotes(List<Note> notes, String query) {
  if (query.isEmpty) return notes;
  return notes.where((note) => note.title.contains(query)).toList();
}
```

### 2b. Potongan `notes_page.dart` versi AI

```dart
// di dalam notes.when(data: (items) { ... })
final visible = items
    .where(
      (note) => note.title.contains(
        query,
        caseSensitive: false,
      ),
    )
    .toList();
return _NotesList(items: visible);
```

### 2c. Test yang AI sarankan

```dart
test('filter abaikan huruf besar/kecil', () {
  expect(searchNotes(list, 'belanja'), hasLength(2));
});
test('query tak cocok kembalikan kosong', () {
  expect(filterNotes(list, 'zzz-tak-ada'), isEmpty);
});
```

> Catatan: test kedua memanggil `filterNotes`, padahal fungsi yang diusulkan
> bernama `searchNotes`. Ini halusinasi nama fungsi dan langsung terlihat saat
> test dijalankan.

---

## 3. Verifikasi 6 langkah

| # | Langkah | Hasil |
|:-:|:--------|:------|
| 1 | Baca tiap baris | Dua baris tidak saya pahami: `caseSensitive` pada `String.contains` dan pemakaian `filterNotes` di test |
| 2 | Cek import | `note_search.dart` hanya mengimpor `data/local/note.dart` → belum ada Flutter di `core/` ✅ |
| 3 | Cek API | `String.contains` di Dart hanya menerima satu argumen (`Pattern`). Tidak ada parameter `caseSensitive` |
| 4 | `flutter analyze` | **gagal** — lihat bagian 4 |
| 5 | Test sukses + gagal | 8 test ditulis; 4 di antaranya merah pada versi AI |
| 6 | Uji manual | query kosong, cocok, tak cocok (empty state) — lihat `screenshots/` |

---

## 4. Halusinasi / bug yang terbukti

### Temuan A — method fiktif `contains(caseSensitive:)`

```
$ flutter analyze
error - The named parameter 'caseSensitive' isn't defined. Try correcting the
name to an existing named parameter's name, or defining a named parameter with
the name 'caseSensitive' - lib\pages\notes_page.dart:88:25 -
undefined_named_parameter
1 issue found.
```

**Bukti:** pesan analyzer di atas. **Keputusan:** diterima sebagai bug, filter
dipindah ke `lib/core` dan kapitalisasi ditangani `toLowerCase()`.

### Temuan B — logika filter ada di dalam `build()`

```
$ git grep -n "\.where(" -- lib/pages
lib/pages/notes_page.dart:84:                final visible = items
```

**Bukti:** grep di atas (sebelum refactor). Setelah refactor:

```
$ git grep -n "toLowerCase|contains(|\.where(" -- lib/pages
(kosong)
```

**Keputusan:** diterima. Logika pindah ke `lib/core/note_search.dart` supaya
bisa diunit-test tanpa widget tree.

### Temuan C — `query.isEmpty` tidak menangani spasi, kapitalisasi, dan trim

Test yang gagal pada versi AI:

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

**Bukti:** keluaran `flutter test` di atas. **Keputusan:** diterima, ditulis
ulang jadi `trim().toLowerCase()` + `contains`.

### Temuan D — nama fungsi tidak konsisten di test AI

`filterNotes` tidak pernah didefinisikan. Ini halusinasi kecil, tetapi cukup
untuk membuat seluruh berkas test gagal dikompilasi. **Keputusan:** ditolak,
test ditulis manual dengan nama `searchNotes`.

---

## 5. Review AI pass 2 (setelah kode diperbaiki)

Prompt:

```
Review kode search Flutter ini sebagai senior dev.
Konteks: layer-first (core/data/pages/widgets), Riverpod, SQLite.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level (blocker/saran) + alasan.
```

Temuan yang diterima: **spasi ganda pada query**. Bukti test merah:

```dart
test('spasi ganda pada query tetap mencocokkan judul', () {
  final notes = [_note('Tugas Mobile')];
  expect(searchNotes(notes, 'tugas  mobile'), hasLength(1));
});
```

```
Expected: an object with length of <1>
  Actual: []
00:00 +0 -1: Some tests failed.
```

Perbaikan (PR #18) memakai satu helper normalisasi untuk query **dan** judul:

```dart
String _normalize(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
```

Temuan yang ditolak: lihat [`keputusan-ai.md`](keputusan-ai.md).

---

## 6. Refactor yang dilakukan

| Sebelum (AI) | Sesudah | Alasan |
|:-------------|:--------|:-------|
| filter di `build()` | `lib/core/note_search.dart` | bisa diunit-test tanpa widget; aturan bisnis tidak di UI |
| `contains(query, caseSensitive: false)` | `_normalize()` + `contains` | API tidak ada; normalisasi dipakai dua arah |
| `if (query.isEmpty)` | `if (needle.isEmpty)` setelah trim | query spasi saja harus sama dengan kosong |
| satu teks `No cached notes` | dua empty state berbeda + tombol hapus filter | pengguna tahu apa yang harus dilakukan |
| widget test butuh controller | `NotesSearchField` dikontrol provider | tombol "Hapus filter" bisa mengosongkan kolom |

---

## 7. Explain (tanpa membuka AI)

- **Kenapa filter di memori, bukan SQL?** Daftar catatan sudah dimuat ke
  `notesProvider`. Filter di memori tidak menambah I/O dan tidak membuka
  koneksi database per ketikan — persis masalah yang dicatat di issue #10.
- **Kenapa `searchNotes` menerima `List<Note>` dan bukan `WidgetRef`?** Supaya
  fungsi murni: input sama menghasilkan output sama, bisa diuji tanpa Flutter.
- **Kenapa query disimpan di provider?** Empty state perlu tombol "Hapus
  filter" yang mengubah teks kolom pencarian. Kalau query hanya `setState` di
  halaman, widget field harus memegang controller dan menyinkronkan nilainya
  manual.
- **Kenapa urutan dipertahankan?** Repository sudah mengurutkan
  `updated_at DESC`; filter yang mengurutkan ulang akan mengubah ekspektasi
  pengguna.
