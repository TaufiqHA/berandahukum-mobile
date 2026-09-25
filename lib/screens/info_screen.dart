import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/cms_html.dart';
import 'article_screen.dart';

class InfoListScreen extends StatefulWidget {
  const InfoListScreen({super.key});
  @override
  State<InfoListScreen> createState() => _InfoListScreenState();
}

class _InfoListScreenState extends State<InfoListScreen> {
  late Future<Map<String, dynamic>> _future;
  @override
  void initState() {
    super.initState();
    _future = Api.settings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informasi', style: TextStyle(fontFamily: 'serif'))),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.brand));
          }
          if (snap.hasError) return Center(child: Text(snap.error.toString()));
          final info = (snap.data!['info'] as List).cast<Map<String, dynamic>>();
          final sosial = (snap.data!['sosial'] as List).cast<Map<String, dynamic>>();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              for (final p in info)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p['name'], style: const TextStyle(fontFamily: 'serif', fontSize: 17, fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.ink500),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InfoDetailScreen(id: p['id'], name: p['name']))),
                ),
              if (sosial.isNotEmpty) ...[
                const Divider(height: 32),
                const Text('IKUTI KAMI', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 12)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: sosial
                      .map((s) => OutlinedButton(
                            onPressed: () => launchUrl(Uri.parse(s['url']), mode: LaunchMode.externalApplication),
                            child: Text(s['name']),
                          ))
                      .toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class InfoDetailScreen extends StatefulWidget {
  final String id;
  final String name;
  const InfoDetailScreen({super.key, required this.id, required this.name});
  @override
  State<InfoDetailScreen> createState() => _InfoDetailScreenState();
}

class _InfoDetailScreenState extends State<InfoDetailScreen> {
  late Future<InfoPage> _future;
  @override
  void initState() {
    super.initState();
    _future = Api.info(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name, style: const TextStyle(fontFamily: 'serif'))),
      body: FutureBuilder<InfoPage>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.brand));
          }
          if (snap.hasError) return Center(child: Text(snap.error.toString()));
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              CmsHtml(
                snap.data!.content,
                textStyle: const TextStyle(fontSize: 16, height: 1.7),
                onArticle: (uri) => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => ArticleScreen(uri: uri))),
              ),
            ],
          );
        },
      ),
    );
  }
}
