/// Penyaring data pribadi sebelum teks dikirim ke penyedia AI.
///
/// Fungsi murni tanpa import Flutter agar bisa diuji langsung. Prinsipnya:
/// data sensitif tidak dilarang masuk ke catatan lokal (aplikasi ini offline
/// first), tetapi **tidak boleh** ikut terkirim ke pihak ketiga. Karena itu
/// penyaringan dilakukan di satu tempat, tepat sebelum prompt dibentuk.
library;

class PrivacyFilter {
  const PrivacyFilter._();

  static const String nikMask = '[NIK]';
  static const String phoneMask = '[nomor telepon]';
  static const String emailMask = '[email]';

  /// NIK = 16 digit. Batas `[0-9]` dipakai (bukan `\b`) supaya angka yang
  /// menempel pada tanda baca seperti `NIK:3507...` tetap tertangkap.
  static final RegExp _nik = RegExp(r'(?<![0-9])[0-9]{16}(?![0-9])');

  /// Nomor Indonesia (seluler maupun rumah): `08xx`, `628xx`, atau `+628xx`.
  ///
  /// Pola sengaja tidak mensyaratkan awalan `8` setelah kode negara agar nomor
  /// rumah seperti `+62341234567` ikut tersamarkan.
  static final RegExp _phone = RegExp(r'(?:\+62|62|0)[0-9]{8,12}(?![0-9])');

  static final RegExp _email = RegExp(
    r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
  );

  /// Mengganti email, NIK, lalu nomor telepon dengan penanda netral.
  ///
  /// Urutan penting: email lebih dulu (mengandung `@`), lalu NIK (16 digit),
  /// baru nomor telepon. NIK yang kebetulan diawali `08` harus tertangkap
  /// sebagai NIK, bukan sebagai nomor telepon yang lebih pendek.
  static String redact(String text) {
    return text
        .replaceAll(_email, emailMask)
        .replaceAll(_nik, nikMask)
        .replaceAll(_phone, phoneMask);
  }

  /// Daftar jenis data sensitif yang ditemukan, dipakai untuk memberi tahu
  /// pengguna bahwa isi catatan telah disamarkan sebelum dikirim.
  static List<String> findings(String text) {
    final found = <String>[];
    if (_email.hasMatch(text)) found.add('email');
    if (_nik.hasMatch(text)) found.add('NIK');
    if (_phone.hasMatch(text)) found.add('nomor telepon');
    return found;
  }

  static bool containsSensitiveData(String text) => findings(text).isNotEmpty;
}
