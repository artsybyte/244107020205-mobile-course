/// Aturan pencarian judul catatan.
///
/// Fungsi ini murni (tanpa import Flutter) sehingga bisa diuji sebagai unit
/// test biasa. Pencarian sengaja **tidak** menyentuh database: daftar catatan
/// sudah ada di cache lokal, jadi memfilter di memori jauh lebih murah
/// daripada membuka koneksi SQLite baru pada setiap ketikan.
library;

import '../data/local/note.dart';

/// Menyaring [notes] berdasarkan [query] pada judul catatan.
///
/// - [query] di-`trim` lebih dulu; bila hasilnya kosong, seluruh catatan
///   dikembalikan (pencarian kosong berarti tidak memfilter).
/// - Pencocokan memakai `contains` dan **tidak** membedakan huruf besar/kecil.
/// - Urutan catatan dipertahankan agar urutan `updated_at DESC` dari repository
///   tidak berubah setelah difilter.
List<Note> searchNotes(List<Note> notes, String query) {
  final needle = _normalize(query);
  if (needle.isEmpty) return notes;
  return notes
      .where((note) => _normalize(note.title).contains(needle))
      .toList(growable: false);
}

/// Menyeragamkan teks sebelum dibandingkan: buang spasi tepi, rapatkan spasi
/// beruntun menjadi satu, lalu huruf kecil.
///
/// Tanpa langkah ini, query `tugas  mobile` (dua spasi) tidak akan menemukan
/// judul `Tugas Mobile` - pengguna melihat hasil kosong padahal catatannya ada.
String _normalize(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
