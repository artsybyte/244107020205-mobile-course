import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/ai/privacy_filter.dart';

void main() {
  group('PrivacyFilter.redact', () {
    test('menyamarkan email', () {
      final result = PrivacyFilter.redact('Hubungi marta@example.com besok');

      expect(result, contains(PrivacyFilter.emailMask));
      expect(result, isNot(contains('marta@example.com')));
    });

    test('menyamarkan NIK 16 digit', () {
      final result = PrivacyFilter.redact('NIK: 3507123456789012');

      expect(result, contains(PrivacyFilter.nikMask));
      expect(result, isNot(contains('3507123456789012')));
    });

    test('menyamarkan nomor telepon format 08, 62, dan +62', () {
      const input = 'HP 081234567890, WA 6281234567890, kantor +62341234567';
      final result = PrivacyFilter.redact(input);

      expect(result, isNot(contains('081234567890')));
      expect(result, isNot(contains('6281234567890')));
      expect(result, isNot(contains('+62341234567')));
      expect(PrivacyFilter.phoneMask, isNotEmpty);
    });

    test('NIK yang diawali 08 tidak dipotong menjadi nomor telepon', () {
      final result = PrivacyFilter.redact('0812345678901234');

      expect(result, PrivacyFilter.nikMask);
    });

    test('teks tanpa data sensitif tidak berubah', () {
      const input = 'Tugas Mobile dikumpulkan Jumat pukul 10.00';

      expect(PrivacyFilter.redact(input), input);
    });
  });

  group('PrivacyFilter.findings', () {
    test('melaporkan jenis data yang ditemukan', () {
      const input = 'Email a@b.com, NIK 3507123456789012, HP 081234567890';

      expect(
        PrivacyFilter.findings(input),
        containsAll(['email', 'NIK', 'nomor telepon']),
      );
    });

    test('mengembalikan daftar kosong bila aman', () {
      expect(PrivacyFilter.findings('belanja mingguan'), isEmpty);
      expect(PrivacyFilter.containsSensitiveData('belanja mingguan'), isFalse);
    });
  });
}
