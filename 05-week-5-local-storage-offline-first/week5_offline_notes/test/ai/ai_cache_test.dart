import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:week5_offline_notes/ai/ai_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AiCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cache = AiCache(prefs: prefs, now: () => DateTime(2026, 11, 17, 9));
  });

  group('cacheKeyFor', () {
    test('deterministik untuk pertanyaan yang sama', () {
      expect(
        AiCache.cacheKeyFor('Apa tugas saya?', '2@x'),
        AiCache.cacheKeyFor('Apa tugas saya?', '2@x'),
      );
    });

    test('mengabaikan kapitalisasi dan spasi berlebih', () {
      expect(
        AiCache.cacheKeyFor('  Apa   Tugas ', '1@x'),
        AiCache.cacheKeyFor('apa tugas', '1@x'),
      );
    });

    test('berbeda saat sidik jari catatan berubah', () {
      expect(
        AiCache.cacheKeyFor('apa tugas', '1@x'),
        isNot(AiCache.cacheKeyFor('apa tugas', '2@y')),
      );
    });
  });

  group('read/write', () {
    test('mengembalikan null saat belum ada jawaban', () async {
      expect(await cache.read('apa tugas', '1@x'), isNull);
    });

    test('menyimpan lalu membaca jawaban yang sama', () async {
      await cache.write('apa tugas', '1@x', 'Tugas Mobile dikumpulkan Jumat.');

      expect(
        await cache.read('apa tugas', '1@x'),
        'Tugas Mobile dikumpulkan Jumat.',
      );
    });

    test('tidak menyimpan jawaban kosong', () async {
      await cache.write('apa tugas', '1@x', '   ');

      expect(await cache.entryCount(), 0);
    });

    test('cache lama tidak dipakai saat sidik jari berubah', () async {
      await cache.write('apa tugas', '1@x', 'Jawaban lama');

      expect(await cache.read('apa tugas', '2@y'), isNull);
    });

    test('clear menghapus seluruh entri cache', () async {
      await cache.write('satu', '1@x', 'A');
      await cache.write('dua', '1@x', 'B');

      await cache.clear();

      expect(await cache.entryCount(), 0);
      expect(await cache.read('satu', '1@x'), isNull);
    });

    test('menyisakan maksimal maxEntries entri terbaru', () async {
      for (var i = 0; i < AiCache.maxEntries + 5; i++) {
        await cache.write('pertanyaan $i', '1@x', 'jawaban $i');
      }

      expect(await cache.entryCount(), lessThanOrEqualTo(AiCache.maxEntries));
    });
  });

  group('notesFingerprint', () {
    test('berubah saat ada catatan baru atau waktu update berubah', () {
      final base = notesFingerprint([DateTime(2026, 11, 16)]);

      expect(notesFingerprint([DateTime(2026, 11, 16)]), base);
      expect(notesFingerprint([DateTime(2026, 11, 17)]), isNot(base));
      expect(
        notesFingerprint([DateTime(2026, 11, 16), DateTime(2026, 11, 16)]),
        isNot(base),
      );
    });

    test('aman untuk daftar kosong', () {
      expect(notesFingerprint(const []), '0');
    });
  });
}
