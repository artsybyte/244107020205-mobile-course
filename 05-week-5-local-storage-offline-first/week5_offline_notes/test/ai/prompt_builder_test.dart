import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/ai/privacy_filter.dart';
import 'package:week5_offline_notes/ai/prompt_builder.dart';
import 'package:week5_offline_notes/data/local/note.dart';

Note _note(String title, {String body = '', int day = 1}) =>
    Note(title: title, body: body, updatedAt: DateTime(2026, 11, day));

void main() {
  group('PromptBuilder.buildContext', () {
    test('menuliskan judul dan isi catatan berurutan', () {
      final context = PromptBuilder.buildContext([
        _note('Tugas Mobile', body: 'Kumpulkan Jumat'),
        _note('Belanja', body: 'Telur dan beras'),
      ]);

      expect(context, contains('1. Tugas Mobile'));
      expect(context, contains('2. Belanja'));
      expect(context, contains('Kumpulkan Jumat'));
    });

    test('memberi penanda saat belum ada catatan', () {
      expect(
        PromptBuilder.buildContext(const []),
        'Konteks catatan: (belum ada catatan)',
      );
    });

    test('membatasi jumlah catatan sesuai maxNotes', () {
      final notes = [
        for (var i = 0; i < 5; i++) _note('Catatan $i', day: i + 1),
      ];

      final context = PromptBuilder.buildContext(notes, maxNotes: 2);

      expect(context, contains('Catatan 0'));
      expect(context, contains('Catatan 1'));
      expect(context, isNot(contains('Catatan 2')));
    });

    test('memotong isi catatan yang panjang', () {
      final longBody = 'a' * 300;

      final context = PromptBuilder.buildContext([
        _note('Panjang', body: longBody),
      ], maxBodyChars: 20);

      expect(context, contains('...'));
      expect(context.length, lessThan(300));
    });

    test('menyamarkan data pribadi di judul dan isi', () {
      final context = PromptBuilder.buildContext([
        _note('Kontak a@b.com', body: 'NIK 3507123456789012 HP 081234567890'),
      ]);

      expect(context, isNot(contains('a@b.com')));
      expect(context, isNot(contains('3507123456789012')));
      expect(context, isNot(contains('081234567890')));
      expect(context, contains(PrivacyFilter.emailMask));
    });
  });

  group('PromptBuilder.buildUserPrompt', () {
    test('menggabungkan konteks dan pertanyaan', () {
      final prompt = PromptBuilder.buildUserPrompt(
        question: 'Tugas apa yang menunggu?',
        notes: [_note('Tugas Mobile', body: 'Kumpulkan Jumat')],
      );

      expect(prompt, contains('Konteks catatan:'));
      expect(prompt, contains('Tugas Mobile'));
      expect(prompt, contains('Pertanyaan: Tugas apa yang menunggu?'));
    });

    test('menyamarkan data pribadi pada pertanyaan', () {
      final prompt = PromptBuilder.buildUserPrompt(
        question: 'Kirim ke marta@example.com ya',
        notes: const [],
      );

      expect(prompt, isNot(contains('marta@example.com')));
      expect(prompt, contains(PrivacyFilter.emailMask));
    });

    test('memotong pertanyaan yang terlalu panjang', () {
      final prompt = PromptBuilder.buildUserPrompt(
        question: 'x' * 900,
        notes: const [],
        maxQuestionChars: 50,
      );

      expect(prompt, contains('Pertanyaan: ${'x' * 50}...'));
    });

    test('system prompt membatasi dua kalimat dan bahasa Indonesia', () {
      expect(PromptBuilder.systemPrompt, contains('Bahasa Indonesia'));
      expect(PromptBuilder.systemPrompt, contains('2 kalimat'));
    });
  });
}
