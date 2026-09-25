import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import '../../state/app_events.dart';
import '../../widgets/widgets.dart';
import 'admin_ui.dart';

/// Pengaturan iklan yang disisipkan di antara kartu kategori beranda.
/// Khusus aplikasi mobile (posisi 100 pada tbl_ads).
class AdminAdsScreen extends StatefulWidget {
  const AdminAdsScreen({super.key});
  @override
  State<AdminAdsScreen> createState() => _AdminAdsScreenState();
}

class _AdminAdsScreenState extends State<AdminAdsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  List<Map<String, dynamic>> _categories = const [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final results = await Future.wait([AdminApi.ads(), AdminApi.categories()]);
    final all = ((results[1]['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
    // Hanya kategori yang tampil di beranda (category_show = yes), karena
    // iklan antar-kategori hanya muncul pada kartu kategori beranda.
    _categories = all.where((c) => c['show'] == true).toList();
    return ((results[0]['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  String _placementName(dynamic id, dynamic position) {
    if (position == 101) return 'Bawah beranda';
    if (position == 102) return 'Atas beranda';
    if (position == 103) return 'Atas artikel';
    if (id == null) return 'Bergilir di celah kategori';
    for (final c in _categories) {
      if (c['id'] == id) return 'Setelah: ${c['name']}';
    }
    return 'Setelah: kategori #$id';
  }

  Future<void> _reload() async {
    setState(() { _future = _load(); });
    await _future;
  }

  Future<void> _remove(Map<String, dynamic> row) async {
    if (!await adminConfirm(context, 'Hapus iklan ini?')) return;
    try {
      await AdminApi.deleteAd(row['id'] as int);
      requestHomeReload();
      if (mounted) adminSnack(context, 'Iklan dihapus.');
      await _reload();
    } catch (e) {
      if (mounted) adminSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _openForm([Map<String, dynamic>? row]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminAdFormScreen(row: row, categories: _categories)),
    );
    if (saved == true) {
      requestHomeReload();
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.brand,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const AdminLoading();
          if (snap.hasError) return AdminErrorView(message: snap.error.toString(), onRetry: _reload);
          final rows = snap.data!;
          if (rows.isEmpty) {
            return const AdminEmpty(
                message: 'Belum ada iklan antar-kategori.\nTekan tombol + untuk menambah.');
          }
          return RefreshIndicator(
            color: AppTheme.brand,
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final row = rows[i];
                final link = (row['link'] ?? '').toString();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    SizedBox(width: 96, child: MagazineImage(path: row['image']?.toString(), aspectRatio: 16 / 9)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_placementName(row['category_id'], row['position']),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.brand)),
                        const SizedBox(height: 2),
                        Text(link.isEmpty ? 'Tanpa link' : link,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: link.isEmpty ? AppTheme.ink500 : AppTheme.ink600)),
                      ]),
                    ),
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _openForm(row)),
                    IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.brand),
                        onPressed: () => _remove(row)),
                  ]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AdminAdFormScreen extends StatefulWidget {
  final Map<String, dynamic>? row;
  final List<Map<String, dynamic>> categories;
  const AdminAdFormScreen({super.key, this.row, this.categories = const []});

  @override
  State<AdminAdFormScreen> createState() => _AdminAdFormScreenState();
}

class _AdminAdFormScreenState extends State<AdminAdFormScreen> {
  final _link = TextEditingController();
  String? _pickedImage;
  String? _existingImage;
  int? _categoryId;
  int _position = 100; // 100 = antar kategori, 101 = bawah beranda
  bool _saving = false;

  bool get _isEdit => widget.row != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _link.text = (widget.row!['link'] ?? '').toString();
      _existingImage = widget.row!['image']?.toString();
      final pos = widget.row!['position'];
      if (pos != null) _position = int.tryParse('$pos') ?? 100;
      final cat = widget.row!['category_id'];
      _categoryId = cat is int ? cat : (cat == null ? null : int.tryParse('$cat'));
    }
    _retrieveLostImage();
  }

  /// Android bisa membunuh activity saat galeri terbuka; pulihkan gambar yang
  /// sudah dipilih agar tidak hilang.
  Future<void> _retrieveLostImage() async {
    try {
      final lost = await ImagePicker().retrieveLostData();
      final files = lost.files;
      if (!mounted || lost.isEmpty || files == null || files.isEmpty) return;
      setState(() => _pickedImage = files.first.path);
    } catch (_) {
      // Abaikan: tidak ada data yang perlu dipulihkan.
    }
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (picked != null && mounted) setState(() => _pickedImage = picked.path);
    } catch (e) {
      if (mounted) adminSnack(context, 'Gagal memilih gambar: $e', error: true);
    }
  }

  Future<void> _save() async {
    if (_pickedImage == null && (_existingImage == null || _existingImage!.isEmpty)) {
      adminSnack(context, 'Gambar iklan wajib dipilih.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await AdminApi.saveAd(
        id: widget.row?['id'] as int?,
        link: _link.text.trim(),
        position: _position,
        categoryId: _position == 100 ? _categoryId : null,
        imagePath: _pickedImage,
      );
      if (mounted) {
        adminSnack(context, _isEdit ? 'Iklan diubah.' : 'Iklan disimpan.');
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
        title: Text(_isEdit ? 'Ubah Iklan' : 'Tambah Iklan', style: const TextStyle(fontFamily: 'serif')),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('SIMPAN', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          const Text(
            'Atas beranda: di antara banner atas dan carousel (maks. 2). '
            'Atas artikel: di atas judul pada halaman artikel (maks. 2). '
            'Antar kategori: di antara kartu kategori, bisa dipasangkan ke kategori tertentu. '
            'Bawah beranda: sebelum footer (maks. 3).',
            style: TextStyle(fontSize: 12.5, color: AppTheme.ink500),
          ),
          const SizedBox(height: 16),
          AdminField(
            label: 'Penempatan',
            child: DropdownButtonFormField<int>(
              initialValue: _position,
              isExpanded: true,
              decoration: adminInputDecoration(),
              items: const [
                DropdownMenuItem(value: 100, child: Text('Antar kategori beranda')),
                DropdownMenuItem(value: 102, child: Text('Atas beranda (maks. 2)')),
                DropdownMenuItem(value: 101, child: Text('Bawah beranda (maks. 3)')),
                DropdownMenuItem(value: 103, child: Text('Atas artikel (maks. 2)')),
              ],
              onChanged: (v) => setState(() => _position = v ?? 100),
            ),
          ),
          if (_position == 100)
            AdminField(
              label: 'Tampilkan di bawah kategori',
              child: DropdownButtonFormField<int?>(
                initialValue: _categoryId,
                isExpanded: true,
                decoration: adminInputDecoration(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Bergilir di celah kategori')),
                  for (final c in widget.categories)
                    DropdownMenuItem(value: c['id'] as int, child: Text(c['name'].toString())),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ),
          AdminField(
            label: 'Gambar Iklan',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_pickedImage != null)
                Image.file(File(_pickedImage!),
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Text('Gambar tidak dapat ditampilkan.',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.brand)))
              else if (_existingImage != null && _existingImage!.isNotEmpty)
                MagazineImage(path: _existingImage, aspectRatio: 16 / 9),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(_pickedImage == null && _existingImage == null ? 'Pilih Gambar' : 'Ganti Gambar'),
              ),
            ]),
          ),
          AdminField(
            label: 'Link (opsional)',
            child: TextField(
              controller: _link,
              keyboardType: TextInputType.url,
              decoration: adminInputDecoration('https://… atau tautan artikel'),
            ),
          ),
        ],
      ),
    );
  }
}
