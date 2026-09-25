import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/admin_auth.dart';
import 'admin_ads_screen.dart';
import 'admin_article_list_screen.dart';
import 'admin_comment_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_layout_screen.dart';
import 'admin_question_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_slider_screen.dart';
import 'admin_taxonomy_screen.dart';
import 'admin_ui.dart';
import 'admin_user_screen.dart';

class _Destination {
  final String label;
  final IconData icon;
  final bool adminOnly;
  final Widget Function() build;
  const _Destination(this.label, this.icon, this.build, {this.adminOnly = false});
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _all = <_Destination>[
    _Destination('Dashboard', Icons.dashboard_outlined, _dashboard),
    _Destination('Artikel', Icons.article_outlined, _articles),
    _Destination('Slider', Icons.view_carousel_outlined, _slider, adminOnly: true),
    _Destination('Iklan', Icons.campaign_outlined, _ads, adminOnly: true),
    _Destination('Tata Letak', Icons.dashboard_customize_outlined, _layout, adminOnly: true),
    _Destination('Komentar', Icons.mode_comment_outlined, _comments, adminOnly: true),
    _Destination('Pertanyaan', Icons.help_outline, _questions, adminOnly: true),
    _Destination('Label', Icons.label_outline, _labels, adminOnly: true),
    _Destination('Kategori', Icons.folder_outlined, _categories, adminOnly: true),
    _Destination('Sub Kategori', Icons.folder_open_outlined, _subCategories, adminOnly: true),
    _Destination('Pengguna', Icons.people_outline, _users, adminOnly: true),
    _Destination('Informasi', Icons.info_outline, _info, adminOnly: true),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuth>();
    final dests = _all.where((d) => !d.adminOnly || auth.isAdmin).toList();
    final index = _index.clamp(0, dests.length - 1);
    final current = dests[index];

    return Scaffold(
      appBar: AppBar(
        title: Text(current.label, style: const TextStyle(fontFamily: 'serif')),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              if (await adminConfirm(context, 'Keluar dari panel admin?')) {
                if (context.mounted) await context.read<AdminAuth>().signOut();
              }
            },
          ),
        ],
      ),
      drawer: _drawer(context, auth, dests, index),
      body: current.build(),
    );
  }

  Widget _drawer(BuildContext context, AdminAuth auth, List<_Destination> dests, int index) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.line)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('PANEL ADMIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: AppTheme.brand)),
                const SizedBox(height: 6),
                Text(auth.name, style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                const SizedBox(height: 2),
                Text(auth.isAdmin ? 'Administrator' : 'Penulis', style: const TextStyle(fontSize: 12, color: AppTheme.ink500)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (var i = 0; i < dests.length; i++)
                    ListTile(
                      selected: i == index,
                      selectedTileColor: AppTheme.tint,
                      leading: Icon(dests[i].icon, color: i == index ? AppTheme.brand : AppTheme.ink600, size: 20),
                      title: Text(dests[i].label,
                          style: TextStyle(fontWeight: i == index ? FontWeight.w700 : FontWeight.w500, color: AppTheme.ink)),
                      onTap: () {
                        setState(() => _index = i);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _dashboard() => const AdminDashboardScreen();
  static Widget _articles() => const AdminArticleListScreen();
  static Widget _slider() => const AdminSliderScreen();
  static Widget _ads() => const AdminAdsScreen();
  static Widget _layout() => const AdminLayoutScreen();
  static Widget _comments() => const AdminCommentScreen();
  static Widget _questions() => const AdminQuestionScreen();
  static Widget _labels() => const AdminTaxonomyScreen(kind: TaxonomyKind.label);
  static Widget _categories() => const AdminTaxonomyScreen(kind: TaxonomyKind.category);
  static Widget _subCategories() => const AdminTaxonomyScreen(kind: TaxonomyKind.subCategory);
  static Widget _users() => const AdminUserScreen();
  static Widget _info() => const AdminSettingsScreen();
}
