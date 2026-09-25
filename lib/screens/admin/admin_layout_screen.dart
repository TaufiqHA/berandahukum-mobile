import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import 'admin_ui.dart';

/// Tata letak halaman beranda: urutkan section + tampil/sembunyikan.
class AdminLayoutScreen extends StatefulWidget {
  const AdminLayoutScreen({super.key});
  @override
  State<AdminLayoutScreen> createState() => _AdminLayoutScreenState();
}

class _AdminLayoutScreenState extends State<AdminLayoutScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  List<Map<String, dynamic>> _rows = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final res = await AdminApi.layout();
    final rows = ((res['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
    _rows = List.of(rows);
    return rows;
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await AdminApi.saveLayout(
          _rows.map((r) => {'key': r['key'], 'enabled': r['enabled'] == true}).toList());
      if (mounted) adminSnack(context, 'Tata letak disimpan.');
    } catch (e) {
      if (mounted) adminSnack(context, e.toString(), error: true);
      await _reload();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggle(int i, bool value) {
    setState(() => _rows[i]['enabled'] = value);
    _save();
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final item = _rows.removeAt(oldIndex);
      _rows.insert(newIndex, item);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const AdminLoading();
          if (snap.hasError) return AdminErrorView(message: snap.error.toString(), onRetry: _reload);
          if (_rows.isEmpty) return const AdminEmpty();
          return Column(children: [
            Container(
              width: double.infinity,
              color: AppTheme.tint,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(children: [
                const Expanded(
                  child: Text('Seret untuk mengurutkan, tombol untuk tampil/sembunyi.',
                      style: TextStyle(fontSize: 12, color: AppTheme.ink600)),
                ),
                if (_saving)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brand)),
              ]),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: _rows.length,
                // ignore: deprecated_member_use
                onReorder: _onReorder,
                itemBuilder: (context, i) {
                  final r = _rows[i];
                  return ListTile(
                    key: ValueKey(r['key']),
                    contentPadding: EdgeInsets.zero,
                    leading: ReorderableDragStartListener(
                      index: i,
                      child: const Icon(Icons.drag_handle, color: AppTheme.ink500),
                    ),
                    title: Text(r['label'].toString(),
                        style: const TextStyle(fontFamily: 'serif', fontSize: 15.5, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                    subtitle: Text('${r['scope']}'.toUpperCase(),
                        style: const TextStyle(fontSize: 10.5, letterSpacing: .8, color: AppTheme.ink500)),
                    trailing: Switch(
                      value: r['enabled'] == true,
                      activeThumbColor: AppTheme.brand,
                      onChanged: (v) => _toggle(i, v),
                    ),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}
