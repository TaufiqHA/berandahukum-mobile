import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import '../../widgets/widgets.dart';
import 'admin_rich_text_editor.dart';
import 'admin_ui.dart';

class AdminArticleFormScreen extends StatefulWidget {
  final int? articleId;
  const AdminArticleFormScreen({super.key, this.articleId});

  @override
  State<AdminArticleFormScreen> createState() => _AdminArticleFormScreenState();
}

class _AdminArticleFormScreenState extends State<AdminArticleFormScreen> {
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _date = TextEditingController();
  final _editorKey = GlobalKey<AdminRichTextEditorState>();
  String _contentHtml = '';

  List<Map<String, dynamic>> _labels = const [];
  List<Map<String, dynamic>> _categories = const [];
  int? _labelId;
  int? _categoryId;
  int? _subCategoryId;
  int _status = 2;
  bool _headline = false;
  String? _pickedImage;
  String? _existingImage;
  bool _removeImage = false;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.articleId != null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final opt = await AdminApi.options();
      _labels = ((opt['labels'] as List?) ?? const []).cast<Map<String, dynamic>>();
      _categories = ((opt['categories'] as List?) ?? const []).cast<Map<String, dynamic>>();

      if (_isEdit) {
        final res = await AdminApi.article(widget.articleId!);
        final a = (res['data'] as Map).cast<String, dynamic>();
        _title.text = a['title']?.toString() ?? '';
        _author.text = a['author']?.toString() ?? '';
        _date.text = a['date']?.toString() ?? '';
        _contentHtml = a['content']?.toString() ?? '';
        _labelId = (a['label_id'] as int?) ?? 0;
        _categoryId = a['category_id'] as int?;
        _subCategoryId = a['sub_category_id'] as int?;
        _status = a['status'] as int? ?? 2;
        _headline = a['headline'] == true;
        _existingImage = a['image']?.toString();
        if (_labelId == 0) _labelId = null;
      } else {
        _date.text = DateTime.now().toString().split('.').first;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _subs {
    for (final c in _categories) {
      if (c['id'] == _categoryId) {
        return ((c['subs'] as List?) ?? const []).cast<Map<String, dynamic>>();
      }
    }
    return const [];
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _pickedImage = picked.path;
        _removeImage = false;
      });
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      adminSnack(context, 'Judul artikel wajib diisi.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await AdminApi.saveArticle(
        id: widget.articleId,
        title: _title.text.trim(),
        content: _editorKey.currentState?.html ?? '',
        labelId: _labelId,
        categoryId: _categoryId,
        subCategoryId: _subCategoryId,
        author: _author.text.trim(),
        date: _date.text.trim(),
        status: _status,
        headline: _headline,
        imagePath: _pickedImage,
        removeImage: _removeImage,
      );
      if (mounted) {
        adminSnack(context, _isEdit ? 'Artikel diubah.' : 'Artikel disimpan.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) adminSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ubah Artikel' : 'Tambah Artikel', style: const TextStyle(fontFamily: 'serif')),
        actions: [
          TextButton(
            onPressed: _saving || _loading ? null : _save,
            child: _saving
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('SIMPAN', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: _loading
          ? const AdminLoading()
          : _error != null
              ? AdminErrorView(message: _error!, onRetry: _init)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    AdminField(label: 'Judul', child: TextField(controller: _title, decoration: adminInputDecoration())),
                    AdminField(
                      label: 'Label',
                      child: DropdownButtonFormField<int?>(
                        initialValue: _labelId,
                        isExpanded: true,
                        decoration: adminInputDecoration(),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('- Tanpa label -')),
                          for (final l in _labels) DropdownMenuItem(value: l['id'] as int, child: Text(l['name'].toString())),
                        ],
                        onChanged: (v) => setState(() => _labelId = v),
                      ),
                    ),
                    AdminField(
                      label: 'Kategori',
                      child: DropdownButtonFormField<int?>(
                        initialValue: _categoryId,
                        isExpanded: true,
                        decoration: adminInputDecoration(),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('- Tanpa kategori -')),
                          for (final c in _categories) DropdownMenuItem(value: c['id'] as int, child: Text(c['name'].toString())),
                        ],
                        onChanged: (v) => setState(() {
                          _categoryId = v;
                          _subCategoryId = null;
                        }),
                      ),
                    ),
                    if (_subs.isNotEmpty)
                      AdminField(
                        label: 'Sub Kategori',
                        child: DropdownButtonFormField<int?>(
                          initialValue: _subCategoryId,
                          isExpanded: true,
                          decoration: adminInputDecoration(),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('- Tanpa sub kategori -')),
                            for (final s in _subs) DropdownMenuItem(value: s['id'] as int, child: Text(s['name'].toString())),
                          ],
                          onChanged: (v) => setState(() => _subCategoryId = v),
                        ),
                      ),
                    AdminField(label: 'Penulis', child: TextField(controller: _author, decoration: adminInputDecoration())),
                    AdminField(
                      label: 'Tanggal (YYYY-MM-DD HH:MM:SS)',
                      child: TextField(controller: _date, decoration: adminInputDecoration()),
                    ),
                    AdminField(
                      label: 'Gambar Utama',
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (_pickedImage != null)
                          Image.file(File(_pickedImage!), height: 140, fit: BoxFit.cover)
                        else if (_existingImage != null && !_removeImage)
                          MagazineImage(path: _existingImage, aspectRatio: 16 / 9),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, children: [
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: Text(_pickedImage == null && _existingImage == null ? 'Pilih Gambar' : 'Ganti Gambar'),
                          ),
                          if ((_pickedImage != null) || (_existingImage != null && !_removeImage))
                            TextButton(
                              onPressed: () => setState(() {
                                _pickedImage = null;
                                _removeImage = true;
                              }),
                              child: const Text('Hapus gambar', style: TextStyle(color: AppTheme.brand)),
                            ),
                        ]),
                      ]),
                    ),
                    Row(children: [
                      Expanded(
                        child: AdminField(
                          label: 'Status',
                          child: DropdownButtonFormField<int>(
                            initialValue: _status,
                            isExpanded: true,
                            decoration: adminInputDecoration(),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Publish')),
                              DropdownMenuItem(value: 2, child: Text('Draft')),
                            ],
                            onChanged: (v) => setState(() => _status = v ?? 2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AdminField(
                          label: 'Headline',
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Tampilkan di headline', style: TextStyle(fontSize: 13)),
                            value: _headline,
                            activeThumbColor: AppTheme.brand,
                            onChanged: (v) => setState(() => _headline = v),
                          ),
                        ),
                      ),
                    ]),
                    const Text('ISI ARTIKEL',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppTheme.ink600)),
                    const SizedBox(height: 6),
                    AdminRichTextEditor(
                      key: _editorKey,
                      initialHtml: _contentHtml,
                      placeholder: 'Tulis isi artikel…',
                      minHeight: 200,
                    ),
                  ],
                ),
    );
  }
}
