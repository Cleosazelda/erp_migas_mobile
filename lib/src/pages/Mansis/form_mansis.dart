import 'package:erp/src/models/mansis_model.dart';
import 'package:flutter/material.dart';

class MansisFormData {
  final int? id;
  final String number;
  final String name;
  final MansisLookupOption type;
  final MansisLookupOption pic;
  final DateTime? approvalDate;
  final String status;
  final String? link;

  MansisFormData({
    this.id,
    required this.number,
    required this.name,
    required this.type,
    required this.pic,
    required this.approvalDate,
    required this.status,
    this.link,
  });
}

class MansisFormSheet extends StatefulWidget {
  final List<MansisLookupOption> typeOptions;
  final List<MansisLookupOption> picOptions;
  final MansisLookupOption defaultPic;
  final Future<bool> Function(MansisFormData data) onSubmit;
  final MansisDocument? initialData;

  const MansisFormSheet({
    super.key,
    required this.typeOptions,
    required this.picOptions,
    required this.defaultPic,
    required this.onSubmit,
    this.initialData,
  });

  @override
  State<MansisFormSheet> createState() => _MansisFormSheetState();
}

class _MansisFormSheetState extends State<MansisFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _linkController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _selectedDate;
  late MansisLookupOption _selectedType;
  late MansisLookupOption _selectedPic;
  String _status = 'Aktif';
  bool _isSaving = false;
  bool get _isEditing => widget.initialData != null;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.typeOptions.first;
    _selectedPic = widget.defaultPic;
    _prefillFromInitialData();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _linkController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _prefillFromInitialData() {
    final initial = widget.initialData;
    if (initial == null) return;

    _numberController.text = initial.documentNumber;
    _nameController.text = initial.title;
    _linkController.text = initial.link ?? '';
    _status = initial.statusLabel;
    _selectedDate = initial.approvalDate;

    if (_selectedDate != null) {
      _dateController.text =
      "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}";
    }

    _selectedType = _matchOption(
      widget.typeOptions,
      initial.typeId,
      initial.category,
    );

    _selectedPic = _matchOption(
      widget.picOptions,
      initial.picId,
      initial.pic,
    );
  }

  MansisLookupOption _matchOption(
      List<MansisLookupOption> options,
      int? targetId,
      String fallbackName,
      ) {
    if (targetId != null) {
      final match = options.firstWhere(
            (option) => option.id == targetId,
        orElse: () => options.first,
      );
      if (match.id == targetId) return match;
    }

    final lowerName = fallbackName.toLowerCase();
    final byName = options.firstWhere(
          (option) => option.name.toLowerCase() == lowerName,
      orElse: () => options.first,
    );
    return byName;
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Data Manajemen Sistem',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isEditing)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.edit, color: Color(0xFF0B8A00)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Perbarui detail dokumen yang dipilih.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B8A00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _buildTextField(
              controller: _numberController,
              label: 'Nomor Dokumen',
              hint: 'Masukkan nomor dokumen',
              validator: (value) => value == null || value.isEmpty
                  ? 'Nomor dokumen wajib diisi'
                  : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              label: 'Nama Dokumen',
              hint: 'Masukkan nama dokumen',
              validator: (value) => value == null || value.isEmpty
                  ? 'Nama dokumen wajib diisi'
                  : null,
            ),
            const SizedBox(height: 12),
            _buildDropdownField(
              label: 'Jenis Dokumen',
              value: _selectedType,
              items: widget.typeOptions,
              hint: 'Masukkan jenis dokumen',
              onChanged: (option) {
                if (option != null) {
                  setState(() => _selectedType = option);
                }
              },
            ),
            const SizedBox(height: 12),
            _buildDropdownField(
              label: 'PIC',
              value: _selectedPic,
              items: widget.picOptions,
              hint: 'Masukkan nama PIC',
              onChanged: (option) {
                if (option != null) {
                  setState(() => _selectedPic = option);
                }
              },
            ),
            const SizedBox(height: 12),
            _buildDateField(),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _linkController,
              label: 'Link Dokumen',
              hint: 'Masukkan link dokumen',
              validator: (value) => value == null || value.isEmpty
                  ? 'Link dokumen wajib diisi'
                  : null,
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: _inputDecoration('Pilih status dokumen'),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: const [
                    DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                    DropdownMenuItem(value: 'Tidak Aktif', child: Text('Tidak Aktif')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7CB342),
                      side: const BorderSide(color: Color(0xFF7CB342)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B8A00),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(_isEditing ? 'Perbarui' : 'Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(hint),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required MansisLookupOption value,
    required List<MansisLookupOption> items,
    required String hint,
    required ValueChanged<MansisLookupOption?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<MansisLookupOption>(
          value: value,
          decoration: _inputDecoration(hint),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: items
              .map((option) => DropdownMenuItem(
            value: option,
            child: Text(option.name),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tanggal Pengesahan',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _dateController,
          readOnly: true,
          decoration: _inputDecoration('DD/MM/YYYY').copyWith(
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          validator: (_) => _selectedDate == null
              ? 'Tanggal pengesahan wajib diisi'
              : null,
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? now,
              firstDate: DateTime(now.year - 10),
              lastDate: DateTime(now.year + 5),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
                _dateController.text =
                "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
              });
            }
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0B8A00), width: 1.2),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final data = MansisFormData(
      id: widget.initialData?.id,
      number: _numberController.text.trim(),
      name: _nameController.text.trim(),
      type: _selectedType,
      pic: _selectedPic,
      approvalDate: _selectedDate,
      status: _status,
      link: _linkController.text.trim(),
    );

    await widget.onSubmit(data);
    if (mounted) setState(() => _isSaving = false);
  }
}