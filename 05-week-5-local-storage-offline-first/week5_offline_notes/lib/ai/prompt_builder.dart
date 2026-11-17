/// Perakitan prompt untuk AI API.
///
/// Semua keputusan prompt (persona, batas panjang, pemotongan konteks, dan
/// penyaringan data pribadi) ada di satu berkas murni supaya bisa diuji tanpa
/// jaringan maupun widget.
library;

import '../data/local/note.dart';
import 'ai_config.dart';
import 'privacy_filter.dart';

class PromptBuilder {
  const PromptBuilder._();

  /// System prompt: menetapkan persona, bahasa, dan batas jawaban.
  static const String systemPrompt =
      'Kamu asisten catatan pribadi yang ramah. '
      'Jawab dalam Bahasa Indonesia dengan maksimal 2 kalimat. '
      'Jawab hanya berdasarkan konteks catatan yang diberikan. '
      'Bila konteks tidak memuat jawabannya, katakan terus terang bahwa '
      'catatan tidak menyebutkannya, lalu tawarkan kata kunci lain. '
      'Jangan pernah mengarang isi catatan dan jangan menampilkan NIK, '
      'nomor telepon, atau email.';

  /// Catatan yang ikut sebagai konteks: [maxNotes] terbaru.
  ///
  /// Repository sudah mengurutkan `updated_at DESC`, jadi cukup ambil dari
  /// depan tanpa mengurutkan ulang.
  static List<Note> selectNotes(
    List<Note> notes, {
    int maxNotes = AiConfig.maxContextNotes,
  }) {
    if (notes.length <= maxNotes) return notes;
    return notes.take(maxNotes).toList(growable: false);
  }

  /// Blok konteks yang ditempel ke prompt pengguna.
  static String buildContext(
    List<Note> notes, {
    int maxNotes = AiConfig.maxContextNotes,
    int maxBodyChars = AiConfig.maxBodyChars,
  }) {
    final selected = selectNotes(notes, maxNotes: maxNotes);
    if (selected.isEmpty) return 'Konteks catatan: (belum ada catatan)';

    final buffer = StringBuffer('Konteks catatan:');
    for (var i = 0; i < selected.length; i++) {
      final note = selected[i];
      final title = PrivacyFilter.redact(note.title.trim());
      final body = PrivacyFilter.redact(_clip(note.body.trim(), maxBodyChars));
      buffer.write('\n${i + 1}. $title');
      if (body.isNotEmpty) buffer.write('\n   $body');
    }
    return buffer.toString();
  }

  /// Prompt pengguna = konteks + pertanyaan yang sudah disamarkan.
  static String buildUserPrompt({
    required String question,
    required List<Note> notes,
    int maxNotes = AiConfig.maxContextNotes,
    int maxBodyChars = AiConfig.maxBodyChars,
    int maxQuestionChars = AiConfig.maxQuestionChars,
  }) {
    final context = buildContext(
      notes,
      maxNotes: maxNotes,
      maxBodyChars: maxBodyChars,
    );
    final safeQuestion = PrivacyFilter.redact(
      _clip(question.trim(), maxQuestionChars),
    );
    return '$context\n\nPertanyaan: $safeQuestion';
  }

  static String _clip(String value, int maxChars) {
    if (value.length <= maxChars) return value;
    return '${value.substring(0, maxChars).trimRight()}...';
  }
}
