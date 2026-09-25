import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/api.dart';

/// Banner/iklan gambar: ditampilkan seukuran aslinya (dibatasi lebar layar)
/// dan diposisikan di tengah — sama seperti situs mobile.
///
/// Jika tautan banner mengarah ke artikel (`/a/...`), banner dibuka di dalam
/// aplikasi lewat [onArticle]; selain itu jatuh ke browser.
class AdBannerView extends StatelessWidget {
  final AdBanner ad;
  final EdgeInsets padding;
  final void Function(String uri)? onArticle;

  const AdBannerView({
    super.key,
    required this.ad,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.onArticle,
  });

  static String? articleUri(String? link) {
    if (link == null) return null;
    final m = RegExp(r'/(?:a|article)/([^/?#]+)').firstMatch(link);
    return m?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.media(ad.image);
    if (url.isEmpty) return const SizedBox.shrink();

    final image = CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (_, _) => const SizedBox(height: 60),
      errorWidget: (_, _, _) => const SizedBox.shrink(),
    );

    Widget child = image;
    if (ad.link != null) {
      child = InkWell(
        onTap: () {
          final uri = articleUri(ad.link);
          if (uri != null && onArticle != null) {
            onArticle!(uri);
          } else {
            launchUrl(Uri.parse(ad.link!), mode: LaunchMode.externalApplication);
          }
        },
        child: image,
      );
    }

    return Center(
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Pembatas "#" seperti pada situs.
class HashDivider extends StatelessWidget {
  final bool padded;
  const HashDivider({super.key, this.padded = true});

  @override
  Widget build(BuildContext context) {
    final row = Row(children: [
      const Text('#',
          style: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.ink600)),
      const SizedBox(width: 12),
      Expanded(child: Container(height: 1, color: AppTheme.line)),
    ]);
    return padded ? Padding(padding: const EdgeInsets.fromLTRB(20, 22, 20, 6), child: row) : row;
  }
}

/// Kartu kategori accordion: header bergaris merah + baris sub-kategori.
/// Klik header kategori membuka/menutup daftar sub-kategorinya, lalu klik
/// baris sub-kategori memunculkan dropdown berisi artikelnya.
class CategoryAccordion extends StatefulWidget {
  final List<Category> categories;
  final void Function(Article article) onArticle;
  final EdgeInsets padding;

  /// Iklan yang disisipkan di antara kartu kategori (bergilir).
  final List<AdBanner> ads;

  /// Membuka tautan iklan artikel internal di dalam aplikasi.
  final void Function(String uri)? onAdArticle;

  const CategoryAccordion({
    super.key,
    required this.categories,
    required this.onArticle,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.ads = const [],
    this.onAdArticle,
  });

  @override
  State<CategoryAccordion> createState() => _CategoryAccordionState();
}

class _CategoryAccordionState extends State<CategoryAccordion> {
  /// Kategori yang sedang dibuka (menampilkan daftar sub-kategori).
  final _openCategories = <String>{};
  final _open = <String>{};
  final _loading = <String>{};
  final _articles = <String, List<Article>>{};

  Future<void> _toggle(Category sub) async {
    final isOpen = _open.contains(sub.uri);
    setState(() {
      if (isOpen) {
        _open.remove(sub.uri);
      } else {
        _open
          ..clear()
          ..add(sub.uri);
      }
    });
    if (isOpen || _articles.containsKey(sub.uri) || _loading.contains(sub.uri)) return;

    setState(() => _loading.add(sub.uri));
    try {
      final p = await Api.taxonomyArticles('subcategories', sub.uri, 1);
      if (!mounted) return;
      setState(() => _articles[sub.uri] = p.data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _articles[sub.uri] = const []);
    } finally {
      if (mounted) setState(() => _loading.remove(sub.uri));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) return const SizedBox.shrink();

    // Iklan tanpa kategori dipakai bergilir untuk mengisi celah yang belum
    // punya iklan khusus.
    final generic = widget.ads.where((a) => a.categoryId == null).toList();
    var genericIndex = 0;

    final children = <Widget>[];
    for (var i = 0; i < widget.categories.length; i++) {
      final c = widget.categories[i];
      final isLast = i == widget.categories.length - 1;
      children.add(_card(context, c));

      // Iklan khusus kategori ini selalu tampil setelahnya; jika tidak ada,
      // isi celah (kecuali setelah kategori terakhir) dengan iklan bergilir.
      final specific = _adForCategory(c.id);
      if (specific != null) {
        children.add(_ad(specific));
      } else if (!isLast && generic.isNotEmpty) {
        children.add(_ad(generic[genericIndex++ % generic.length]));
      }
    }

    return Padding(padding: widget.padding, child: Column(children: children));
  }

  AdBanner? _adForCategory(int categoryId) {
    for (final a in widget.ads) {
      if (a.categoryId == categoryId) return a;
    }
    return null;
  }

  Widget _ad(AdBanner ad) => AdBannerView(
        ad: ad,
        padding: const EdgeInsets.only(bottom: 16),
        onArticle: widget.onAdArticle,
      );

  Widget _card(BuildContext context, Category c) {
    final canExpand = c.subs.isNotEmpty;
    final isOpen = _openCategories.contains(c.uri);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppTheme.ash, border: Border.all(color: AppTheme.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: canExpand ? () => _toggleCategory(c.uri) : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.brand, width: 3),
                bottom: BorderSide(color: AppTheme.line),
              ),
            ),
            child: Row(children: [
              Expanded(
                child: Text(c.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isOpen ? AppTheme.brand : AppTheme.ink,
                    )),
              ),
              if (canExpand)
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.arrow_drop_down, color: isOpen ? AppTheme.brand : AppTheme.ink500),
                ),
            ]),
          ),
        ),
        if (canExpand && isOpen)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [for (final s in c.subs) _sub(context, s)]),
          ),
      ]),
    );
  }

  void _toggleCategory(String uri) {
    setState(() {
      if (!_openCategories.remove(uri)) _openCategories.add(uri);
    });
  }

  Widget _sub(BuildContext context, Category s) {
    final isOpen = _open.contains(s.uri);
    final articles = _articles[s.uri];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      InkWell(
        onTap: () => _toggle(s),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: isOpen ? AppTheme.brand : AppTheme.line),
          ),
          child: Row(children: [
            Expanded(
              child: Text(s.name,
                  style: TextStyle(fontSize: 14, color: isOpen ? AppTheme.brand : AppTheme.ink600)),
            ),
            AnimatedRotation(
              turns: isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.arrow_drop_down, color: AppTheme.ink500),
            ),
          ]),
        ),
      ),
      if (isOpen)
        Container(
          decoration: const BoxDecoration(
            color: AppTheme.tint,
            border: Border(
              left: BorderSide(color: AppTheme.line),
              right: BorderSide(color: AppTheme.line),
              bottom: BorderSide(color: AppTheme.line),
            ),
          ),
          child: _loading.contains(s.uri)
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Memuat…', style: TextStyle(fontSize: 13, color: AppTheme.ink500)),
                )
              : (articles == null || articles.isEmpty)
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Belum ada artikel.', style: TextStyle(fontSize: 13, color: AppTheme.ink500)),
                    )
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      for (final a in articles)
                        InkWell(
                          onTap: () => widget.onArticle(a),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Text(a.title, style: const TextStyle(fontSize: 13.5, color: AppTheme.ink600)),
                          ),
                        ),
                    ]),
        ),
      const SizedBox(height: 12),
    ]);
  }
}

/// Footer situs: logo, hak cipta, Informasi, dan Ikuti Kami.
class SiteFooter extends StatefulWidget {
  final void Function(String id, String name) onInfo;
  const SiteFooter({super.key, required this.onInfo});

  @override
  State<SiteFooter> createState() => _SiteFooterState();
}

class _SiteFooterState extends State<SiteFooter> {
  List<Map<String, dynamic>> _info = [];
  List<Map<String, dynamic>> _sosial = [];

  @override
  void initState() {
    super.initState();
    Api.settings().then((s) {
      if (!mounted) return;
      setState(() {
        _info = (s['info'] as List? ?? []).cast<Map<String, dynamic>>();
        _sosial = (s['sosial'] as List? ?? []).cast<Map<String, dynamic>>();
      });
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      decoration: const BoxDecoration(
        color: AppTheme.tint,
        border: Border(top: BorderSide(color: AppTheme.ink, width: 4)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(children: [
        Image.asset('assets/logo.png', height: 60, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
        const SizedBox(height: 8),
        Text('copyright © 2014 - ${DateTime.now().year} berandahukum.com',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppTheme.ink600)),
        const SizedBox(height: 22),

        // Informasi — 2 kolom, teks di tengah
        const Text('Informasi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
        const SizedBox(height: 6),
        for (var i = 0; i < _info.length; i += 2)
          Row(children: [
            Expanded(child: _infoLink(_info[i])),
            Expanded(child: i + 1 < _info.length ? _infoLink(_info[i + 1]) : const SizedBox()),
          ]),

        const SizedBox(height: 28),

        // Ikuti Kami — ikon rapat, di tengah, ada jarak bawah
        const Text('Ikuti Kami', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _sosial)
              _socialBox(_socialIcon(s['name'] as String? ?? ''), s['url'] as String),
            _socialBox(FontAwesomeIcons.rss, '${AppConfig.host}/rss'),
          ],
        ),
        const SizedBox(height: 28),
      ]),
    );
  }

  Widget _infoLink(Map<String, dynamic> i) => InkWell(
        onTap: () => widget.onInfo('${i['id']}', i['name'] as String? ?? ''),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: Text(i['name'] as String? ?? '',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppTheme.ink600)),
          ),
        ),
      );

  Widget _socialBox(FaIconData icon, String url) => InkWell(
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: AppTheme.line), color: Colors.white),
          child: FaIcon(icon, size: 16, color: AppTheme.ink600),
        ),
      );

  FaIconData _socialIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('face')) return FontAwesomeIcons.facebookF;
    if (n.contains('insta')) return FontAwesomeIcons.instagram;
    if (n.contains('twit')) return FontAwesomeIcons.twitter;
    if (n.contains('you')) return FontAwesomeIcons.youtube;
    if (n.contains('rss')) return FontAwesomeIcons.rss;
    return FontAwesomeIcons.link;
  }
}
