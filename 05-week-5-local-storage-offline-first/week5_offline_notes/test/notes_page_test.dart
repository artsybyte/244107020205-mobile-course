import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/note_providers.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

/// Repository yang gagal saat menyimpan, untuk menguji jalur error di UI.
class _FailingAddNoteRepository extends NoteRepository {
  _FailingAddNoteRepository() : super(openDb: () => throw UnimplementedError());

  @override
  Future<List<Note>> fetchNotes() async => const [];

  @override
  Future<int> countDirty() async => 0;

  @override
  Future<Note> addNote({required String title, String body = ''}) async {
    throw Exception('database penuh');
  }
}

void main() {
  testWidgets('SnackBar muncul ketika penyimpanan catatan gagal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(_FailingAddNoteRepository()),
        ],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Catatan uji');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gagal menyimpan catatan'), findsOneWidget);
  });
}
