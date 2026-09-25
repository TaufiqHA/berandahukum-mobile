import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/html_utils.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../state/bookmarks.dart';
import '../widgets/site_widgets.dart';
import '../widgets/widgets.dart';

class ArticleScreen extends StatefulWidget {
  final String uri;
  final String? initialTitle;
  const ArticleScreen({super.key, required this.uri, this.initialTitle});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  Article? _article;
  String? _error;
  bool _loading = true;

  final _name = TextEditingController();
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final a = await Api.article(widget.uri);
      setState(() {
        _article = a;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    if (_name.text.trim().isEmpty || _comment.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await Api.submitComment(_article!.id, _name.text.trim(), _comment.text.trim());
      if (!mounted) return;
      _name.clear();
      _comment.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentar terkirim & menunggu verifikasi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<Bookmarks>();
    final a = _article;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTitle ?? 'Artikel', maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'serif', fontSize: 17)),
        actions: [
          if (a != null)
            IconButton(
              tooltip: bookmarks.has(a.id) ? 'Hapus dari simpanan' : 'Simpan',
              onPressed: () {
                bookmarks.toggle(a);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(bookmarks.has(a.id) ? 'Disimpan ke Bookmark' : 'Dihapus dari Bookmark')));
              },
              icon: Icon(bookmarks.has(a.id) ? Icons.bookmark : Icons.bookmark_border,
                  color: bookmarks.has(a.id) ? AppTheme.brand : AppTheme.ink),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _buildArticle(a!),
    );
  }

  Widget _buildArticle(Article a) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Iklan di atas artikel (maks 2, dari panel admin)
        for (final b in a.adsAtas) ...[
          AdBannerView(
            ad: b,
            padding: const EdgeInsets.only(bottom: 12),
            onArticle: (uri) => Navigator.push(
                context, MaterialPageRoute(builder: (_) => ArticleScreen(uri: uri))),
          ),
        ],
        if (a.labelName != null)
          Text(a.labelName!.toUpperCase(), style: const TextStyle(color: AppTheme.brand, fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 11)),
        const SizedBox(height: 6),
        Text(a.title, style: const TextStyle(fontFamily: 'serif', fontSize: 27, fontWeight: FontWeight.w700, height: 1.12, color: AppTheme.ink)),
        const SizedBox(height: 12),
        Text(a.author,
            style: const TextStyle(fontSize: 11.5, letterSpacing: .4, fontWeight: FontWeight.w600, color: AppTheme.ink600)),
        const SizedBox(height: 2),
        Text('${formatDate(a.date)}   ·   ${a.views}x dibaca',
            style: const TextStyle(fontSize: 11, letterSpacing: .4, color: AppTheme.ink500)),
        const SizedBox(height: 12),
        _ShareRow(uri: a.uri, title: a.title),
        const Divider(height: 28),
        if (a.image != null) ...[MagazineImage(path: a.image, aspectRatio: 16 / 9), const SizedBox(height: 16)],
        HtmlWidget(
          sanitizeCmsHtml(a.content),
          textStyle: const TextStyle(fontSize: 16.5, height: 1.7, color: AppTheme.ink),
          onTapUrl: (url) {
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            return true;
          },
        ),
        if (a.pdf != null && a.pdf!.isNotEmpty) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse(a.pdf!), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Buka Dokumen PDF'),
          ),
        ],
        if (a.referensi.isNotEmpty) ...[
          const Divider(height: 36),
          const Text('REFERENSI BACAAN', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 12)),
          const SizedBox(height: 10),
          ...a.referensi.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: r.uri == null ? null : () => launchUrl(Uri.parse(r.uri!), mode: LaunchMode.externalApplication),
                  child: Text('• ${r.title}', style: const TextStyle(color: AppTheme.brandStrong, height: 1.4)),
                ),
              )),
        ],
        if (a.related.isNotEmpty) ...[
          const Divider(height: 36),
          const Text('ARTIKEL TERKAIT', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 12)),
          const SizedBox(height: 8),
          ...a.related.map((rel) => StoryCard(
                a: rel,
                compact: true,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleScreen(uri: rel.uri, initialTitle: rel.title))),
              )),
        ],
        const Divider(height: 36),
        const Text('KOMENTAR', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 12)),
        const SizedBox(height: 8),
        if (a.comments.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Belum ada komentar.', style: TextStyle(color: AppTheme.ink500)))
        else
          ...a.comments.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(formatDate(c.date), style: const TextStyle(fontSize: 10.5, color: AppTheme.ink500)),
                    const SizedBox(height: 6),
                    HtmlWidget(sanitizeCmsHtml(c.fill), textStyle: const TextStyle(fontSize: 14.5, height: 1.5, color: AppTheme.ink)),
                    if (c.reply != null && c.reply!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8, left: 12),
                        padding: const EdgeInsets.only(left: 12),
                        decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppTheme.brand, width: 3))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Jawaban:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          const SizedBox(height: 2),
                          HtmlWidget(sanitizeCmsHtml(c.reply), textStyle: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.ink600)),
                        ]),
                      ),
                  ],
                ),
              )),
        const SizedBox(height: 8),
        TextField(controller: _name, decoration: const InputDecoration(hintText: 'Nama')),
        const SizedBox(height: 10),
        TextField(controller: _comment, maxLines: 3, decoration: const InputDecoration(hintText: 'Tulis komentar…')),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _sending ? null : _sendComment,
          child: Text(_sending ? 'MENGIRIM…' : 'KIRIM KOMENTAR'),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off, size: 40, color: AppTheme.ink500),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.ink600)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('COBA LAGI')),
          ]),
        ),
      );
}

/// Baris tombol bagikan (Twitter/Facebook/WhatsApp/Telegram) — meniru situs.
class _ShareRow extends StatelessWidget {
  final String uri;
  final String title;
  const _ShareRow({required this.uri, required this.title});

  @override
  Widget build(BuildContext context) {
    final url = Uri.encodeComponent('${AppConfig.host}/a/$uri');
    final text = Uri.encodeComponent(title);
    final links = <String, String>{
      'Twitter': 'https://twitter.com/intent/tweet?url=$url&text=$text',
      'Facebook': 'https://www.facebook.com/sharer/sharer.php?u=$url',
      'WhatsApp': 'https://wa.me/?text=$text%20$url',
      'Telegram': 'https://t.me/share/url?url=$url&text=$text',
    };
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        const Text('Bagikan:', style: TextStyle(fontSize: 11.5, color: AppTheme.ink500)),
        for (final e in links.entries)
          InkWell(
            onTap: () => launchUrl(Uri.parse(e.value), mode: LaunchMode.externalApplication),
            child: Text(e.key,
                style: const TextStyle(fontSize: 12, color: AppTheme.brandStrong, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
