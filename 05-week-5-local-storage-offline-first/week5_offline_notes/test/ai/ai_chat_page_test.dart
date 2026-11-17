import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:week5_offline_notes/ai/ai_cache.dart';
import 'package:week5_offline_notes/ai/ai_client.dart';
import 'package:week5_offline_notes/ai/ai_providers.dart';
import 'package:week5_offline_notes/ai/ai_quota.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/note_providers.dart';
import 'package:week5_offline_notes/pages/ai_chat_page.dart';

class _FakeAiClient implements AiClient {
  _FakeAiClient({this.error});

  final AiException? error;

  @override
  String get label => 'fake';

  @override
  Stream<String> streamAnswer(AiRequest request) async* {
    if (error != null) throw error!;
    yield 'Ada satu ';
    yield 'catatan tentang tugas.';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final notes = [
    Note(
      title: 'Tugas Mobile',
      body: 'Kumpulkan Jumat.',
      updatedAt: DateTime(2026, 11, 17),
    ),
  ];

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpPage(WidgetTester tester, _FakeAiClient client) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notesProvider.overrideWith((ref) async => notes),
          aiClientProvider.overrideWith((ref) async => client),
          aiCacheProvider.overrideWithValue(
            AiCache(prefs: prefs, now: () => DateTime(2026, 11, 17)),
          ),
          aiQuotaProvider.overrideWithValue(
            AiQuota(prefs: prefs, now: () => DateTime(2026, 11, 17)),
          ),
        ],
        child: const MaterialApp(home: AiChatPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('layar awal menampilkan pengingat privasi dan chip saran', (
    tester,
  ) async {
    await pumpPage(tester, _FakeAiClient());

    expect(find.text('Tanya Catatan'), findsOneWidget);
    expect(find.textContaining('disamarkan sebelum dikirim'), findsOneWidget);
    expect(find.text('Catatan tentang tugas?'), findsOneWidget);
    expect(find.text('Tanya apa saja tentang catatan Anda'), findsOneWidget);
  });

  testWidgets('mengirim pertanyaan menampilkan balon pengguna dan jawaban', (
    tester,
  ) async {
    await pumpPage(tester, _FakeAiClient());

    await tester.enterText(find.byType(TextField), 'tugas apa saja?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('tugas apa saja?'), findsOneWidget);
    expect(find.text('Ada satu catatan tentang tugas.'), findsOneWidget);
    expect(find.text('dari cache lokal'), findsNothing);
  });

  testWidgets('chip saran langsung mengirim pertanyaan', (tester) async {
    await pumpPage(tester, _FakeAiClient());

    await tester.tap(find.text('Catatan tentang tugas?'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan tentang tugas?'), findsOneWidget);
    expect(find.text('Ada satu catatan tentang tugas.'), findsOneWidget);
  });

  testWidgets('error menampilkan banner fallback dan mode offline berfungsi', (
    tester,
  ) async {
    await pumpPage(
      tester,
      _FakeAiClient(error: const AiException('Layanan AI sedang sibuk (503).')),
    );

    await tester.enterText(find.byType(TextField), 'tugas');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Layanan AI Sibuk'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('Mode offline'), findsOneWidget);

    await tester.tap(find.text('Mode offline'));
    await tester.pumpAndSettle();

    expect(find.text('Layanan AI Sibuk'), findsNothing);
    expect(find.textContaining('Mode offline:'), findsOneWidget);
    expect(find.textContaining('Tugas Mobile'), findsOneWidget);
  });
}
