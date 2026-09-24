import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import 'admin_article_comments_screen.dart';
import 'admin_rich_text_editor.dart';
import 'admin_ui.dart';

/// Moderasi seluruh komentar.
class AdminCommentScreen extends StatefulWidget {
  const AdminCommentScreen({super.key});
  @override
  State<AdminCommentScreen> createState() => _AdminCommentScreenState();
}

class _AdminCommentScreenState extends State<AdminCommentScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _items = <Map<String, dynamic>>[];
  int _page = 1;
  int _lastPage = 1;
  int? _status;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (_loading || _page > _lastPage)) return;
    if (reset) {
      _page = 1;
      _lastPage = 1;
    }
    setState(() => _loading = true);
    try {
      final res = await AdminApi.comments(q: _search.text.trim().isEmpty ? null : _search.text.trim(), status: _status, page: _page);
      final data = ((res['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
      setState(() {
        if (reset || _page == 1) _items.clear();
        _items.addAll(data);
        _lastPage = res['last_page'] as int? ?? 1;
        _page++;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(Future<void> Function() action, String message) async {
    try {
      await action();
      if (mounted) adminSnack(context, message);
      await _load(reset: true);
    } catch (e) {
      if (mounted) adminSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _reply(Map<String, dynamic> row) async {
    final editorKey = GlobalKey<AdminRichTextEditorState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Balas Komentar', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700, fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(row['fill'].toString(), style: const TextStyle(fontSize: 13, color: AppTheme.ink600, height: 1.4)),
              const SizedBox(height: 12),
              AdminRichTextEditor(
                key: editorKey,
                initialHtml: row['reply']?.toString() ?? '',
                placeholder: 'Tulis balasan…',
                minHeight: 150,
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              try {
                await AdminApi.commentReply(row['id'] as int, editorKey.currentState?.html ?? '');
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) adminSnack(context, e.toString(), error: true);
              }
            },
            child: const Text('KIRIM'),
          ),
        ],
      ),
    );
    if (ok == true) await _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(reset: true),
              decoration: adminInputDecoration('Cari komentar / nama').copyWith(prefixIcon: const Icon(Icons.search, size: 20)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: () => _load(reset: true), icon: const Icon(Icons.refresh)),
        ]),
      ),
      SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final f in const [null, 0, 1])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f == null ? 'Semua' : (f == 0 ? 'Pending' : 'Tampil')),
                  selected: _status == f,
                  onSelected: (_) {
                    setState(() => _status = f);
                    _load(reset: true);
                  },
                ),
              ),
          ],
        ),
      ),
      Expanded(child: _body()),
    ]);
  }

  Widget _body() {
    if (_items.isEmpty && _loading) return const AdminLoading();
    if (_items.isEmpty && _error != null) return AdminErrorView(message: _error!, onRetry: () => _load(reset: true));
    if (_items.isEmpty) return const AdminEmpty(message: 'Belum ada komentar.');
    return RefreshIndicator(
      color: const Color(0xFFC1121F),
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        itemCount: _items.length + (_page <= _lastPage ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i >= _items.length) return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: AdminLoading());
          final row = _items[i];
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AdminCommentTile(
              row: row,
              onPublish: (id) => _act(() => AdminApi.commentPublish(id), 'Komentar ditampilkan.'),
              onUnpublish: (id) => _act(() => AdminApi.commentUnpublish(id), 'Komentar disembunyikan.'),
              onDelete: (id) async {
                if (await adminConfirm(context, 'Hapus komentar ini?')) {
                  await _act(() => AdminApi.commentDelete(id), 'Komentar dihapus.');
                }
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _reply(row),
                icon: const Icon(Icons.reply, size: 18),
                label: const Text('Balas'),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
