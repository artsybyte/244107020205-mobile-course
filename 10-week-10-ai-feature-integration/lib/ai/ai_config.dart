/// Konfigurasi lapisan AI: model, endpoint, dan batas pemakaian.
///
/// Semua angka yang membatasi biaya dan ukuran request dikumpulkan di sini
/// supaya mudah diaudit tanpa membaca seluruh kode fitur.
library;

class AiConfig {
  const AiConfig._();

  /// Codelab menyebut `gemini-pro`, tetapi model itu sudah tidak dilayani
  /// `v1beta` (respons 404). `gemini-2.5-flash` dipilih karena murah, cepat,
  /// dan mendukung streaming SSE.
  static const String model = 'gemini-2.5-flash';

  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Endpoint streaming Gemini memakai `alt=sse` agar balasan datang bertahap.
  static Uri streamUri({String model = AiConfig.model}) =>
      Uri.parse('$baseUrl/models/$model:streamGenerateContent?alt=sse');

  /// Maksimal catatan yang ikut dikirim sebagai konteks.
  static const int maxContextNotes = 10;

  /// Isi catatan dipotong agar prompt tidak membengkak (biaya per token).
  static const int maxBodyChars = 160;

  /// Pertanyaan pengguna dipotong sebelum dikirim.
  static const int maxQuestionChars = 500;

  /// Batas request per pengguna per hari.
  static const int dailyRequestLimit = 30;
}
