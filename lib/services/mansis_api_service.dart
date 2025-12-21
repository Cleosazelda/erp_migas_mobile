import 'dart:async';
import 'dart:convert';

import 'package:erp/src/models/mansis_model.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

class MansisApiException implements Exception {
  final String message;

  const MansisApiException(this.message);

  @override
  String toString() => message;
}

String _cleanExceptionMessage(Object e) {
  final message = e.toString();
  const prefix = 'Exception: ';
  if (message.startsWith(prefix)) {
    return message.substring(prefix.length);
  }
  return message;
}

String _readApiMessage(http.Response response) {
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
  } catch (_) {
    // Ignore parsing errors and fallback to generic message.
  }

  return '';
}

class MansisApiService {
  // Pastikan ApiService.baseUrl sudah mengandung prefix /api
  // misal: http://103.165.226.178:8085/api
  static String get baseUrl => ApiService.baseUrl;

  /// GET /dokumen
  static Future<List<MansisDocument>> fetchDocuments() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/dokumen'), headers: ApiService.headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          data = decoded['data'] as List;
        } else {
          throw Exception('Format response dokumen tidak dikenal');
        }

        return data
            .whereType<Map<String, dynamic>>()
            .map(MansisDocument.fromJson)
            .toList();
      }

      throw Exception('Gagal memuat dokumen (Status: ${response.statusCode})');
    } on TimeoutException {
      throw Exception('Permintaan mengambil dokumen melebihi batas waktu.');
    } catch (e) {
      throw Exception('Gagal mengambil dokumen: $e');
    }
  }

  /// GET /jenis-dokumen
  static Future<List<MansisLookupOption>> fetchDocumentTypes() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/jenis-dokumen'),
          headers: ApiService.headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          data = decoded['data'] as List;
        } else {
          throw Exception('Format response jenis dokumen tidak dikenal');
        }

        return data
            .whereType<Map<String, dynamic>>()
            .map(MansisLookupOption.fromJson)
            .toList();
      }

      throw Exception(
        'Gagal memuat jenis dokumen (Status: ${response.statusCode})',
      );
    } on TimeoutException {
      throw Exception(
        'Permintaan mengambil jenis dokumen melebihi batas waktu.',
      );
    } catch (e) {
      throw Exception('Gagal mengambil jenis dokumen: $e');
    }
  }

  /// GET /pic
  static Future<List<MansisLookupOption>> fetchPicOptions() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/pic'), headers: ApiService.headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          data = decoded['data'] as List;
        } else {
          throw Exception('Format response PIC tidak dikenal');
        }

        return data
            .whereType<Map<String, dynamic>>()
            .map(MansisLookupOption.fromJson)
            .toList();
      }

      throw Exception('Gagal memuat PIC (Status: ${response.statusCode})');
    } on TimeoutException {
      throw Exception('Permintaan mengambil PIC melebihi batas waktu.');
    } catch (e) {
      throw Exception('Gagal mengambil PIC: $e');
    }
  }

  /// POST /dokumen
  static Future<MansisDocument> createDocument({
    required String number,
    required String name,
    required int jenisId,
    required int picId,
    required DateTime? approvalDate,
    required String status,
    String? link,
  }) async {
    try {
      final body = jsonEncode({
        'no': number,
        'nama': name,
        'id_jenis': jenisId,
        'id_pic': picId,
        'tgl_pengesahan': approvalDate != null
            ? approvalDate
            .toIso8601String()
            .split('T')
            .first
            : null,
        'status_dokumen': status,
        'link': link,
      });

      final response = await http
          .post(
        Uri.parse('$baseUrl/dokumen'),
        headers: ApiService.headers,
        body: body,
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Backend kamu sepertinya hanya kirim { success, message, data? }
        final decoded = jsonDecode(response.body);

        Map<String, dynamic>? data;
        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is Map<String, dynamic>) {
            data = decoded['data'] as Map<String, dynamic>;
          }
        }

        if (data != null) {
          return MansisDocument.fromJson(data);
        }

        // Kalau tidak ada "data" di response, kita buat object berdasarkan input
        return MansisDocument(
          id: null,
          title: name,
          documentNumber: number,
          pic: '',
          approvalDate: approvalDate,
          category: '',
          status: status,
          link: link,
        );
      }
      final message = _readApiMessage(response);

      if (response.statusCode == 401) {
        throw MansisApiException(
          message.isNotEmpty
              ? _cleanExceptionMessage(message)
              : 'Sesi Anda telah berakhir. Silakan login kembali lalu coba lagi.',
        );
      }

      if (response.statusCode == 403) {
        throw MansisApiException(
          message.isNotEmpty
              ? _cleanExceptionMessage(message)
              : 'Akses Anda terbatas untuk menambahkan dokumen. Hubungi admin jika membutuhkan izin.',
        );
      }

      throw MansisApiException(
        message.isNotEmpty
            ? _cleanExceptionMessage(message)
            : 'Gagal membuat dokumen (Status: ${response.statusCode})',
      );
    } on TimeoutException {
      throw const MansisApiException(
        'Permintaan menyimpan dokumen melebihi batas waktu.',
      );
    } catch (e) {
      throw MansisApiException(
        'Gagal menyimpan dokumen: ${_cleanExceptionMessage(e)}',
      );
    }
  }
  /// PATCH /dokumen/{id}
  /// Mengubah status dokumen menjadi "Aktif" atau "Tidak Aktif"
  static Future<void> updateDocumentStatus({
    required int id,
    required String status,
  }) async {
    try {
      final body = jsonEncode({
        'status_dokumen': status,
      });

      final response = await http
          .patch(
        Uri.parse('$baseUrl/dokumen/$id'),
        headers: ApiService.headers,
        body: body,
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final success = decoded['success'];
          if (success is bool && !success) {
            throw Exception(decoded['message'] ??
                'Gagal memperbarui status dokumen (server menolak permintaan).');
          }
        }

        return;
      }

      throw Exception(
        'Gagal memperbarui status dokumen (Status: ${response.statusCode})',
      );
    } on TimeoutException {
      throw Exception('Permintaan memperbarui status melebihi batas waktu.');
    } catch (e) {
      throw Exception('Gagal memperbarui status dokumen: $e');
    }
  }
  /// GET /dokumen/{id}
  static Future<MansisDocument> fetchDocumentDetail(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/dokumen/$id'), headers: ApiService.headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'] ?? decoded;
          if (data is Map<String, dynamic>) {
            return MansisDocument.fromJson(data);
          }
        }
        throw Exception('Format respons dokumen tidak valid');
      }

      throw Exception('Gagal memuat detail dokumen (Status: ${response.statusCode})');
    } on TimeoutException {
      throw Exception('Permintaan memuat detail dokumen melebihi batas waktu.');
    } catch (e) {
      throw Exception('Gagal memuat detail dokumen: $e');
    }
  }

  /// PATCH /dokumen/{id}
  static Future<void> updateDocument({
    required int id,
    required String number,
    required String name,
    required int jenisId,
    required int picId,
    required DateTime? approvalDate,
    required String status,
    String? link,
  }) async {
    try {
      final body = jsonEncode({
        'no': number,
        'nama': name,
        'id_jenis': jenisId,
        'id_pic': picId,
        'tgl_pengesahan': approvalDate != null
            ? approvalDate.toIso8601String().split('T').first
            : null,
        'status_dokumen': status,
        'link': link,
      });

      final response = await http
          .patch(
        Uri.parse('$baseUrl/dokumen/$id'),
        headers: ApiService.headers,
        body: body,
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw Exception('Gagal memperbarui dokumen (Status: ${response.statusCode})');
    } on TimeoutException {
      throw Exception('Permintaan memperbarui dokumen melebihi batas waktu.');
    } catch (e) {
      throw Exception('Gagal memperbarui dokumen: $e');
    }
  }

  /// DELETE /dokumen/{id}
  static Future<void> deleteDocument(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/dokumen/$id'), headers: ApiService.headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }

      throw Exception('Gagal menghapus dokumen (Status: ${response.statusCode})');
    } on TimeoutException {
      throw Exception('Permintaan menghapus dokumen melebihi batas waktu.');
    } catch (e) {
      throw Exception('Gagal menghapus dokumen: $e');
    }
  }

  /// POST /pic
  static Future<MansisLookupOption> createPic(String name) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/pic'),
        headers: ApiService.headers,
        body: jsonEncode({'pic': name}),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return MansisLookupOption.fromJson(decoded['data'] as Map<String, dynamic>);
        }
        return MansisLookupOption(id: -1, name: name);
      }

      throw Exception('Gagal menambahkan PIC (Status: ${response.statusCode})');
    } on TimeoutException {
      throw Exception('Permintaan menambahkan PIC melebihi batas waktu.');
    } catch (e) {
      throw Exception('Gagal menambahkan PIC: $e');
    }
  }

  /// PATCH /pic/{id}
  static Future<MansisLookupOption> updatePic({required int id, required String name}) async {
    try {
      final response = await http
          .patch(
        Uri.parse('$baseUrl/pic/$id'),
        headers: ApiService.headers,
        body: jsonEncode({'pic': name}),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MansisLookupOption(id: id, name: name);
      }

      throw Exception('Gagal memperbarui PIC (Status: ${response.statusCode})');
    } on TimeoutException {
      throw Exception('Permintaan memperbarui PIC melebihi batas waktu.');
    } catch (e) {
      throw Exception('Gagal memperbarui PIC: $e');
    }
  }

  /// POST /jenis-dokumen
  static Future<MansisLookupOption> createDocumentType(String name) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/jenis-dokumen'),
        headers: ApiService.headers,
        body: jsonEncode({'jenis_dokumen': name}),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return MansisLookupOption.fromJson(decoded['data'] as Map<String, dynamic>);
        }
        return MansisLookupOption(id: -1, name: name);
      }

      throw Exception('Gagal menambahkan jenis dokumen (Status: ${response.statusCode})');
    } on TimeoutException {
      throw Exception('Permintaan menambahkan jenis dokumen melebihi batas waktu.');
    } catch (e) {
      throw Exception('Gagal menambahkan jenis dokumen: $e');
    }
  }

  /// PATCH /jenis-dokumen/{id}
  static Future<MansisLookupOption> updateDocumentType({
    required int id,
    required String name,
  }) async {
    try {
      final response = await http
          .patch(
        Uri.parse('$baseUrl/jenis-dokumen/$id'),
        headers: ApiService.headers,
        body: jsonEncode({'jenis_dokumen': name}),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MansisLookupOption(id: id, name: name);
      }

      throw Exception('Gagal memperbarui jenis dokumen (Status: ${response.statusCode})');
    } on TimeoutException {
      throw Exception('Permintaan memperbarui jenis dokumen melebihi batas waktu.');
    } catch (e) {
      throw Exception('Gagal memperbarui jenis dokumen: $e');
    }
  }
}