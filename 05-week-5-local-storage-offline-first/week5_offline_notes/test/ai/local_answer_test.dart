import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/ai/ai_client.dart';
import 'package:week5_offline_notes/ai/demo_client.dart';
import 'package:week5_offline_notes/ai/local_answer.dart';
import 'package:week5_offline_notes/data/local/note.dart';

Note _note(String title, {String body = ''}) =>
    Note(title: title, body: body, updatedAt: DateTime(2026, 11, 17));

void main() {
  group('extractKeywords', () {
    test('membuang kata umum dan tanda baca', () {
      expect(
        extractKeywords('Apa catatan tentang tugas mobile?'),
        containsAll(['tugas', 'mobile']),
      );
    });

    test('mengembalikan daftar kosong untuk pertanyaan tanpa kata kunci', () {
      expect(extractKeywords('apa itu?'), isEmpty);
    });
  });

  group('findRelevantNotes', () {
    test('mengutamakan catatan yang cocok di judul', () {
      final notes = [
        _note('Belanja mingguan', body: 'tugas rumah'),
        _note('Tugas Mobile'),
      ];

      final result = findRelevantNotes(notes, 'tugas');

      expect(result.first.title, 'Tugas Mobile');
      expect(result, hasLength(2));
    });

    test('mengembalikan kosong bila tidak ada yang cocok', () {
      expect(findRelevantNotes([_note('Belanja')], 'kriptografi'), isEmpty);
    });
  });

  group('buildLocalAnswer', () {
    test('menyebut jumlah dan judul catatan yang cocok', () {
      final answer = buildLocalAnswer(
        question: 'tugas',
        notes: [_note('Tugas Mobile', body: 'Kumpulkan Jumat. Bawa laptop.')],
      );

      expect(answer, contains('1 catatan'));
      expect(answer, contains('Tugas Mobile'));
      expect(answer, contains('Kumpulkan Jumat.'));
    });

    test('jujur saat catatan masih kosong', () {
      final answer = buildLocalAnswer(question: 'tugas', notes: const []);

      expect(answer, contains('Belum ada catatan'));
    });

    test('tidak memotong kalimat pada titik desimal seperti 10.00', () {
      final answer = buildLocalAnswer(
        question: 'tugas',
        notes: [
          _note(
            'Tugas Mobile',
            body: 'Kumpulkan laporan Jumat pukul 10.00 di lab. Bawa laptop.',
          ),
        ],
      );

      expect(answer, contains('pukul 10.00 di lab.'));
      expect(answer, isNot(contains('Bawa laptop')));
    });

    test('menawarkan kata kunci lain saat tidak ada yang cocok', () {
      final answer = buildLocalAnswer(
        question: 'kriptografi',
        notes: [_note('Belanja')],
      );

      expect(answer, contains('tidak menemukan'));
      expect(answer, contains('kata kunci lain'));
    });
  });

  group('DemoAiClient', () {
    test('mengalirkan jawaban bertahap dan bisa digabung utuh', () async {
      final client = DemoAiClient(chunkDelay: Duration.zero);

      final chunks = await client
          .streamAnswer(
            AiRequest(
              question: 'tugas',
              systemPrompt: '',
              userPrompt: '',
              notes: [_note('Tugas Mobile')],
            ),
          )
          .toList();

      expect(chunks.length, greaterThan(1));
      expect(chunks.join(), contains('Tugas Mobile'));
    });

    test('splitIntoChunks mempertahankan teks asli saat digabung', () {
      const text = 'Ada satu catatan yang cocok.';

      expect(splitIntoChunks(text).join(), text);
    });
  });
}
