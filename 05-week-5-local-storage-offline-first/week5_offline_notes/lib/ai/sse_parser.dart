/// Parser Server-Sent Events (SSE) untuk balasan streaming Gemini.
///
/// Gemini mengirim satu baris `data: {json}` per potongan. Parser dibuat
/// toleran: baris kosong, komentar `:` (keep-alive), JSON rusak, dan chunk tanpa
/// teks dilewati tanpa melempar exception, karena satu chunk rusak tidak boleh
/// membatalkan seluruh jawaban.
library;

import 'dart:convert';

class SseParser {
  static const String _dataPrefix = 'data:';

  /// Mengubah satu baris mentah menjadi delta teks, atau `null` bila baris
  /// tersebut tidak memuat teks yang bisa ditampilkan.
  String? parseLine(String rawLine) {
    final line = rawLine.trim();
    if (line.isEmpty || !line.startsWith(_dataPrefix)) return null;

    final payload = line.substring(_dataPrefix.length).trim();
    if (payload.isEmpty || payload == '[DONE]') return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final first = candidates.first;
    if (first is! Map) return null;
    final content = first['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List) return null;

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text'] as String);
      }
    }
    final text = buffer.toString();
    return text.isEmpty ? null : text;
  }

  /// Memfilter aliran baris menjadi aliran delta teks.
  Stream<String> parse(Stream<String> lines) async* {
    await for (final line in lines) {
      final delta = parseLine(line);
      if (delta != null) yield delta;
    }
  }
}
