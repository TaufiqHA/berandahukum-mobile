import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import 'widgets.dart';

/// Carousel sorotan: gambar + bar caption (judul & penulis) menempel di bawah,
/// dengan tombol panah — meniru slider pada situs mobile.
class HeroSlider extends StatefulWidget {
  final List<Article> items;
  final void Function(Article) onTap;

  /// Disimpan untuk kompatibilitas; caption kini full-bleed.
  final double inset;

  const HeroSlider({super.key, required this.items, required this.onTap, this.inset = 0});

  @override
  State<HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<HeroSlider> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        final next = (_index + 1) % widget.items.length;
        _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_index + delta) % widget.items.length;
    _controller.animateToPage(next < 0 ? next + widget.items.length : next,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.of(context).size.width;
    final imageHeight = width * 9 / 16;
    const captionHeight = 96.0;

    return SizedBox(
      height: imageHeight + captionHeight,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final a = widget.items[i];
              return GestureDetector(
                onTap: () => widget.onTap(a),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: MagazineImage(path: a.image, expand: true),
                    ),
                    Container(
                      height: captionHeight,
                      color: AppTheme.ink,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            a.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700, height: 1.15, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          if (a.author.isNotEmpty)
                            Text(a.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (widget.items.length > 1) ...[
            Positioned(
              left: 0,
              top: 0,
              height: imageHeight,
              child: Center(child: _arrow(Icons.chevron_left, () => _go(-1))),
            ),
            Positioned(
              right: 0,
              top: 0,
              height: imageHeight,
              child: Center(child: _arrow(Icons.chevron_right, () => _go(1))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => Material(
        color: Colors.black.withValues(alpha: .5),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: 44, height: 60, child: Icon(icon, color: Colors.white, size: 30)),
        ),
      );
}
