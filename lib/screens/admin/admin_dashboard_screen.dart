import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import 'admin_ui.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminApi.dashboard();
  }

  Future<void> _refresh() async {
    setState(() { _future = AdminApi.dashboard(); });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const AdminLoading();
        if (snap.hasError) return AdminErrorView(message: snap.error.toString(), onRetry: _refresh);
        final d = snap.data!;
        return RefreshIndicator(
          color: AppTheme.brand,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _statGrid(d),
              const SizedBox(height: 24),
              _rankCard('Artikel per Kategori', (d['per_kategori'] as List?) ?? const []),
              const SizedBox(height: 16),
              _rankCard('Artikel per Penulis', (d['per_penulis'] as List?) ?? const []),
            ],
          ),
        );
      },
    );
  }

  Widget _statGrid(Map<String, dynamic> d) {
    final stats = <List<String>>[
      ['Total Artikel', '${d['total_artikel'] ?? 0}'],
      ['Publish', '${d['total_publish'] ?? 0}'],
      ['Draft', '${d['total_draft'] ?? 0}'],
      ['Komentar', '${d['total_komentar'] ?? 0}'],
      ['Komentar Pending', '${d['total_komentar_nonver'] ?? 0}'],
      ['Pertanyaan', '${d['total_pertanyaan'] ?? 0}'],
      ['Pertanyaan Belum', '${d['pertanyaan_belum'] ?? 0}'],
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 640 ? 4 : 2;
      final width = (c.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final s in stats)
            SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.tint, border: Border.all(color: AppTheme.line)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s[0].toUpperCase(),
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: .8, color: AppTheme.ink600)),
                  const SizedBox(height: 8),
                  Text(s[1], style: const TextStyle(fontFamily: 'serif', fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                ]),
              ),
            ),
        ],
      );
    });
  }

  Widget _rankCard(String title, List items) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppTheme.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.line))),
          child: Text(title.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppTheme.ink)),
        ),
        if (items.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data.', style: TextStyle(color: AppTheme.ink500)))
        else
          for (final it in items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Expanded(child: Text('${it['name']}', style: const TextStyle(fontSize: 13.5, color: AppTheme.ink))),
                Text('${it['jumlah']}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.brand)),
              ]),
            ),
      ]),
    );
  }
}
