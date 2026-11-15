/// Aturan validasi judul catatan.
///
/// Fungsi ini murni (tanpa import Flutter) sehingga bisa diuji sebagai unit
/// test biasa dan dipakai ulang oleh widget mana pun.
library;

/// Batas panjang judul yang masih wajar untuk ditampilkan pada daftar catatan.
const int maxNoteTitleLength = 80;

/// Mengembalikan pesan error bila [raw] tidak valid, atau `null` bila valid.
///
/// Judul dianggap valid bila setelah di-`trim` tidak kosong dan panjangnya
/// tidak melebihi [maxNoteTitleLength].
///
/// Catatan desain: `TextFormField` sudah membatasi input dengan `maxLength`,
/// tetapi pemeriksaan panjang di sini tetap dipertahankan. `maxLength` adalah
/// lapis UX (pengguna tidak bisa mengetik lebih), sedangkan fungsi ini adalah
/// kontrak aturan bisnis yang juga dipakai di luar widget dan diuji langsung.
String? validateNoteTitle(String? raw) {
  final title = raw?.trim() ?? '';
  if (title.isEmpty) {
    return 'Judul tidak boleh kosong';
  }
  if (title.length > maxNoteTitleLength) {
    return 'Judul maksimal $maxNoteTitleLength karakter';
  }
  return null;
}

/// Membersihkan judul sebelum disimpan.
///
/// Dipakai bersama [validateNoteTitle] agar spasi di awal/akhir tidak ikut
/// tersimpan ke database.
String normalizeNoteTitle(String raw) => raw.trim();
