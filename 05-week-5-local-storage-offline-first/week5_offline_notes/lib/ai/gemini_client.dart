/// Klien Gemini memakai REST `streamGenerateContent` dengan `alt=sse`.
///
/// Perbedaan dari contoh codelab:
/// - API key dikirim lewat header `x-goog-api-key`, bukan query string, supaya
///   tidak ikut tercatat di log proxy maupun riwayat URL.
/// - `dio` dipakai karena project ini sudah memakainya; menambah `http` hanya
///   akan menduplikasi klien HTTP.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'ai_client.dart';
import 'ai_config.dart';
import 'sse_parser.dart';

class GeminiClient implements AiClient {
  GeminiClient({required this.apiKey, Dio? dio}) : _dio = dio ?? Dio();

  final String apiKey;
  final Dio _dio;

  @override
  String get label => 'Gemini ${AiConfig.model}';

  @override
  Stream<String> streamAnswer(AiRequest request) async* {
    final Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        AiConfig.streamUri().toString(),
        data: {
          'system_instruction': {
            'parts': [
              {'text': request.systemPrompt},
            ],
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': request.userPrompt},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 256},
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    }

    final body = response.data;
    if (body == null) {
      throw const AiException('AI API mengirim respons kosong. Coba lagi.');
    }

    yield* SseParser().parse(_decodeLines(body.stream));
  }

  Stream<String> _decodeLines(Stream<Uint8List> bytes) => bytes
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(const LineSplitter());

  AiException _mapDioError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) {
      return const AiException(
        'API key ditolak. Periksa kembali key di Pengaturan AI.',
        retryable: false,
      );
    }
    if (status == 404) {
      return const AiException(
        'Model AI tidak tersedia untuk key ini. Coba model lain di Pengaturan.',
        retryable: false,
      );
    }
    if (status == 429) {
      return const AiException(
        'Kuota AI API sedang penuh. Coba lagi beberapa saat atau pakai mode offline.',
      );
    }
    if (status != null && status >= 500) {
      return AiException('Layanan AI sedang sibuk ($status). Coba lagi nanti.');
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AiException(
          'Koneksi ke AI API terlalu lama. Periksa jaringan lalu coba lagi.',
        );
      case DioExceptionType.connectionError:
        return const AiException(
          'Tidak ada koneksi internet. Gunakan mode offline untuk mencari di catatan lokal.',
        );
      default:
        return const AiException('Gagal memanggil AI API. Coba lagi nanti.');
    }
  }
}
