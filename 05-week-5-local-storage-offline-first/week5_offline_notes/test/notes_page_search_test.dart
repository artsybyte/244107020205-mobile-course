import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/note_providers.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

/// Repository palsu: tidak menyentuh SQLite, hanya mengembalikan daftar tetap.
class _FakeNoteRepository extends NoteRepository {
  _FakeNoteRepository(this.items)
    : super(openDb: () => throw UnimplementedError());

  final List<Note> items;

  @override
  Future<List<Note>> fetchNotes() async => items;

  @override
  Future<int> countDirty() async => items.where((note) => note.dirty).length;
}

Note _note(String title, {int? id}) =>
    Note(id: id, title: title, updatedAt: DateTime(2026, 11, 16));

Future<void> _pumpNotesPage(WidgetTester tester, List<Note> items) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(_FakeNoteRepository(items)),
      ],
      child: const MaterialApp(home: NotesPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final items = <Note>[
    _note('Belanja mingguan', id: 1),
    _note('Tugas Mobile', id: 2),
  ];

  testWidgets('mengetik query menyaring daftar catatan', (tester) async {
    await _pumpNotesPage(tester, items);
    expect(find.text('Belanja mingguan'), findsOneWidget);
    expect(find.text('Tugas Mobile'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'tugas');
    await tester.pumpAndSettle();

    expect(find.text('Tugas Mobile'), findsOneWidget);
    expect(find.text('Belanja mingguan'), findsNothing);
  });

  testWidgets('query tanpa hasil menampilkan empty state dan bisa dihapus', (
    tester,
  ) async {
    await _pumpNotesPage(tester, items);

    await tester.enterText(find.byType(TextField), 'zzz-tak-ada');
    await tester.pumpAndSettle();

    expect(find.textContaining('Tidak ada catatan yang cocok'), findsOneWidget);
    expect(find.text('Belanja mingguan'), findsNothing);

    await tester.tap(find.text('Hapus filter'));
    await tester.pumpAndSettle();

    expect(find.text('Belanja mingguan'), findsOneWidget);
    expect(find.text('Tugas Mobile'), findsOneWidget);
  });

  testWidgets('daftar kosong menampilkan pesan belum ada catatan', (
    tester,
  ) async {
    await _pumpNotesPage(tester, const []);

    expect(find.text('Belum ada catatan'), findsOneWidget);
  });
}
