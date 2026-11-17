/// Klien AI tanpa jaringan.
///
/// Dipakai saat mode demo aktif atau API key belum diisi. Jawabannya dibangun
/// dari catatan lokal, lalu dialirkan bertahap agar UI tetap bisa menguji
/// keadaan streaming. Tidak ada data yang keluar dari perangkat.
library;

import 'ai_client.dart';
import 'local_answer.dart';

class DemoAiClient implements AiClient {
  DemoAiClient({this.chunkDelay = const Duration(milliseconds: 40)});

  /// Jeda antar potongan. Test memakai `Duration.zero` agar cepat.
  final Duration chunkDelay;

  @override
  String get label => 'Mode demo (tanpa API key)';

  @override
  Stream<String> streamAnswer(AiRequest request) async* {
    final answer = buildLocalAnswer(
      question: request.question,
      notes: request.notes,
    );
    for (final chunk in splitIntoChunks(answer)) {
      if (chunkDelay > Duration.zero) await Future<void>.delayed(chunkDelay);
      yield chunk;
    }
  }
}

/// Memecah jawaban menjadi potongan per kata (spasi ikut di belakang) supaya
/// penggabungan kembali menghasilkan teks yang identik.
List<String> splitIntoChunks(String text) {
  final chunks = <String>[];
  final words = text.split(' ');
  for (var i = 0; i < words.length; i++) {
    chunks.add(i == words.length - 1 ? words[i] : '${words[i]} ');
  }
  return chunks;
}
