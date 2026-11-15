import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/note_validator.dart';

void main() {
  group('validateNoteTitle', () {
    test('menolak null dan string kosong', () {
      expect(validateNoteTitle(null), 'Judul tidak boleh kosong');
      expect(validateNoteTitle(''), 'Judul tidak boleh kosong');
    });

    test('menolak judul yang hanya berisi spasi', () {
      expect(validateNoteTitle('   '), 'Judul tidak boleh kosong');
      expect(validateNoteTitle('\n\t '), 'Judul tidak boleh kosong');
    });

    test('menerima judul yang valid', () {
      expect(validateNoteTitle('Belanja'), isNull);
      expect(validateNoteTitle('  Catatan kuliah  '), isNull);
    });

    test('menerima judul tepat pada batas panjang', () {
      final title = 'a' * maxNoteTitleLength;
      expect(validateNoteTitle(title), isNull);
    });

    test('menolak judul melebihi batas panjang', () {
      final title = 'a' * (maxNoteTitleLength + 1);
      expect(
        validateNoteTitle(title),
        'Judul maksimal $maxNoteTitleLength karakter',
      );
    });
  });

  group('normalizeNoteTitle', () {
    test('memangkas spasi di awal dan akhir', () {
      expect(normalizeNoteTitle('  Belanja  '), 'Belanja');
    });
  });
}
