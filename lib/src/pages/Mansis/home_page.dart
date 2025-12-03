import 'package:erp/services/mansis_mock_service.dart';
import 'package:erp/src/models/mansis_model.dart';
import 'package:flutter/material.dart';

class MansisHomePage extends StatefulWidget {
  final String userName;
  const MansisHomePage({super.key, this.userName = 'Nama'});

  @override
  State<MansisHomePage> createState() => _MansisHomePageState();
}

class _MansisHomePageState extends State<MansisHomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<MansisDocument> _documents = [];
  String _selectedType = MansisMockService.documentTypes.first;
  String _selectedPic = MansisMockService.picOptions.first;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _loadDocuments() async {
    final results = await MansisMockService.fetchDocuments();
    setState(() {
      _documents = results;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MansisDocument> get _filteredDocuments {
    final keyword = _searchController.text.toLowerCase();

    return _documents.where((doc) {
      final matchesType = _selectedType == MansisMockService.documentTypes.first ||
          doc.category.toLowerCase() == _selectedType.toLowerCase();
      final matchesPic = _selectedPic == MansisMockService.picOptions.first ||
          doc.pic.toLowerCase() == _selectedPic.toLowerCase();
      final matchesSearch = keyword.isEmpty ||
          doc.title.toLowerCase().contains(keyword) ||
          doc.documentNumber.toLowerCase().contains(keyword) ||
          doc.pic.toLowerCase().contains(keyword);
      return matchesType && matchesPic && matchesSearch;
    }).toList();
  }

  void _applyFilters() => setState(() {});

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
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87),
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
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Welcome ${widget.userName}!',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
        hintText: 'Search any Product..',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildDropdown(
          value: _selectedType,
          items: MansisMockService.documentTypes,
          icon: Icons.keyboard_arrow_down,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedType = value);
          },
        ),
        _buildDropdown(
          value: _selectedPic,
          items: MansisMockService.picOptions,
          icon: Icons.keyboard_arrow_down,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedPic = value);
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        icon: Icon(icon, color: Colors.black54),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: onChanged,
        items: items
            .map((item) => DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'voiceButton',
          backgroundColor: Colors.grey[300],
          onPressed: () {},
          child: const Icon(Icons.mic_none, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'addButton',
          backgroundColor: const Color(0xFF0B8A00),
          onPressed: () {},
          child: const Icon(Icons.add, color: Colors.white),
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
      itemBuilder: (context, index) => _DocumentCard(document: documents[index]),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final MansisDocument document;
  const _DocumentCard({required this.document});

  Color get _statusColor => document.isActive ? const Color(0xFF0B8A00) : const Color(0xFF777777);
  Color get _chipBackground => document.isActive ? const Color(0xFFDFF2D8) : const Color(0xFFE5E5E5);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(document.category, const Color(0xFFDFF2D8), _statusColor),
                    _buildChip(document.statusLabel, _chipBackground, _statusColor),
                  ],
                ),
                const SizedBox(height: 12),
                Text(document.documentNumber, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text('PIC: ${document.pic}', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text('Tanggal Pengesahan ${document.approvalDateLabel}', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              ElevatedButton(
                onPressed: document.hasDocumentLink ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: document.hasDocumentLink ? const Color(0xFF0B8A00) : Colors.grey[300],
                  foregroundColor: document.hasDocumentLink ? Colors.white : Colors.grey[700],
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Link Dokumen'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color background, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
