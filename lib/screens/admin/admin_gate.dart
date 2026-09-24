import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/admin_auth.dart';
import 'admin_login_screen.dart';
import 'admin_shell.dart';

/// Menampilkan panel admin bila sudah masuk, atau halaman login bila belum.
class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuth>();
    return auth.isLoggedIn ? const AdminShell() : const AdminLoginScreen();
  }
}
