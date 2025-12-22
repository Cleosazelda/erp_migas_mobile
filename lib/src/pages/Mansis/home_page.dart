import 'package:erp/services/mansis_api_service.dart';
import 'package:erp/src/models/mansis_model.dart';
import 'package:erp/src/pages/Mansis/form_mansis.dart';
import 'package:erp/src/pages/Mansis/list_pic.dart';
import 'package:erp/src/pages/Mansis/type_document.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:url_launcher/url_launcher.dart';

class MansisHomePage extends StatefulWidget {
  final String userName;
  final bool isAdmin;
  const MansisHomePage({super.key, this.userName = 'Nama', this.isAdmin = false});

  @override
  State<MansisHomePage> createState() => _MansisHomePageState();
}

class _MansisHomePageState extends State<MansisHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  final ScrollController _scrollController = ScrollController();
  List<MansisDocument> _documents = [];
  List<MansisLookupOption> _documentTypes = const [];
  List<MansisLookupOption> _picOptions = const [];

  MansisLookupOption _selectedType =
  const MansisLookupOption(id: -1, name: 'Semua Jenis Dokumen');
  MansisLookupOption _selectedPic =
  const MansisLookupOption(id: -1, name: 'Semua PIC Dokumen');

  bool _isLoading = true;
  String? _loadError;
  int? _updatingDocumentId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final documents = await MansisApiService.fetchDocuments();
      List<MansisLookupOption> types = const [];
      List<MansisLookupOption> pics = const [];

      try {
        types = await MansisApiService.fetchDocumentTypes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat jenis dokumen: $e')),
          );
        }
      }

      try {
        pics = await MansisApiService.fetchPicOptions();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat PIC dokumen: $e')),
          );
        }
      }

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
      setState(() {
        _isLoading = false;
        _loadError = 'Gagal memuat dokumen. Silakan coba lagi.';
      });
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

  Future<void> _triggerRefresh() async {
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    await _refreshIndicatorKey.currentState?.show();
  }

  void _openAddForm() {
    if (!widget.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hanya admin yang dapat menambahkan dokumen.')),
      );
      return;
    }
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
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

  void _openEditForm(MansisDocument document) {
    if (!widget.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hanya admin yang dapat mengubah dokumen.')),
      );
      return;
    }
    final colorScheme = Theme.of(context).colorScheme;
    if (document.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dokumen tidak memiliki ID yang valid.')),
      );
      return;
    }

    if (_masterTypeOptions.isEmpty || _masterPicOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data master belum tersedia, coba lagi.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
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
          initialData: document,
          onSubmit: (data) async {
            try {
              await MansisApiService.updateDocument(
                id: document.id!,
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
                  const SnackBar(content: Text('Dokumen berhasil diperbarui.')),
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

  Future<void> _deleteDocument(MansisDocument document) async {
    if (!widget.isAdmin) return;
    final colorScheme = Theme.of(context).colorScheme;
    if (document.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dokumen tidak memiliki ID yang valid.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dokumen'),
        content: Text('Hapus dokumen "${document.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _updatingDocumentId = document.id);
    try {
      await MansisApiService.deleteDocument(document.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dokumen berhasil dihapus.')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _updatingDocumentId = null);
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: Icon(Icons.menu, color: colorScheme.onSurface),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _triggerRefresh,
            icon:
            Icon(Icons.refresh_outlined, color: colorScheme.onSurface),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _loadData,
          child: ListView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.all(16),
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
            if (_isLoading)
          const Center(child: CircularProgressIndicator())
    else if (_loadError != null)
    _ErrorState(
                  message: _loadError!,
                  onRetry: _loadData,
                )
                else
                    _DocumentList(
                  documents: _filteredDocuments,
                  onEdit: widget.isAdmin ? _openEditForm : null,
                  onDelete: widget.isAdmin ? _deleteDocument : null,
                  updatingDocumentId: _updatingDocumentId,
                  isAdmin: widget.isAdmin,
                ),
            ],
          ),
        ),
      ),
      floatingActionButton:
      _loadError == null && widget.isAdmin ? _buildFloatingButtons(colorScheme) : null,
    );
  }


  Drawer _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Drawer(
      child: Container(
        color: colorScheme.surface,
        child: Column(
          children: [
            _buildDrawerHeader(theme, isDark: theme.brightness == Brightness.dark),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSectionTitle('Navigasi', theme),
                  _buildSidebarItem(
                    context,
                    assetPath: 'assets/images/home.png',
                    title: 'Beranda',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                  _buildSidebarItem(
                    context,
                    assetPath: 'assets/images/mansis/documents_logo.png',
                    title: 'Dokumen',
                    isSelected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  if (widget.isAdmin) ...[
                    const SizedBox(height: 12),
                    _buildSectionTitle('Data Master', theme),
                    _buildSidebarItem(
                      context,
                      assetPath: 'assets/images/mansis/pic_logo.png',
                      title: 'Daftar PIC',
                      isSelected: false,
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ListPicPage(),
                          ),
                        );
                        if (mounted) _loadData();
                      },
                    ),
                    _buildSidebarItem(
                      context,
                      assetPath: 'assets/images/mansis/list_documents.png',
                      title: 'Tipe Dokumen',
                      isSelected: false,
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TypeDocumentPage(),
                          ),
                        );
                        if (mounted) _loadData();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(ThemeData theme, {required bool isDark}) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surfaceVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primary.withOpacity(isDark ? 0.18 : 0.12),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.account_circle,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manajemen Sistem MUJ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.hintColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
      BuildContext context, {
        required String assetPath,
        required String title,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isSelected ? theme.colorScheme.onSurface : theme.hintColor;
    final bgColor = isSelected
        ? theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.5 : 0.8)
        : Colors.transparent;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Image.asset(
                assetPath,
                width: 22,
                height: 22,
                color: color,
                errorBuilder: (ctx, e, st) => Icon(Icons.image_not_supported, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari dokumen...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(isDark ? 0.35 : 0.8),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        boxShadow: isDark
            ? null
            : [
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              );
            }).toList();
          },

          iconStyleData: IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: textColor, size: 18),
          ),

          dropdownStyleData: DropdownStyleData(
            padding: EdgeInsets.zero,
            maxHeight: 300,
            decoration: BoxDecoration(
              color: colorScheme.surface,
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
                    color: isSelected ? selectedColor : colorScheme.surface,
                    borderRadius: BorderRadius.zero
                ),
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.white : textColor,
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

  Widget _buildFloatingButtons(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'addButton',
          backgroundColor: colorScheme.primary,
          shape: const CircleBorder(),
          onPressed: _openAddForm,
          child: Image.asset(
            'assets/images/mansis/tambah_dokumen.png',
            width: 28,
            height: 28,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.note_add_outlined, size: 28, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}


class _DocumentList extends StatelessWidget {
  final List<MansisDocument> documents;

  final int? updatingDocumentId;
  final ValueChanged<MansisDocument>? onEdit;
  final ValueChanged<MansisDocument>? onDelete;
  final bool isAdmin;

  const _DocumentList({
    required this.documents,
    required this.updatingDocumentId,
    this.onEdit,
    this.onDelete,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(child: Text('Dokumen tidak ditemukan'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _DocumentCard(
            document: documents[index],
            onEdit: onEdit != null ? () => onEdit!(documents[index]) : null,
            onDelete: onDelete != null ? () => onDelete!(documents[index]) : null,
            isUpdating: updatingDocumentId == documents[index].id,
            isAdmin: isAdmin,
          ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final MansisDocument document;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isUpdating;
  final bool isAdmin;
  const _DocumentCard({
    required this.document,
    this.onEdit,
    this.onDelete,
    required this.isUpdating,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: isDark
            ? null
            : [
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  document.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (isAdmin)
                PopupMenuButton<String>(
                  enabled: !isUpdating,
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'delete':
                        if (onDelete != null) onDelete!();
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    final items = <PopupMenuEntry<String>>[];
                    if (onEdit != null) {
                      items.add(
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, color: colorScheme.onSurface),
                              const SizedBox(width: 8),
                              Text('Edit Dokumen', style: TextStyle(color: colorScheme.onSurface)),
                            ],
                          ),
                        ),
                      );

                    }
                    if (isAdmin && onDelete != null) {
                      if (items.isNotEmpty) items.add(const PopupMenuDivider());
                      items.add(
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: colorScheme.error),
                              const SizedBox(width: 8),
                              Text('Hapus Dokumen', style: TextStyle(color: colorScheme.error)),                              Text('Hapus Dokumen', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      );
                    }
                    return items;
                  },
                  icon: isUpdating
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(Icons.more_vert, color: colorScheme.onSurface),
                ),
            ],
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            children: [
              _outlineChip(
                label: document.category,
                color: colorScheme.primary,
                background: colorScheme.surface,
                textColor: colorScheme.primary,
              ),
              _chip(
                label: document.statusLabel,
                bg: document.isActive
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant,
                text: document.isActive
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            document.documentNumber,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'PIC : ${document.pic}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Tanggal Pengesahan ${document.approvalDateLabel}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 14),

          if (document.hasDocumentLink)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: document.hasDocumentLink
                      ? () => _openDocument(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Link Dokumen',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.open_in_new, color: colorScheme.onPrimary, size: 18),
                    ],
                  ),
                ),
              ],
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
        borderRadius: BorderRadius.circular(8),
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

  Widget _outlineChip({
    required String label,
    Color color = const Color(0xFF82B43F),
    Color? background,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
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