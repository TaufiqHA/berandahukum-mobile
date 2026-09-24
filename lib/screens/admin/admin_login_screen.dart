import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import '../../state/admin_auth.dart';
import 'admin_ui.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Email dan kata sandi wajib diisi.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AdminApi.login(_email.text.trim(), _password.text);
      final token = res['token'] as String;
      final user = (res['user'] as Map).cast<String, dynamic>();
      if (!mounted) return;
      await context.read<AdminAuth>().signIn(token, user);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Masuk Admin', style: TextStyle(fontFamily: 'serif'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const SizedBox(height: 8),
          const Text('Panel Admin', style: TextStyle(fontFamily: 'serif', fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.ink)),
          const SizedBox(height: 6),
          const Text('Masuk untuk mengelola artikel, kategori, dan moderasi.',
              style: TextStyle(color: AppTheme.ink600, fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.brand.withValues(alpha: .08), border: Border.all(color: AppTheme.brand)),
              child: Text(_error!, style: const TextStyle(color: AppTheme.brandStrong, fontSize: 13)),
            ),
            const SizedBox(height: 16),
          ],
          AdminField(
            label: 'Email / Username',
            child: TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              decoration: adminInputDecoration('nama@contoh.com'),
            ),
          ),
          AdminField(
            label: 'Kata Sandi',
            child: TextField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
              decoration: adminInputDecoration('••••••••').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.ink500),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('MASUK'),
          ),
        ],
      ),
    );
  }
}
