import 'package:intl/intl.dart';

class MansisDocument {
  final String title;
  final String documentNumber;
  final String pic;
  final DateTime approvalDate;
  final String category;
  final bool isActive;
  final bool hasDocumentLink;

  const MansisDocument({
    required this.title,
    required this.documentNumber,
    required this.pic,
    required this.approvalDate,
    required this.category,
    required this.isActive,
    this.hasDocumentLink = true,
  });

  factory MansisDocument.fromJson(Map<String, dynamic> json) {
    return MansisDocument(
      title: json['title'] ?? 'Untitled Document',
      documentNumber: json['documentNumber'] ?? '-',
      pic: json['pic'] ?? '-',
      approvalDate: DateTime.tryParse(json['approvalDate'] ?? '') ?? DateTime.now(),
      category: json['category'] ?? 'Lainnya',
      isActive: json['isActive'] ?? false,
      hasDocumentLink: json['hasDocumentLink'] ?? true,
    );
  }

  String get approvalDateLabel => DateFormat('dd MMM yyyy').format(approvalDate);

  String get statusLabel => isActive ? 'Aktif' : 'Tidak Aktif';
}