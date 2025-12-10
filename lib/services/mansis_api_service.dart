import 'dart:async';
import 'dart:convert';

import 'package:erp/src/models/mansis_model.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

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
            ? approvalDate.toIso8601String().split('T').first
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

      throw Exception('Gagal membuat dokumen (Status: ${response.statusCode})');
    } on TimeoutException {
      throw Exception('Permintaan menyimpan dokumen melebihi batas waktu.');
    } catch (e) {
      throw Exception('Gagal menyimpan dokumen: $e');
    }
  }
}
