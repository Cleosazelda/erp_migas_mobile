import 'package:erp/src/models/mansis_model.dart';

class MansisMockService {
  MansisMockService._();

  static const List<String> documentTypes = [
    'Semua Jenis Dokumen',
    'Pedoman',
    'SOP',
    'Intruksi Kerja',
    'Form',
    'Record',
    'Laporan Kinerja',
    'Perdir',
    'Perubahan',
    'Tidak Aktif',
  ];

  static const List<String> picOptions = [
    'Semua PIC Dokumen',
    'Sekretaris Perusahaan',
    'Satuan Pengawas Internal',
    'Keuangan',
    'Pengembangan SDM dan Organisasi',
    'Umum',
    'Manajemen Risiko',
    'Perencanaan & Manajemen Kinerja',
    'Pengadaan',
    'Teknologi Informasi',
    'T3L',
    'Manajemen Aset',
  ];

  static final List<MansisDocument> _mockDocuments = [
    MansisDocument(
      title: 'SOP LHKPN di Lingkungan MUJ',
      documentNumber: '02.3.0/PER-LHKPN/SEKPER/LEG/2023',
      pic: 'Sekretaris Perusahaan',
      approvalDate: DateTime(2023, 8, 30),
      category: 'Perdir',
      isActive: true,
    ),
    MansisDocument(
      title: 'Buku Pedoman Kerja Dewan Komisaris dan Direksi',
      documentNumber: '1.2-BM1',
      pic: 'Sekretaris Perusahaan',
      approvalDate: DateTime(2023, 8, 30),
      category: 'Pedoman',
      isActive: true,
    ),
    MansisDocument(
      title: 'Pedoman Naskah Dinas Pengaturan',
      documentNumber: 'P.SKPD.01/2023',
      pic: 'Sekretaris Perusahaan',
      approvalDate: DateTime(2023, 8, 30),
      category: 'Pedoman',
      isActive: true,
    ),
    MansisDocument(
      title: 'Buku Pedoman Kerja Dewan Komisaris dan Direksi',
      documentNumber: 'P.SKPD.02/2023',
      pic: 'Satuan Pengawas Internal',
      approvalDate: DateTime(2023, 8, 30),
      category: 'Pedoman',
      isActive: false,
      hasDocumentLink: false,
    ),
  ];

  static Future<List<MansisDocument>> fetchDocuments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockDocuments;
  }
}