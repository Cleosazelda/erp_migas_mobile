import 'package:erp/services/mansis_api_service.dart';
import 'package:erp/src/models/mansis_model.dart';
import 'package:flutter/material.dart';

class TypeDocumentPage extends StatefulWidget {
  const TypeDocumentPage({super.key});

  @override
  State<TypeDocumentPage> createState() => _TypeDocumentPageState();
}

class _TypeDocumentPageState extends State<TypeDocumentPage> {
  final TextEditingController _typeController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;
  List<MansisLookupOption> _types = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await MansisApiService.fetchDocumentTypes();
      if (mounted) {
        setState(() {
          _types = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _openTypeDialog({MansisLookupOption? existing}) async {
    _typeController.text = existing?.name ?? '';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Tambah Jenis Dokumen' : 'Ubah Jenis Dokumen'),
        content: TextField(
          controller: _typeController,
          decoration: const InputDecoration(
            hintText: 'Nama jenis dokumen',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () => _saveType(ctx, id: existing?.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveType(BuildContext dialogContext, {int? id}) async {
    final name = _typeController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nama jenis dokumen wajib diisi.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (id == null) {
        await MansisApiService.createDocumentType(name);
      } else {
        await MansisApiService.updateDocumentType(id: id, name: name);
      }

      if (mounted) {
        Navigator.of(dialogContext).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(id == null ? 'Jenis dokumen ditambahkan.' : 'Jenis dokumen diperbarui.')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Jenis Dokumen'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _types.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _types[index];
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                title: Text(item.name),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openTypeDialog(existing: item),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTypeDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}