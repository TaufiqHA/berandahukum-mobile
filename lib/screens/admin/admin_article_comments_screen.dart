import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import 'admin_ui.dart';

/// Moderasi komentar untuk satu artikel.
class AdminArticleCommentsScreen extends StatefulWidget {
  final int articleId;
  final String title;
  const AdminArticleCommentsScreen({super.key, required this.articleId, required this.title});

  @override
  State<AdminArticleCommentsScreen> createState() => _AdminArticleCommentsScreenState();
}

class _AdminArticleCommentsScreenState extends State<AdminArticleCommentsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final res = await AdminApi.articleComments(widget.articleId);
    return ((res['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _act(Future<void> Function() action, String message) async {
    try {
      await action();
      if (mounted) adminSnack(context, message);
      await _reload();
    } catch (e) {
      if (mounted) adminSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Komentar Artikel', style: TextStyle(fontFamily: 'serif'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(widget.title,
              style: const TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.ink)),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const AdminLoading();
              if (snap.hasError) return AdminErrorView(message: snap.error.toString(), onRetry: _reload);
              final rows = snap.data!;
              if (rows.isEmpty) return const AdminEmpty(message: 'Belum ada komentar.');
              return RefreshIndicator(
                color: AppTheme.brand,
                onRefresh: _reload,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => AdminCommentTile(
                    row: rows[i],
                    onPublish: (id) => _act(() => AdminApi.commentPublish(id), 'Komentar ditampilkan.'),
                    onUnpublish: (id) => _act(() => AdminApi.commentUnpublish(id), 'Komentar disembunyikan.'),
                    onDelete: (id) async {
                      if (await adminConfirm(context, 'Hapus komentar ini?')) {
                        await _act(() => AdminApi.commentDelete(id), 'Komentar dihapus.');
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Kartu komentar dengan aksi moderasi (dipakai juga di layar moderasi global).
class AdminCommentTile extends StatelessWidget {
  final Map<String, dynamic> row;
  final void Function(int id)? onPublish;
  final void Function(int id)? onUnpublish;
  final void Function(int id)? onDelete;
  const AdminCommentTile({super.key, required this.row, this.onPublish, this.onUnpublish, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final id = row['id'] as int;
    final status = row['status'] as int? ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(row['name'].toString(),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.ink)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(border: Border.all(color: (status == 1 ? const Color(0xFF1B7A3D) : AppTheme.brand).withValues(alpha: .5))),
            child: Text(status == 1 ? 'TAMPIL' : 'PENDING',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: .5, color: status == 1 ? const Color(0xFF1B7A3D) : AppTheme.brand)),
          ),
        ]),
        if (row['article_title'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(row['article_title'].toString(), style: const TextStyle(fontSize: 11.5, color: AppTheme.ink500)),
          ),
        const SizedBox(height: 6),
        Text(row['fill'].toString(), style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppTheme.ink600)),
        if ((row['reply'] ?? '').toString().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.tint, border: Border.all(color: AppTheme.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('BALASAN ADMIN',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10.5, letterSpacing: .8, color: AppTheme.brand)),
              const SizedBox(height: 4),
              HtmlWidget(
                row['reply'].toString(),
                textStyle: const TextStyle(fontSize: 12.5, height: 1.45, color: AppTheme.ink600),
              ),
            ]),
          ),
        Wrap(spacing: 0, children: [
          if (status == 1 && onUnpublish != null) TextButton(onPressed: () => onUnpublish!(id), child: const Text('Sembunyikan')),
          if (status != 1 && onPublish != null) TextButton(onPressed: () => onPublish!(id), child: const Text('Tampilkan')),
          if (onDelete != null) TextButton(onPressed: () => onDelete!(id), child: const Text('Hapus', style: TextStyle(color: AppTheme.brand))),
        ]),
      ]),
    );
  }
}
