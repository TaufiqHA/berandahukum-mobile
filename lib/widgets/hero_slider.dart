import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import 'widgets.dart';

class HeroSlider extends StatefulWidget {
  final List<Article> items;
  final void Function(Article) onTap;

  /// Jarak teks dari tepi layar agar tetap sejajar dengan konten halaman,
  /// sementara gambar dibuat full-bleed (menyentuh tepi).
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
        _controller.animateToPage(next,
            duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final a = widget.items[i];
              return GestureDetector(
                onTap: () => widget.onTap(a),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: MagazineImage(path: a.image, expand: true)),
                    const SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: widget.inset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SOROTAN', style: TextStyle(color: AppTheme.brand, fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 10.5)),
                          const SizedBox(height: 4),
                          Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700, height: 1.15, color: AppTheme.ink)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (widget.items.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.items.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? AppTheme.brand : Colors.transparent,
                  border: Border.all(color: active ? AppTheme.brand : const Color(0xFF9B9A93)),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
