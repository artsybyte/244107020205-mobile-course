/// Pencocokan kata kunci lokal terhadap catatan.
///
/// Dipakai dua tempat sekaligus: klien demo (tanpa API key) dan mode offline
/// saat AI API gagal. Karena keduanya berbagi fungsi yang sama, jawaban offline
/// tidak pernah "mengarang" - isinya benar-benar berasal dari catatan pengguna.
library;

import '../data/local/note.dart';

/// Kata yang terlalu umum untuk dijadikan kata kunci pencarian.
const Set<String> _stopwords = {
  'yang',
  'apa',
  'apakah',
  'saya',
  'aku',
  'di',
  'ke',
  'dari',
  'dan',
  'atau',
  'ada',
  'adalah',
  'itu',
  'ini',
  'untuk',
  'dengan',
  'pada',
  'dalam',
  'tentang',
  'catatan',
  'note',
  'notes',
  'tolong',
  'bisa',
  'kah',
  'nya',
  'punya',
  'semua',
  'jelaskan',
  'sebutkan',
  'ringkas',
  'ringkasan',
  'terbaru',
};

/// Memecah pertanyaan menjadi kata kunci yang layak dicari.
List<String> extractKeywords(String question) {
  final cleaned = question
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'));
  return cleaned
      .where((word) => word.length >= 3 && !_stopwords.contains(word))
      .toSet()
      .toList(growable: false);
}

/// Catatan yang judul atau isinya memuat minimal satu kata kunci.
///
/// Judul diberi bobot 2 dan isi bobot 1, lalu hasil diurutkan menurun supaya
/// catatan yang paling relevan muncul lebih dulu.
List<Note> findRelevantNotes(
  List<Note> notes,
  String question, {
  int limit = 3,
}) {
  final keywords = extractKeywords(question);
  if (keywords.isEmpty) return const [];

  final scored = <({Note note, int score})>[];
  for (final note in notes) {
    final title = note.title.toLowerCase();
    final body = note.body.toLowerCase();
    var score = 0;
    for (final keyword in keywords) {
      if (title.contains(keyword)) score += 2;
      if (body.contains(keyword)) score += 1;
    }
    if (score > 0) scored.add((note: note, score: score));
  }

  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored.take(limit).map((entry) => entry.note).toList(growable: false);
}

/// Jawaban yang seluruhnya dibangun dari data lokal.
///
/// Dipakai klien demo dan mode offline. Maksimal dua kalimat agar konsisten
/// dengan batas pada system prompt.
String buildLocalAnswer({required String question, required List<Note> notes}) {
  final trimmed = question.trim();
  if (notes.isEmpty) {
    return 'Belum ada catatan yang bisa saya baca. Tambahkan catatan dulu, '
        'lalu tanyakan lagi.';
  }

  final matches = findRelevantNotes(notes, trimmed);
  if (matches.isEmpty) {
    return 'Saya tidak menemukan catatan yang membahas "$trimmed" dari '
        '${notes.length} catatan yang tersimpan. Coba sebutkan kata kunci lain.';
  }

  final titles = matches.map((note) => note.title).join(', ');
  final first = matches.first;
  final snippet = _firstSentence(first.body);
  final detail = snippet.isEmpty ? '' : ' Catatan pertama: $snippet';
  return 'Ada ${matches.length} catatan yang cocok dengan "$trimmed": '
      '$titles.$detail';
}

/// Kalimat pertama dari isi catatan.
///
/// Tanda akhir kalimat hanya dianggap batas bila diikuti spasi/akhir teks,
/// sehingga "pukul 10.00" tidak terpotong menjadi "pukul 10.".
String _firstSentence(String body) {
  final trimmed = body.trim();
  if (trimmed.isEmpty) return '';
  final end = trimmed.indexOf(RegExp(r'[.!?\n](?=\s|$)'));
  if (end <= 0) {
    return trimmed.length > 120 ? '${trimmed.substring(0, 120)}...' : trimmed;
  }
  return trimmed.substring(0, end + 1).trim();
}
