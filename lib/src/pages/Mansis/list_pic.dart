import 'package:erp/services/mansis_api_service.dart';
import 'package:erp/src/models/mansis_model.dart';
import 'package:flutter/material.dart';

class ListPicPage extends StatefulWidget {
  const ListPicPage({super.key});

  @override
  State<ListPicPage> createState() => _ListPicPageState();
}

class _ListPicPageState extends State<ListPicPage> {
  final TextEditingController _picController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;
  List<MansisLookupOption> _pics = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _picController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await MansisApiService.fetchPicOptions();
      if (mounted) {
        setState(() {
          _pics = data;
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

  Future<void> _openPicDialog({MansisLookupOption? existing}) async {
    _picController.text = existing?.name ?? '';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Tambah PIC' : 'Ubah PIC'),
        content: TextField(
          controller: _picController,
          decoration: const InputDecoration(
            hintText: 'Nama PIC',
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
                : () => _savePic(ctx, id: existing?.id),
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

  Future<void> _savePic(BuildContext dialogContext, {int? id}) async {
    final name = _picController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nama PIC wajib diisi.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (id == null) {
        await MansisApiService.createPic(name);
      } else {
        await MansisApiService.updatePic(id: id, name: name);
      }

      if (mounted) {
        Navigator.of(dialogContext).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(id == null ? 'PIC ditambahkan.' : 'PIC diperbarui.')),
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
        title: const Text('Kelola PIC'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _pics.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final pic = _pics[index];
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                title: Text(pic.name),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openPicDialog(existing: pic),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPicDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}