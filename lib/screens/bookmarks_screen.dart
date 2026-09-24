import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/bookmarks.dart';
import '../widgets/widgets.dart';
import 'home_screen.dart' show openArticle;

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<Bookmarks>();
    return Scaffold(
      appBar: AppBar(title: const Text('Disimpan', style: TextStyle(fontFamily: 'serif'))),
      body: bookmarks.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Belum ada artikel tersimpan.\nKetuk ikon bookmark di halaman artikel untuk menyimpannya.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppTheme.ink500)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: bookmarks.items.length,
              itemBuilder: (context, i) {
                final a = bookmarks.items[i];
                return Dismissible(
                  key: ValueKey(a.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AppTheme.brand,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (_) => bookmarks.toggle(a),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: StoryCard(a: a, onTap: () => openArticle(context, a)),
                  ),
                );
              },
            ),
    );
  }
}
