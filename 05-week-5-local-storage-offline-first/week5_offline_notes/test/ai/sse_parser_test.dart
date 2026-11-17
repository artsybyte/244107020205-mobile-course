import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/ai/sse_parser.dart';

void main() {
  final parser = SseParser();

  group('SseParser.parseLine', () {
    test('mengambil teks dari chunk Gemini yang valid', () {
      const line =
          'data: {"candidates":[{"content":{"parts":[{"text":"Halo"}]}}]}';

      expect(parser.parseLine(line), 'Halo');
    });

    test('menggabungkan beberapa part dalam satu chunk', () {
      const line =
          'data: {"candidates":[{"content":{"parts":[{"text":"Ha"},{"text":"lo"}]}}]}';

      expect(parser.parseLine(line), 'Halo');
    });

    test('mengabaikan baris kosong, komentar, dan penanda [DONE]', () {
      expect(parser.parseLine(''), isNull);
      expect(parser.parseLine(': keep-alive'), isNull);
      expect(parser.parseLine('data: [DONE]'), isNull);
      expect(parser.parseLine('event: ping'), isNull);
    });

    test('mengembalikan null untuk JSON rusak tanpa melempar exception', () {
      expect(parser.parseLine('data: {bukan json'), isNull);
    });

    test('mengembalikan null bila chunk tidak memuat teks', () {
      expect(
        parser.parseLine('data: {"candidates":[{"finishReason":"STOP"}]}'),
        isNull,
      );
      expect(parser.parseLine('data: {"candidates":[]}'), isNull);
      expect(parser.parseLine('data: {"error":{"code":500}}'), isNull);
    });
  });

  group('SseParser.parse', () {
    test('menghasilkan delta hanya dari baris yang berisi teks', () async {
      final lines = Stream.fromIterable([
        'data: {"candidates":[{"content":{"parts":[{"text":"Satu"}]}}]}',
        '',
        'data: {"candidates":[{"content":{"parts":[{"text":" dua"}]}}]}',
        'data: [DONE]',
      ]);

      expect(await parser.parse(lines).toList(), ['Satu', ' dua']);
    });
  });
}
