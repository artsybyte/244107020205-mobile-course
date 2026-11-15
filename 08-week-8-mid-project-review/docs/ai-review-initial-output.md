# Output Awal AI Review

Output apa adanya dari AI reviewer untuk prompt di
[`ai-review-prompt.md`](ai-review-prompt.md). Belum diverifikasi — verifikasi dan
keputusan ada di [`ai-review-vs-keputusan.md`](ai-review-vs-keputusan.md).

Branch yang direview: `feat/notes-validation` (diff terhadap `develop`).

---

## Temuan 1 — BLOCKER

**Lokasi:** `lib/data/note_providers.dart:34`

```dart
Future<int> syncNotesFromProvider(WidgetRef ref) async {
  final synced = await syncNotes(
    ref.read(noteRepositoryProvider),
    forceOffline: ref.read(forceOfflineProvider),
  );
  ref.invalidate(notesProvider);
  ref.invalidate(dirtyCountProvider);
  return synced;
}
```

**Alasan:** `WidgetRef` adalah tipe dari `flutter_riverpod` yang hanya hidup di
lapisan presentasi. Karena fungsi ini tinggal di `lib/data/`, data layer jadi
bergantung pada Flutter dan pada widget. Akibatnya fungsi ini tidak bisa dipanggil
dari test tanpa membangun widget tree, dan `data` tidak lagi bisa dipakai ulang
di luar UI.

**Usulan:**

```dart
// lib/pages/notes_page.dart (presentation)
Future<int> _syncNotes(WidgetRef ref) async {
  final synced = await syncNotes(
    ref.read(noteRepositoryProvider),
    forceOffline: ref.read(forceOfflineProvider),
  );
  ref.invalidate(notesProvider);
  ref.invalidate(dirtyCountProvider);
  return synced;
}
```

`syncNotes()` sendiri tetap di `lib/data/sync.dart` karena tidak menyentuh Flutter.

---

## Temuan 2 — BLOCKER

**Lokasi:** `test/note_test.dart:58-73`

```dart
try {
  await container.read(notesProvider.future);
  fail('Expected the notes provider to fail');
} catch (error) {
  expect(error, isA<Exception>());
}
```

**Alasan:** test ini gagal dengan `TimeoutException after 0:00:30` dan error
`StateError: The provider ... was disposed during loading state`. Dua penyebab:

1. `ProviderContainer.read(future)` tidak memasang listener, sehingga
   `FutureProvider` (auto-dispose) dibuang saat masih loading.
2. Riverpod 3 punya **retry otomatis** dengan backoff eksponensial, jadi provider
   tetap `AsyncLoading(retrying)` dan future baru selesai setelah puluhan detik.

**Usulan:**

```dart
final subscription = container.listen(notesProvider, (_, _) {});
addTearDown(subscription.close);
await expectLater(
  container.read(notesProvider.future),
  throwsA(isA<Exception>()),
);
```

Untuk retry, matikan pada level provider (lihat Temuan 3) atau lewat
`ProviderContainer(retry: (_, _) => null)` di test.

---

## Temuan 3 — SARAN

**Lokasi:** `lib/data/note_providers.dart:22-32`

**Alasan:** dengan retry default Riverpod 3, error SQLite lokal akan diulang
dengan backoff eksponensial. UI menampilkan spinner berputar lama sebelum
akhirnya masuk `AsyncError`, padahal error database lokal tidak akan pulih
sendiri. Ini juga yang membuat test pada Temuan 2 menggantung.

**Usulan:**

```dart
Duration? _noRetry(int retryCount, Object error) => null;

final notesProvider = FutureProvider<List<Note>>(
  (ref) => ref.watch(noteRepositoryProvider).fetchNotes(),
  retry: _noRetry,
);
```

---

## Temuan 4 — SARAN

**Lokasi:** `lib/pages/notes_page.dart:81-89` (`_addNote`)

```dart
await ref.read(noteRepositoryProvider).addNote(title: draft.title, body: draft.body);
ref.invalidate(notesProvider);
```

**Alasan:** tidak ada penanganan error. Bila `addNote()` melempar (database
penuh, disk penuh, constraint gagal), exception naik tanpa jejak di UI dan
pengguna mengira catatan tersimpan. Jalur error tidak punya test.

**Usulan:**

```dart
final messenger = ScaffoldMessenger.of(context);
try {
  await ref.read(noteRepositoryProvider).addNote(title: draft.title, body: draft.body);
} catch (error) {
  messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan catatan: $error')));
  return;
}
ref.invalidate(notesProvider);
ref.invalidate(dirtyCountProvider);
```

---

## Temuan 5 — SARAN

**Lokasi:** `lib/core/note_validator.dart:17-19` dan
`lib/widgets/add_note_dialog.dart:58`

**Alasan:** `TextFormField` memakai `maxLength: maxNoteTitleLength`, sehingga
input pengguna sudah dipotong di 80 karakter. Akibatnya cabang
`if (title.length > maxNoteTitleLength)` tidak pernah tercapai dari UI — dead
branch yang tidak punya test.

**Usulan:** hapus cabang panjang dari validator, atau hapus `maxLength` dan
biarkan validator yang menegur. Jangan keduanya.

---

## Saran tambahan yang diminta reviewer (di luar 5 teratas)

> Migrasikan `week5_offline_notes` ke struktur feature-first Clean Architecture
> (`features/notes/{domain,data,presentation}`) seperti `week7/campus_notify`,
> lengkap dengan `datasources/` dan use case per operasi.

Saran ini **tidak** diverifikasi sebagai temuan; keputusannya dibahas di
[`ai-review-vs-keputusan.md`](ai-review-vs-keputusan.md).
