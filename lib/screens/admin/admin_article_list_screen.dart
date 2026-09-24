import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import '../../widgets/widgets.dart';
import 'admin_article_comments_screen.dart';
import 'admin_article_form_screen.dart';
import 'admin_referensi_screen.dart';
import 'admin_ui.dart';

class AdminArticleListScreen extends StatefulWidget {
  const AdminArticleListScreen({super.key});
  @override
  State<AdminArticleListScreen> createState() => _AdminArticleListScreenState();
}

class _AdminArticleListScreenState extends State<AdminArticleListScreen> {
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
      final res = await AdminApi.articles(q: _search.text.trim().isEmpty ? null : _search.text.trim(), status: _status, page: _page);
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

  Future<void> _act(Future<void> Function() action, String okMessage) async {
    try {
      await action();
      if (mounted) adminSnack(context, okMessage);
      await _load(reset: true);
    } catch (e) {
      if (mounted) adminSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.brand,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tulis'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(reset: true),
                  decoration: adminInputDecoration('Cari judul artikel').copyWith(
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.ink500),
                  ),
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
                for (final f in const [null, 1, 2])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f == null ? 'Semua' : (f == 1 ? 'Publish' : 'Draft')),
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
        ],
      ),
    );
  }

  Widget _body() {
    if (_items.isEmpty && _loading) return const AdminLoading();
    if (_items.isEmpty && _error != null) return AdminErrorView(message: _error!, onRetry: () => _load(reset: true));
    if (_items.isEmpty) return const AdminEmpty(message: 'Belum ada artikel.');

    return RefreshIndicator(
      color: AppTheme.brand,
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: _items.length + (_page <= _lastPage ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: AdminLoading());
          }
          final a = _items[i];
          return _tile(a);
        },
      ),
    );
  }

  Widget _tile(Map<String, dynamic> a) {
    final status = a['status'] as int? ?? 0;
    final published = status == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 104,
            height: 70,
            child: MagazineImage(path: a['image']?.toString(), expand: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['title'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'serif', fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.2, color: AppTheme.ink)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _badge(adminArticleStatusLabel(status), adminStatusColor(status)),
                if (a['headline'] == true) _badge('Headline', AppTheme.brand),
                if ((a['label_name'] ?? '').toString().isNotEmpty) _badge(a['label_name'].toString(), AppTheme.ink600),
              ]),
              const SizedBox(height: 6),
              Text(
                '${a['category_name'] ?? '-'} · ${a['date'] ?? ''} · ${a['views'] ?? 0}x dibaca',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: AppTheme.ink500),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 2, runSpacing: 2, children: [
          _action('Ubah', Icons.edit_outlined, () => _openForm(a)),
          _action('Komentar', Icons.mode_comment_outlined, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => AdminArticleCommentsScreen(articleId: a['id'] as int, title: a['title'].toString())));
          }),
          _action('Referensi', Icons.link, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => AdminReferensiScreen(articleId: a['id'] as int, title: a['title'].toString())));
          }),
          _action(
            published ? 'Draft' : 'Publish',
            published ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            () => _act(
              () => published ? AdminApi.draftArticle(a['id'] as int) : AdminApi.publishArticle(a['id'] as int),
              published ? 'Artikel diubah ke draft.' : 'Artikel dipublish.',
            ),
          ),
          _action('Hapus', Icons.delete_outline, () async {
            if (await adminConfirm(context, 'Hapus artikel ini?')) {
              await _act(() => AdminApi.deleteArticle(a['id'] as int), 'Artikel dihapus.');
            }
          }, color: AppTheme.brand),
        ]),
      ]),
    );
  }

  Widget _action(String label, IconData icon, VoidCallback onTap, {Color color = AppTheme.ink600}) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Text(text.toUpperCase(),
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: .5, color: color)),
      );

  Future<void> _openForm([Map<String, dynamic>? row]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminArticleFormScreen(articleId: row?['id'] as int?)),
    );
    if (saved == true) await _load(reset: true);
  }
}
