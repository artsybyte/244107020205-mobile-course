/// Kontrak klien AI.
///
/// UI dan controller hanya bergantung pada antarmuka ini, sehingga klien palsu
/// (demo) dan klien nyata (Gemini) bisa ditukar tanpa mengubah widget maupun
/// test.
library;

import '../data/local/note.dart';

/// Satu permintaan ke AI: prompt siap kirim + catatan asli.
///
/// [notes] ikut dibawa karena klien demo menjawab langsung dari data lokal
/// tanpa memanggil jaringan.
class AiRequest {
  const AiRequest({
    required this.question,
    required this.systemPrompt,
    required this.userPrompt,
    required this.notes,
  });

  final String question;
  final String systemPrompt;
  final String userPrompt;
  final List<Note> notes;
}

abstract class AiClient {
  /// Nama yang ditampilkan di UI, mis. `Mode demo` atau `Gemini`.
  String get label;

  /// Aliran potongan jawaban. Setiap elemen adalah delta teks, bukan teks
  /// kumulatif, sehingga UI tinggal menambahkan ke balon yang sedang aktif.
  Stream<String> streamAnswer(AiRequest request);
}

/// Kegagalan yang sudah diterjemahkan menjadi pesan siap tampil.
class AiException implements Exception {
  const AiException(this.message, {this.retryable = true});

  final String message;

  /// `false` untuk kesalahan yang tidak akan pulih dengan mencoba ulang
  /// (mis. API key ditolak), sehingga tombol "Coba lagi" tidak ditampilkan.
  final bool retryable;

  @override
  String toString() => message;
}
