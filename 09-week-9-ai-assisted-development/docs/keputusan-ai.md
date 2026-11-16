# Usulan AI vs Keputusan Final

Setiap saran AI diverifikasi lebih dulu, baru diputuskan. Kolom **Bukti** berisi
perintah atau keluaran nyata yang bisa dijalankan ulang.

| # | Usulan AI | Level | Keputusan | Bukti / Alasan |
|:-:|:----------|:-----:|:---------:|:---------------|
| 1 | `title.contains(query, caseSensitive: false)` | blocker | **Terima + perbaiki** | `flutter analyze` → `error - The named parameter 'caseSensitive' isn't defined ... undefined_named_parameter`. API `String.contains` hanya menerima satu argumen. Diganti `_normalize()` + `contains`. |
| 2 | Filter ditulis langsung di `build()` halaman | saran | **Terima + refactor** | `git grep -n "\.where(" -- lib/pages` menemukan filter di `notes_page.dart:84`. Dipindah ke `lib/core/note_search.dart`; grep yang sama kini kosong. |
| 3 | `if (query.isEmpty) return notes;` | saran | **Terima + perbaiki** | 4 test merah: spasi saja tidak dianggap kosong, huruf besar/kecil tidak cocok, trim diabaikan, urutan berubah. |
| 4 | Test memakai `filterNotes(...)` | saran | **Tolak** | Fungsi itu tidak pernah didefinisikan; `flutter test` gagal kompilasi. Test ditulis manual dengan nama `searchNotes`. |
| 5 | `NoteRepository.searchNotes()` dengan SQL `LIKE` | saran | **Tolak** | Lihat bagian bawah. |
| 6 | Spasi ganda pada query tidak cocok (pass 2) | saran | **Terima + perbaiki** | Test merah: `Expected: an object with length of <1>, Actual: []`. Diperbaiki di PR #18 dengan `RegExp(r'\s+')`. |
| 7 | Ganti empty state jadi satu widget generik dengan parameter teks | saran | **Tolak (disederhanakan)** | Dua keadaan hanya berbeda teks + satu tombol; widget generik menambah satu lapisan abstraksi tanpa menghilangkan duplikasi yang berarti. |

**Rekap:** 4 diterima dengan bukti, 3 ditolak dengan alasan tertulis.

---

## Usulan 5 — ditolak: pencarian di repository dengan SQL `LIKE`

**Klaim AI:** lebih "rapi" bila `NoteRepository` punya method sendiri:

```dart
Future<List<Note>> searchNotes(String query) async {
  final db = await _openDb();
  final rows = await db.query(
    'notes',
    where: 'title LIKE ?',
    whereArgs: ['%$query%'],
    orderBy: 'updated_at DESC',
  );
  return rows.map(Note.fromMap).toList();
}
```

**Alasan penolakan:**

1. **Koneksi per ketikan.** `NoteRepository` memanggil `await _openDb()` di
   setiap method. Dengan pencarian real-time (`onChanged`), setiap huruf yang
   diketik membuka koneksi database baru. Ini memperparah masalah yang sudah
   dicatat di issue #10, bukan menyelesaikannya.
2. **Memutus alur cache-first.** Daftar catatan sudah dimuat utuh ke
   `notesProvider`. Memfilter di memori bersifat O(n) tanpa I/O; query SQL
   menambah round-trip untuk data yang sudah ada di tangan.
3. **`LIKE` di SQLite case-insensitive hanya untuk ASCII.** Untuk judul
   berbahasa Indonesia yang mengandung karakter non-ASCII, perilakunya
   bergantung pada `PRAGMA case_sensitive_like`. Normalisasi di Dart
   memberi hasil yang sama di semua platform, termasuk web.
4. **Widget test jadi berat.** Test empty state harus menyalakan
   `sqflite_common_ffi`, bukan sekadar repository palsu.

**Yang dilakukan sebagai gantinya:** `searchNotes(List<Note>, String)` di
`lib/core`, dipanggil dari halaman setelah `notesProvider` selesai memuat.

---

## Usulan 7 — ditolak: satu widget empty state generik

```dart
// usulan AI
EmptyState(icon: ..., message: ..., actionLabel: ..., onAction: ...)
```

**Alasan penolakan:** dua keadaan kosong hanya muncul di satu tempat
(`_NotesList`) dan berbeda pada satu tombol. Menambah widget generik berarti
menambah satu berkas + satu parameter opsional yang harus dijelaskan, tanpa
mengurangi duplikasi nyata. Kalau nanti empty state dipakai di halaman lain,
ekstraksi bisa dilakukan saat itu — dengan dua pemakai nyata sebagai acuan.

---

## Keputusan per berkas

| Berkas | Keputusan | Catatan |
|:-------|:----------|:--------|
| `lib/core/note_search.dart` | **Tolak + tulis manual** | Versi AI memakai `contains` tanpa normalisasi; ditulis ulang sebagai fungsi murni |
| `lib/widgets/notes_search_field.dart` | **Terima + refactor** | AI menyarankan `TextField` inline dengan `setState`; diubah jadi widget terkontrol provider |
| `lib/pages/notes_page.dart` | **Terima + refactor** | Filter dikeluarkan dari `build()`, empty state dibedakan |
| `lib/data/note_providers.dart` | **Terima + refactor** | AI menyarankan `StateProvider`; diganti `Notifier<String>` mengikuti gaya berkas (Riverpod 3) |
| `test/note_search_test.dart` | **Tolak + tulis manual** | Test AI memanggil fungsi yang tidak ada; 10 test ditulis ulang |
| `test/notes_page_search_test.dart` | **Terima + perluas** | AI hanya memberi satu test; ditambah kasus empty state dan "belum ada catatan" |
