import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import 'admin_ui.dart';

/// Pengaturan: halaman informasi + opsi tampilan pertanyaan.
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminApi.settings();
  }

  Future<void> _reload() async {
    setState(() => _future = AdminApi.settings());
    await _future;
  }

  Future<void> _openForm([Map<String, dynamic>? row]) async {
    final name = TextEditingController(text: row?['name']?.toString() ?? '');
    final content = TextEditingController(text: row?['content']?.toString() ?? '');
    final urutan = TextEditingController(text: '${row?['urutan'] ?? 0}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${row == null ? 'Tambah' : 'Ubah'} Informasi',
            style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700, fontSize: 18)),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AdminField(label: 'Nama', child: TextField(controller: name, decoration: adminInputDecoration())),
              AdminField(
                label: 'Isi (HTML)',
                child: TextField(controller: content, minLines: 5, maxLines: 10, decoration: adminInputDecoration()),
              ),
              AdminField(label: 'Urutan', child: TextField(controller: urutan, keyboardType: TextInputType.number, decoration: adminInputDecoration())),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              try {
                if (name.text.trim().isEmpty) return;
                await AdminApi.saveSetting(
                  id: row?['id'] as int?,
                  name: name.text.trim(),
                  content: content.text,
                  urutan: int.tryParse(urutan.text) ?? 0,
                );
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) adminSnack(context, e.toString(), error: true);
              }
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
    name.dispose();
    content.dispose();
    urutan.dispose();
    if (ok == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const AdminLoading();
        if (snap.hasError) return AdminErrorView(message: snap.error.toString(), onRetry: _reload);
        final rows = ((snap.data!['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
        final sys = (snap.data!['sys'] as Map?)?.cast<String, dynamic>() ?? const {};
        return RefreshIndicator(
          color: AppTheme.brand,
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _sysCard(sys),
              const SizedBox(height: 24),
              Row(children: [
                const Expanded(
                  child: Text('HALAMAN INFORMASI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppTheme.ink600)),
                ),
                TextButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.add, size: 18), label: const Text('Tambah')),
              ]),
              for (final r in rows)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(r['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
                  subtitle: Text('urutan ${r['urutan'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppTheme.ink500)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _openForm(r)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.brand),
                      onPressed: () async {
                        if (await adminConfirm(context, 'Hapus "${r['name']}"?')) {
                          try {
                            await AdminApi.deleteSetting(r['id'] as int);
                            await _reload();
                          } catch (e) {
                            if (context.mounted) adminSnack(context, e.toString(), error: true);
                          }
                        }
                      },
                    ),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _sysCard(Map<String, dynamic> sys) {
    var showPertanyaan = sys['show_pertanyaan'] == true;
    var showYoutube = sys['show_youtube'] == true;
    return StatefulBuilder(builder: (context, setLocal) {
      return Container(
        decoration: BoxDecoration(border: Border.all(color: AppTheme.line)),
        child: Column(children: [
          SwitchListTile(
            title: const Text('Tampilkan menu Pertanyaan', style: TextStyle(fontSize: 14)),
            value: showPertanyaan,
            activeThumbColor: AppTheme.brand,
            onChanged: (v) => setLocal(() => showPertanyaan = v),
          ),
          SwitchListTile(
            title: const Text('Tampilkan YouTube', style: TextStyle(fontSize: 14)),
            value: showYoutube,
            activeThumbColor: AppTheme.brand,
            onChanged: (v) => setLocal(() => showYoutube = v),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  try {
                    await AdminApi.saveSysSettings(showPertanyaan: showPertanyaan, showYoutube: showYoutube);
                    if (context.mounted) adminSnack(context, 'Pengaturan disimpan.');
                  } catch (e) {
                    if (context.mounted) adminSnack(context, e.toString(), error: true);
                  }
                },
                child: const Text('SIMPAN PENGATURAN'),
              ),
            ),
          ),
        ]),
      );
    });
  }
}
