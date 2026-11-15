import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';

/// Membuka database SQLite in-memory dengan schema yang sama seperti
/// `lib/data/local/db.dart`, sehingga repository diuji terhadap SQL nyata
/// (bukan fake).
Future<Database> _openInMemory() {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body TEXT NOT NULL DEFAULT '',
            updated_at TEXT NOT NULL,
            dirty INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    ),
  );
}

void main() {
  sqfliteFfiInit();

  late Database db;
  late NoteRepository repository;

  setUp(() async {
    // Satu koneksi dipakai ulang: database in-memory bersifat per-koneksi,
    // sehingga membuka koneksi baru setiap operasi akan menghasilkan database
    // kosong yang berbeda.
    db = await _openInMemory();
    repository = NoteRepository(openDb: () async => db);
  });

  tearDown(() async {
    await db.close();
  });

  test('addNote menyimpan catatan baru sebagai dirty', () async {
    final note = await repository.addNote(title: 'Belanja', body: 'susu');

    expect(note.id, isNotNull);
    expect(note.title, 'Belanja');
    expect(note.dirty, isTrue);
    expect(await repository.countDirty(), 1);
  });

  test('markAllSynced mengosongkan antrean dirty', () async {
    await repository.addNote(title: 'A');
    await repository.addNote(title: 'B');
    expect(await repository.countDirty(), 2);

    await repository.markAllSynced();

    expect(await repository.countDirty(), 0);
    final notes = await repository.fetchNotes();
    expect(notes.every((note) => note.dirty), isFalse);
  });

  test('fetchNotes mengurutkan dari updated_at terbaru', () async {
    await repository.addNote(title: 'pertama');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repository.addNote(title: 'kedua');

    final notes = await repository.fetchNotes();

    expect(notes.map((note) => note.title).toList(), ['kedua', 'pertama']);
  });

  test('fetchNote mengembalikan null bila id tidak ada', () async {
    final note = await repository.addNote(title: 'A');

    expect(await repository.fetchNote(note.id!), isNotNull);
    expect(await repository.fetchNote(9999), isNull);
  });

  test('deleteNote menghapus baris dari database', () async {
    final note = await repository.addNote(title: 'A');

    await repository.deleteNote(note.id!);

    expect(await repository.fetchNotes(), isEmpty);
    expect(await repository.countDirty(), 0);
  });
}
