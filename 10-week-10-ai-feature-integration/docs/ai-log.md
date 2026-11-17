# AI Log — Chat Asisten atas Catatan

Dokumen ini merekam siklus **prompt → generate → verify → test → refactor →
explain** untuk satu fitur AI: chat asisten yang menjawab pertanyaan berdasarkan
catatan lokal, dengan fallback offline.

Project: `05-week-5-local-storage-offline-first/week5_offline_notes`
(tidak membuat project baru — fitur ditambahkan ke project Minggu 5 yang sudah
lolos review Minggu 8 dan menjadi basis Minggu 9).

Issue: [#20](https://github.com/artsybyte/244107020205-mobile-course/issues/20)
Branch: `feat/ai-chat`

---

## 1. Prompt yang dipakai (formula 5 slot)

```
Peran : senior Flutter dev
Konteks: project week5_offline_notes, layer-first (core/data/pages/widgets),
         Riverpod 3, sqflite cache-first, Dio 5. Catatan ada di Note
         {id, title, body, updatedAt, dirty}; daftar sudah dimuat lewat
         notesProvider (FutureProvider<List<Note>>). SettingsPage ada tapi
         belum punya route.
Tugas : integrasikan satu fitur AI berupa chat asisten yang menjawab
         pertanyaan berdasarkan isi catatan lokal, dengan streaming
         response, cache, batas kuota harian, dan fallback offline.
Batas : API key hanya di secure storage (jangan pernah di kode sumber),
         jangan kirim NIK/nomor telepon/email ke AI API, jangan ubah
         arsitektur layer-first, jangan panggil jaringan dari widget,
         sertakan unit test untuk setiap aturan murni.
Output: kode + test + cara verifikasi manual + tabel risiko.
```

Konteks yang ditempel ke AI (potongan nyata, bukan seluruh repo):

```dart
// lib/data/local/note.dart
class Note {
  const Note({this.id, required this.title, this.body = '',
              required this.updatedAt, this.dirty = false});
  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;
}

// lib/data/note_providers.dart
final notesProvider = FutureProvider<List<Note>>(
  (ref) => ref.watch(noteRepositoryProvider).fetchNotes(),
  retry: _noRetry,
);

// pubspec.yaml (bagian dependencies, sudah ada sebelum minggu 10)
dio: ^5.9.0
shared_preferences: ^2.5.5
sqflite: ^2.4.4
```

Yang **tidak** ditempel: API key, token, `.env`, isi `build/`, dan isi catatan
pengguna.

---

## 2. Output awal (draf) yang dihasilkan AI

### 2a. Klien API — versi draf

```dart
// lib/ai/gemini_client.dart (draf)
Future<String> ask(String question) async {
  final res = await http.post(
    Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-pro:generateContent?key=$apiKey'),
    body: jsonEncode({'contents': [{'parts': [{'text': question}]}]}),
  );
  return jsonDecode(res.body)['candidates'][0]['content']['parts'][0]['text'];
}
```

### 2b. Penyaring data pribadi — versi draf

```dart
// lib/ai/privacy_filter.dart (draf)
static final _phone = RegExp(r'(?:\+62|62|0)8[1-9][0-9]{6,10}(?![0-9])');
```

### 2c. Pemotongan kalimat untuk mode offline — versi draf

```dart
// lib/ai/local_answer.dart (draf)
final end = trimmed.indexOf(RegExp(r'[.!?\n]'));
return trimmed.substring(0, end + 1).trim();
```

### 2d. Wiring klien — versi draf

```dart
// lib/ai/ai_providers.dart (draf)
final aiClientProvider = FutureProvider<AiClient>((ref) async {
  final demoMode = await ref.watch(aiDemoModeProvider.future);
  if (demoMode) return DemoAiClient();
  final apiKey = await ref.watch(aiKeyStoreProvider).read();
  if (apiKey == null || apiKey.isEmpty) throw const AiException('...');
  return GeminiClient(apiKey: apiKey);
});
```

---

## 3. Verifikasi terhadap draf

| # | Temuan | Cara membuktikan | Keputusan |
|:-:|:-------|:-----------------|:----------|
| 1 | Model `gemini-pro` tidak dilayani `v1beta` | Dokumentasi Gemini: model generatif saat ini `gemini-2.5-flash`/`2.5-pro`; `gemini-pro` mengembalikan 404 | ✅ diganti `gemini-2.5-flash` di `AiConfig.model` |
| 2 | `http.post` tidak bisa streaming | `package:http` mengembalikan `Response` utuh; SSE butuh `ResponseBody.stream` milik Dio | ✅ memakai `dio` + `ResponseType.stream` |
| 3 | API key dikirim di query string | URL dengan `?key=` ikut tercatat di log proxy, riwayat, dan `Referer` | ✅ dipindah ke header `x-goog-api-key` |
| 4 | `http` ditambahkan padahal `dio` sudah ada | `pubspec.yaml` sudah berisi `dio: ^5.9.0` | ❌ dependensi `http` ditolak |
| 5 | `flutter_secure_storage: ^9.0.0` (codelab) | pub.dev: versi terbaru `11.2.0`, SDK `>=3.8.0`; project memakai Dart 3.13.2 | ✅ memakai `^11.2.0` |
| 6 | Regex telepon tidak menangkap nomor rumah `+62341234567` | Test merah: `Expected: not contains '+62341234567'` | ✅ pola diubah ke `(?:\+62|62|0)[0-9]{8,12}(?![0-9])` |
| 7 | Pemotongan kalimat memotong `pukul 10.00` menjadi `pukul 10.` | Terlihat pada screenshot aplikasi berjalan, lalu dikunci dengan test `pukul 10.00 di lab.` | ✅ regex jadi `[.!?\n](?=\s|$)` |
| 8 | `FutureProvider` tanpa `retry` menggantung saat key tidak ada | Screenshot 08: layar berhenti di keadaan "mengirim", banner error tidak muncul | ✅ `retry: (_, _) => null` |
| 9 | `prefer_initializing_formals` pada `AiCache`/`AiQuota` | `flutter analyze` → 2 info | ✅ diganti factory + konstruktor privat |
| 10 | `equal_elements_in_const_set` (`'aku'` dua kali) | `flutter analyze` → error | ✅ duplikat dihapus |
| 11 | `bytes.transform(utf8.decoder)` tidak bisa dikompilasi | `flutter analyze` → `argument_type_not_assignable` | ✅ `bytes.cast<List<int>>().transform(...)` |
| 12 | Dialog "Layanan AI Sibuk" menutupi jawaban terakhir | Uji manual: dialog menutup alur, dua aksi harus dipilih berurutan | ✅ diganti banner + dua tombol aksi |

**Rekap:** 10 diterima dengan bukti, 2 ditolak dengan alasan tertulis
(`http`, dan model `gemini-pro` yang tidak mungkin dipakai).

---

## 4. Keputusan desain yang tidak ada di codelab

| Keputusan | Alasan |
|:----------|:-------|
| Mode demo aktif secara default | Aplikasi harus bisa dijalankan dan dinilai tanpa API key pribadi; tidak ada rahasia di repo |
| Cache berbasis sidik jari catatan | Jawaban lama otomatis batal dipakai ketika isi catatan berubah (`notesFingerprint`) |
| Kuota dihitung sebelum request | Menahan biaya sebelum terjadi, bukan sesudah tagihan datang |
| Klien AI di balik `abstract AiClient` | UI dan test tidak tahu Gemini; klien palsu bisa dipakai untuk semua jalur error |
| Penyaringan privasi di satu fungsi murni | Aturan privasi bisa diuji tanpa jaringan dan tanpa widget |

---

## 5. Yang tidak dikirim ke AI API

`PrivacyFilter.redact` mengganti email, NIK 16 digit, dan nomor telepon
Indonesia dengan penanda netral **sebelum** prompt dibentuk. Test
`privacy_filter_test.dart` mengunci perilaku ini, termasuk kasus NIK yang
diawali `08` (tidak boleh dipotong menjadi nomor telepon).
