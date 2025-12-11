import 'package:erp/services/mansis_api_service.dart';
import 'package:erp/src/models/mansis_model.dart';
import 'package:erp/src/pages/Mansis/form_mansis.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:url_launcher/url_launcher.dart';

class MansisHomePage extends StatefulWidget {
  final String userName;
  const MansisHomePage({super.key, this.userName = 'Nama'});

  @override
  State<MansisHomePage> createState() => _MansisHomePageState();
}

class _MansisHomePageState extends State<MansisHomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<MansisDocument> _documents = [];
  List<MansisLookupOption> _documentTypes = const [];
  List<MansisLookupOption> _picOptions = const [];

  MansisLookupOption _selectedType =
  const MansisLookupOption(id: -1, name: 'Semua Jenis Dokumen');
  MansisLookupOption _selectedPic =
  const MansisLookupOption(id: -1, name: 'Semua PIC Dokumen');

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        MansisApiService.fetchDocuments(),
        MansisApiService.fetchDocumentTypes(),
        MansisApiService.fetchPicOptions(),
      ]);

      final documents = results[0] as List<MansisDocument>;
      final types = results[1] as List<MansisLookupOption>;
      final pics = results[2] as List<MansisLookupOption>;

      setState(() {
        _documents = documents;
        _documentTypes = [_allDocumentTypeOption(), ...types];
        _picOptions = [_allPicOption(), ...pics];
        _selectedType = _documentTypes.first;
        _selectedPic = _picOptions.first;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      setState(() => _isLoading = false);
    }
  }

  MansisLookupOption _allDocumentTypeOption() =>
      const MansisLookupOption(id: -1, name: 'Semua Jenis Dokumen');

  MansisLookupOption _allPicOption() =>
      const MansisLookupOption(id: -1, name: 'Semua PIC Dokumen');

  List<MansisLookupOption> get _masterTypeOptions =>
      _documentTypes.where((option) => option.id != -1).toList();

  List<MansisLookupOption> get _masterPicOptions =>
      _picOptions.where((option) => option.id != -1).toList();

  MansisLookupOption _defaultPicForForm() {
    if (_masterPicOptions.isEmpty) return _allPicOption();

    final match = _masterPicOptions.firstWhere(
          (option) => option.name.toLowerCase() == widget.userName.toLowerCase(),
      orElse: () => _masterPicOptions.first,
    );

    return match;
  }

  List<MansisDocument> get _filteredDocuments {
    final keyword = _searchController.text.toLowerCase();

    return _documents.where((doc) {
      final matchesType = _selectedType.id == -1 ||
          doc.category.toLowerCase() == _selectedType.name.toLowerCase();

      final matchesPic = _selectedPic.id == -1 ||
          doc.pic.toLowerCase() == _selectedPic.name.toLowerCase();

      final matchesSearch = keyword.isEmpty ||
          doc.title.toLowerCase().contains(keyword) ||
          doc.documentNumber.toLowerCase().contains(keyword) ||
          doc.pic.toLowerCase().contains(keyword);

      return matchesType && matchesPic && matchesSearch;
    }).toList();
  }

  void _applyFilters() => setState(() {});

  void _openAddForm() {
    if (_masterTypeOptions.isEmpty || _masterPicOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data master belum tersedia, coba lagi.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: MansisFormSheet(
          typeOptions: _masterTypeOptions,
          picOptions: _masterPicOptions,
          defaultPic: _defaultPicForForm(),
          onSubmit: (data) async {
            try {
              await MansisApiService.createDocument(
                number: data.number,
                name: data.name,
                jenisId: data.type.id,
                picId: data.pic.id,
                approvalDate: data.approvalDate,
                status: data.status,
                link: data.link,
              );

              if (mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dokumen berhasil disimpan.')),
                );
                _loadData();
              }
              return true;
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
              return false;
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.menu, color: Colors.black87),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_outlined,
                color: Colors.black87),
          ),
        ],
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage('assets/images/logo.png'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manajemen Sistem MUJ',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Welcome ${widget.userName}!',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchField(),
              const SizedBox(height: 12),
              _buildFilters(),
              const SizedBox(height: 12),
              Text(
                'List Dokumen',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _DocumentList(documents: _filteredDocuments),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingButtons(),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari dokumen...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 380;

        if (isSmallScreen) {
          return Column(
            children: [
              _buildDropdown(
                value: _selectedType,
                items: _documentTypes,
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                value: _selectedPic,
                items: _picOptions,
                onChanged: (value) {
                  if (value != null) setState(() => _selectedPic = value);
                },
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildDropdown(
                value: _selectedType,
                items: _documentTypes,
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                value: _selectedPic,
                items: _picOptions,
                onChanged: (value) {
                  if (value != null) setState(() => _selectedPic = value);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown({
    required MansisLookupOption value,
    required List<MansisLookupOption> items,
    required ValueChanged<MansisLookupOption?> onChanged,
  }) {
    const selectedColor = Color(0xFF82B43F);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<MansisLookupOption>(
          value: value,
          isExpanded: true,

          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.zero,
          ),

          selectedItemBuilder: (context) {
            return items.map((item) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              );
            }).toList();
          },

          iconStyleData: const IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.black87, size: 18),
          ),

          dropdownStyleData: DropdownStyleData(
            padding: EdgeInsets.zero,
            maxHeight: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),

          // Style saat dropdown terbuka
          items: items.map((item) {
            final bool isSelected = item.id == value.id;

            return DropdownMenuItem(
              value: item,
              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : Colors.white,
                  borderRadius: BorderRadius.zero
                ),
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),

          onChanged: onChanged,
        ),
      ),
    );
  }

        Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'addButton',
          backgroundColor: const Color(0xFF0B8A00),
          shape: const CircleBorder(),
          onPressed: _openAddForm,
          child: const Icon(Icons.note_add_outlined, size: 28, color: Colors.white),
        ),

      ],
    );
  }
}

class _DocumentList extends StatelessWidget {
  final List<MansisDocument> documents;
  const _DocumentList({required this.documents});

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(child: Text('Dokumen tidak ditemukan'));
    }

    return ListView.separated(
      itemCount: documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _DocumentCard(document: documents[index]),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final MansisDocument document;
  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            document.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            children: [
              _chip(
                label: document.category,
                bg: const Color(0xFFDFF2D8),
                text: const Color(0xFF82B43F),
              ),
              _chip(
                label: document.statusLabel,
                bg: document.isActive
                    ? const Color(0xFFDFF2D8)
                    : Colors.grey.shade200,
                text: document.isActive
                    ? const Color(0xFF82B43F)
                    : Colors.grey.shade600,
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            document.documentNumber,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'PIC : ${document.pic}',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Tanggal Pengesahan ${document.approvalDateLabel}',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 14),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed:
              document.hasDocumentLink ? () => _openDocument(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF82B43F),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Link Dokumen',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.open_in_new, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required Color bg,
    required Color text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _openDocument(BuildContext context) async {
    final uri = Uri.tryParse(document.link ?? '');

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link dokumen tidak valid')),
      );
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka link dokumen')),
      );
    }
  }
}
