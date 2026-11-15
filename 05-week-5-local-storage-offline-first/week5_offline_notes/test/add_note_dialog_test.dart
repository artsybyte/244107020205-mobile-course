import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/widgets/add_note_dialog.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('judul kosong ditolak dan dialog tetap terbuka', (tester) async {
    NoteDraft? result;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await AddNoteDialog.show(context);
            },
            child: const Text('buka'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Judul tidak boleh kosong'), findsOneWidget);
    // Dialog tidak boleh tertutup sebelum input valid.
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('judul berisi spasi saja ditolak', (tester) async {
    await tester.pumpWidget(_host(const AddNoteDialog()));

    await tester.enterText(find.byType(TextFormField), '    ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Judul tidak boleh kosong'), findsOneWidget);
  });

  testWidgets('judul valid mengembalikan draft yang sudah di-trim', (
    tester,
  ) async {
    NoteDraft? result;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await AddNoteDialog.show(context);
            },
            child: const Text('buka'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '  Belanja  ');
    await tester.enterText(find.byType(TextField).last, '  susu  ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(result?.title, 'Belanja');
    expect(result?.body, 'susu');
  });
}
