import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import 'admin_ui.dart';

/// Referensi bacaan untuk sebuah artikel.
class AdminReferensiScreen extends StatefulWidget {
  final int articleId;
  final String title;
  const AdminReferensiScreen({super.key, required this.articleId, required this.title});

  @override
  State<AdminReferensiScreen> createState() => _AdminReferensiScreenState();
}

class _AdminReferensiScreenState extends State<AdminReferensiScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final res = await AdminApi.referensi(widget.articleId);
    return ((res['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _add() async {
    final count = (await _future).length;
    if (!mounted) return;
    var sumber = 'ext';
    var urutan = TextEditingController(text: '${count + 1}');
    final judul = TextEditingController();
    final link = TextEditingController();
    int? selectedArticleId;
    String? selectedArticleTitle;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Tambah Referensi', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AdminField(
                label: 'Sumber',
                child: DropdownButtonFormField<String>(
                  initialValue: sumber,
                  decoration: adminInputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'ext', child: Text('Eksternal (link)')),
                    DropdownMenuItem(value: 'int', child: Text('Artikel internal')),
                  ],
                  onChanged: (v) => setDialog(() => sumber = v ?? 'ext'),
                ),
              ),
              if (sumber == 'ext') ...[
                AdminField(label: 'Judul', child: TextField(controller: judul, decoration: adminInputDecoration())),
                AdminField(label: 'Link', child: TextField(controller: link, decoration: adminInputDecoration('https://'))),
              ] else ...[
                AdminField(
                  label: 'Cari Artikel',
                  child: TextButton.icon(
                    onPressed: () async {
                      final picked = await _pickArticle(context);
                      if (picked != null) {
                        setDialog(() {
                          selectedArticleId = picked['id'] as int;
                          selectedArticleTitle = picked['title'].toString();
                        });
                      }
                    },
                    icon: const Icon(Icons.search),
                    label: Text(selectedArticleTitle ?? 'Pilih artikel…'),
                  ),
                ),
              ],
              AdminField(label: 'Urutan', child: TextField(controller: urutan, keyboardType: TextInputType.number, decoration: adminInputDecoration())),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                try {
                  if (sumber == 'ext' && judul.text.trim().isEmpty) return;
                  if (sumber == 'int' && selectedArticleId == null) return;
                  await AdminApi.referensiAdd(widget.articleId, {
                    'sumber': sumber,
                    'urutan': int.tryParse(urutan.text) ?? 0,
                    if (sumber == 'ext') 'judul': judul.text.trim(),
                    if (sumber == 'ext') 'link': link.text.trim(),
                    if (sumber == 'int') 'article_id': selectedArticleId,
                  });
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (context.mounted) adminSnack(context, e.toString(), error: true);
                }
              },
              child: const Text('SIMPAN'),
            ),
          ],
        ),
      ),
    );
    urutan.dispose();
    judul.dispose();
    link.dispose();
    if (ok == true) await _reload();
  }

  Future<Map<String, dynamic>?> _pickArticle(BuildContext context) async {
    final search = TextEditingController();
    List<Map<String, dynamic>> results = const [];
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Pilih Artikel', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700, fontSize: 18)),
          content: SizedBox(
            width: 380,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: search,
                onSubmitted: (_) async {
                  final res = await AdminApi.articles(q: search.text.trim(), page: 1);
                  setDialog(() => results = ((res['data'] as List?) ?? const []).cast<Map<String, dynamic>>());
                },
                decoration: adminInputDecoration('Ketik judul lalu Enter').copyWith(prefixIcon: const Icon(Icons.search, size: 20)),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final a in results)
                      ListTile(
                        dense: true,
                        title: Text(a['title'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.pop(context, a),
                      ),
                  ],
                ),
              ),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Referensi Bacaan', style: TextStyle(fontFamily: 'serif'))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.brand,
        foregroundColor: Colors.white,
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
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
              if (rows.isEmpty) return const AdminEmpty(message: 'Belum ada referensi.');
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = rows[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text('${r['urutan']}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.brand)),
                    title: Text(r['title']?.toString() ?? '-', style: const TextStyle(fontSize: 14, color: AppTheme.ink)),
                    subtitle: Text(r['sumber'] == 'int' ? 'Internal · /a/${r['uri'] ?? ''}' : 'Eksternal · ${r['uri'] ?? ''}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppTheme.ink500)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.brand),
                      onPressed: () async {
                        if (await adminConfirm(context, 'Hapus referensi ini?')) {
                          try {
                            await AdminApi.referensiDelete(r['id'] as int);
                            await _reload();
                          } catch (e) {
                            if (context.mounted) adminSnack(context, e.toString(), error: true);
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
