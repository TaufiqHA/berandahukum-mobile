import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import 'admin_ui.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});
  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final res = await AdminApi.users();
    return ((res['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  Future<void> _reload() async {
    setState(() { _future = _load(); });
    await _future;
  }

  Future<void> _openForm([Map<String, dynamic>? row]) async {
    final name = TextEditingController(text: row?['name']?.toString() ?? '');
    final email = TextEditingController(text: row?['email']?.toString() ?? '');
    final password = TextEditingController();
    var level = row?['level']?.toString() ?? 'user';
    var obscure = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text('${row == null ? 'Tambah' : 'Ubah'} Pengguna',
              style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AdminField(label: 'Nama', child: TextField(controller: name, decoration: adminInputDecoration())),
              AdminField(label: 'Email / Username', child: TextField(controller: email, decoration: adminInputDecoration())),
              AdminField(
                label: row == null ? 'Kata Sandi' : 'Kata Sandi (kosongkan bila tidak diubah)',
                child: TextField(
                  controller: password,
                  obscureText: obscure,
                  decoration: adminInputDecoration().copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setDialog(() => obscure = !obscure),
                    ),
                  ),
                ),
              ),
              AdminField(
                label: 'Level',
                child: DropdownButtonFormField<String>(
                  initialValue: level,
                  decoration: adminInputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('Penulis')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                  ],
                  onChanged: (v) => setDialog(() => level = v ?? 'user'),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                try {
                  if (name.text.trim().isEmpty || email.text.trim().isEmpty) return;
                  if (row == null && password.text.isEmpty) return;
                  await AdminApi.saveUser(
                    id: row?['id'] as int?,
                    name: name.text.trim(),
                    email: email.text.trim(),
                    level: level,
                    password: password.text,
                  );
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (context.mounted) adminSnack(context, e.toString(), error: true);
                }
              },
              child: const Text('SIMPAN'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    email.dispose();
    password.dispose();
    if (ok == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.brand,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        child: const Icon(Icons.person_add_alt),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const AdminLoading();
          if (snap.hasError) return AdminErrorView(message: snap.error.toString(), onRetry: _reload);
          final rows = snap.data!;
          if (rows.isEmpty) return const AdminEmpty();
          return RefreshIndicator(
            color: AppTheme.brand,
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final u = rows[i];
                final isAdmin = u['level'] == 'admin';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.tint,
                    foregroundColor: AppTheme.brand,
                    child: Text((u['name'].toString().isNotEmpty ? u['name'].toString()[0] : '?').toUpperCase()),
                  ),
                  title: Text(u['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
                  subtitle: Text(u['email'].toString(), style: const TextStyle(fontSize: 12, color: AppTheme.ink500)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(border: Border.all(color: (isAdmin ? AppTheme.brand : AppTheme.ink500).withValues(alpha: .5))),
                      child: Text(isAdmin ? 'ADMIN' : 'PENULIS',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: .5, color: isAdmin ? AppTheme.brand : AppTheme.ink500)),
                    ),
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _openForm(u)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.brand),
                      onPressed: () async {
                        if (await adminConfirm(context, 'Hapus pengguna "${u['name']}"?')) {
                          try {
                            await AdminApi.deleteUser(u['id'] as int);
                            await _reload();
                          } catch (e) {
                            if (context.mounted) adminSnack(context, e.toString(), error: true);
                          }
                        }
                      },
                    ),
                  ]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
