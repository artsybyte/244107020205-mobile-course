import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/note_search.dart';
import 'package:week5_offline_notes/data/local/note.dart';

Note _note(String title, {int? id}) =>
    Note(id: id, title: title, updatedAt: DateTime(2026, 11, 16));

void main() {
  final notes = <Note>[
    _note('Belanja mingguan', id: 1),
    _note('belanja bulanan', id: 2),
    _note('Tugas Mobile', id: 3),
  ];

  group('searchNotes', () {
    test('query kosong mengembalikan semua catatan', () {
      expect(searchNotes(notes, ''), hasLength(3));
    });

    test('query berisi spasi saja dianggap kosong', () {
      expect(searchNotes(notes, '   '), hasLength(3));
    });

    test('mencocokkan sebagian judul', () {
      expect(searchNotes(notes, 'Mobile'), hasLength(1));
    });

    test('mengabaikan huruf besar/kecil', () {
      expect(searchNotes(notes, 'belanja'), hasLength(2));
    });

    test('mengabaikan spasi di awal dan akhir query', () {
      expect(searchNotes(notes, '  tugas  '), hasLength(1));
    });

    test('query tanpa hasil mengembalikan list kosong', () {
      expect(searchNotes(notes, 'zzz-tak-ada'), isEmpty);
    });

    test('urutan catatan tidak berubah setelah difilter', () {
      final result = searchNotes(notes, 'belanja');
      expect(result.map((n) => n.id), [1, 2]);
    });

    test('list kosong tetap kosong', () {
      expect(searchNotes(const [], 'apa pun'), isEmpty);
    });
  });
}
