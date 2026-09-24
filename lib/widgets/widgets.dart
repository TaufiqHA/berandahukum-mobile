import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../models/models.dart';

class SectionHeader extends StatelessWidget {
  final String? number;
  final String title;
  final VoidCallback? onMore;
  final String? moreLabel;

  const SectionHeader({super.key, this.number, required this.title, this.onMore, this.moreLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.ink, width: 2)),
      ),
      child: Row(
        children: [
          if (number != null) ...[
            Text(number!, style: const TextStyle(fontFamily: 'serif', color: AppTheme.brand, fontWeight: FontWeight.w700, fontSize: 20)),
            const SizedBox(width: 12),
          ],
          Text(title.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12.5, color: AppTheme.ink)),
          const Spacer(),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: Text((moreLabel ?? 'Lihat semua').toUpperCase(),
                  style: const TextStyle(color: AppTheme.brand, fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 11.5)),
            ),
        ],
      ),
    );
  }
}

class MagazineImage extends StatelessWidget {
  final String? path;
  final double? height;
  final double aspectRatio;
  final BorderRadius? radius;

  /// Isi penuh kotak yang tersedia (crop ala cover) alih-alih mengikuti
  /// [aspectRatio]. Dipakai untuk banner agar tidak menyisakan ruang kosong.
  final bool expand;

  const MagazineImage({super.key, this.path, this.height, this.aspectRatio = 3 / 2, this.radius, this.expand = false});

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.media(path);
    final placeholder = Container(
      color: const Color(0xFFEBEAE7),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Color(0xFFC3C2BB), size: 32),
    );
    final image = url.isEmpty
        ? placeholder
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => placeholder,
          );
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.zero,
      child: expand
          ? SizedBox(width: double.infinity, height: double.infinity, child: image)
          : AspectRatio(aspectRatio: aspectRatio, child: image),
    );
  }
}

class StoryCard extends StatelessWidget {
  final Article a;
  final VoidCallback onTap;
  final bool compact;

  const StoryCard({super.key, required this.a, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final kicker = a.labelName;
    if (compact) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 104, child: MagazineImage(path: a.image, aspectRatio: 1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.w700, height: 1.2, color: AppTheme.ink)),
                    const SizedBox(height: 6),
                    Text(_date(a.date), style: const TextStyle(fontSize: 10.5, letterSpacing: .5, color: AppTheme.ink500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MagazineImage(path: a.image),
          const SizedBox(height: 10),
          if (kicker != null) ...[
            Text(kicker.toUpperCase(), style: const TextStyle(color: AppTheme.brand, fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 10.5)),
            const SizedBox(height: 4),
          ],
          Text(a.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'serif', fontSize: 17, fontWeight: FontWeight.w700, height: 1.18, color: AppTheme.ink)),
          const SizedBox(height: 6),
          Text('${_date(a.date)}${a.author.isEmpty ? '' : ' · ${a.author}'}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, letterSpacing: .4, color: AppTheme.ink500)),
        ],
      ),
    );
  }
}

String _date(String raw) {
  if (raw.isEmpty) return '';
  try {
    final d = DateTime.parse(raw);
    const bulan = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${d.day} ${bulan[d.month]} ${d.year}';
  } catch (_) {
    return raw;
  }
}

String formatDate(String raw) => _date(raw);
