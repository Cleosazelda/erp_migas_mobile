import 'package:intl/intl.dart';

class MansisDocument {
  final int? id;
  final String title;
  final String documentNumber;
  final String pic;
  final DateTime? approvalDate;
  final String category;
  final String status;
  final String? link;

  const MansisDocument({
    this.id,
    required this.title,
    required this.documentNumber,
    required this.pic,
    required this.approvalDate,
    required this.category,
    required this.status,
    this.link,
  });

  factory MansisDocument.fromJson(Map<String, dynamic> json) {
    String _readString(dynamic value, {String fallback = '-'}) {
      if (value == null) return fallback;
      return value.toString();
    }

    final String statusDokumen = _readString(
      json['status_dokumen'] ?? json['status'],
      fallback: '-',
    );

    return MansisDocument(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      title: _readString(
        json['nama'] ?? json['title'],
        fallback: 'Untitled Document',
      ),
      documentNumber: _readString(
        json['no'] ?? json['documentNumber'],
        fallback: '-',
      ),
      pic: _readString(json['pic'], fallback: '-'),
      approvalDate: _parseDate(json['tgl_pengesahan']),
      category: _readString(
        json['jenis_dokumen'] ?? json['category'],
        fallback: '-',
      ),
      status: statusDokumen,
      link: json['link']?.toString(),
    );
  }

  String get approvalDateLabel =>
      approvalDate != null ? DateFormat('dd MMM yyyy').format(approvalDate!) : '-';

  bool get isActive => status.toLowerCase() == 'aktif';

  String get statusLabel => status.isEmpty ? '-' : status;

  bool get hasDocumentLink => link != null && link!.isNotEmpty;

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class MansisLookupOption {
  final int id;
  final String name;

  const MansisLookupOption({required this.id, required this.name});

  factory MansisLookupOption.fromJson(Map<String, dynamic> json) {
    return MansisLookupOption(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? -1,
      // Untuk /jenis-dokumen dan /pic
      name: json['jenis_dokumen']?.toString() ??
          json['pic']?.toString() ??
          json['nama']?.toString() ??
          json['name']?.toString() ??
          '-',
    );
  }
}
