import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/widgets.dart';
import 'home_screen.dart' show openArticle;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Article> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await Api.articles(q: q, perPage: 20);
      setState(() {
        _results = p.data;
        _searched = true;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari', style: TextStyle(fontFamily: 'serif'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Cari artikel…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _search),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
                : _error != null
                    ? Center(child: Text(_error!))
                    : !_searched
                        ? const Center(child: Text('Masukkan kata kunci pencarian.', style: TextStyle(color: AppTheme.ink500)))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('HASIL PENCARIAN',
                                        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 12.5, color: AppTheme.ink)),
                                    const SizedBox(height: 4),
                                    Text('“${_controller.text.trim()}”', style: const TextStyle(color: AppTheme.ink500, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _results.isEmpty
                                    ? const Center(child: Text('Tidak ada hasil.', style: TextStyle(color: AppTheme.ink500)))
                                    : ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                                        itemCount: _results.length,
                                        itemBuilder: (context, i) => Padding(
                                          padding: const EdgeInsets.only(bottom: 18),
                                          child: StoryCard(a: _results[i], onTap: () => openArticle(context, _results[i])),
                                        ),
                                      ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
