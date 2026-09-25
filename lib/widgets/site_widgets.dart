import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
class CategoryAccordion extends StatelessWidget {
  final List<Category> categories;
  final void Function(Category category) onCategory;
  final void Function(Category category, Category sub) onSub;
  final EdgeInsets padding;

  const CategoryAccordion({
    super.key,
    required this.categories,
    required this.onCategory,
    required this.onSub,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Column(children: [for (final c in categories) _card(context, c)]),
    );
  }

  Widget _card(BuildContext context, Category c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: () => onCategory(c),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.brand, width: 3),
                bottom: BorderSide(color: AppTheme.line),
              ),
            ),
            child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.ink)),
          ),
        ),
        if (c.subs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final s in c.subs)
                  InkWell(
                    onTap: () => onSub(c, s),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(border: Border.all(color: AppTheme.line)),
                      child: Text(s.name, style: const TextStyle(fontSize: 14, color: AppTheme.ink600)),
                    ),
                  ),
              ],
            ),
          ),
      ]),
    );
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
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Informasi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
              const SizedBox(height: 10),
              for (final i in _info)
                InkWell(
                  onTap: () => widget.onInfo('${i['id']}', i['name'] as String? ?? ''),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(i['name'] as String? ?? '', style: const TextStyle(fontSize: 14, color: AppTheme.ink600)),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ikuti Kami', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final s in _sosial)
                    InkWell(
                      onTap: () => launchUrl(Uri.parse(s['url'] as String), mode: LaunchMode.externalApplication),
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(border: Border.all(color: AppTheme.line), color: Colors.white),
                        child: Text(_label(s['name'] as String? ?? ''),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.ink600)),
                      ),
                    ),
                ],
              ),
            ]),
          ),
        ]),
      ]),
    );
  }

  String _label(String name) {
    final n = name.toLowerCase();
    if (n.contains('face')) return 'f';
    if (n.contains('insta')) return 'ig';
    if (n.contains('twit')) return 'x';
    if (n.contains('you')) return 'yt';
    if (n.contains('rss')) return 'rss';
    return name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
  }
}
