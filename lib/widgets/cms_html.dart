import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/html_utils.dart';

/// Menampilkan HTML dari CMS dengan penanganan tautan yang benar.
///
/// Tautan ke artikel internal (`/a/<uri>` atau `/article/<uri>`) dibuka di
/// dalam aplikasi lewat [onArticle]. Tautan eksternal dibuka di browser.
/// Anchor (`#...`) diserahkan kembali ke [HtmlWidget] agar bisa di-scroll.
class CmsHtml extends StatelessWidget {
  final String html;
  final TextStyle? textStyle;

  /// Dipanggil dengan URI artikel saat tautan internal disentuh.
  final void Function(String uri)? onArticle;

  const CmsHtml(this.html, {super.key, this.textStyle, this.onArticle});

  @override
  Widget build(BuildContext context) {
    return HtmlWidget(
      sanitizeCmsHtml(html),
      textStyle: textStyle,
      onTapUrl: (url) => _onTap(url),
    );
  }

  Future<bool> _onTap(String url) async {
    // Anchor di dalam halaman: biarkan HtmlWidget menangani scroll-nya.
    if (url.trimLeft().startsWith('#')) return false;

    final articleUri = internalArticleUri(url, baseUrl: AppConfig.host);
    if (articleUri != null && onArticle != null) {
      onArticle!(articleUri);
      return true;
    }

    // Selesaikan tautan relatif terhadap host sebelum dibuka di browser.
    var target = Uri.tryParse(url);
    if (target != null && !target.hasScheme) {
      target = Uri.parse(AppConfig.host).resolveUri(target);
    }
    if (target != null) {
      try {
        await launchUrl(target, mode: LaunchMode.externalApplication);
      } catch (_) {
        // Abaikan tautan yang tidak bisa dibuka.
      }
    }
    return true;
  }
}
