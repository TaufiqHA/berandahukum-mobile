import 'package:flutter/material.dart';

import '../../core/theme.dart';

void adminSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? AppTheme.brand : AppTheme.ink,
  ));
}

Future<bool> adminConfirm(BuildContext context, String title, [String? message]) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title, style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700)),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya')),
      ],
    ),
  );
  return result ?? false;
}

class AdminLoading extends StatelessWidget {
  const AdminLoading({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: AppTheme.brand));
}

class AdminErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AdminErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 40, color: AppTheme.brand),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('COBA LAGI')),
          ],
        ]),
      ),
    );
  }
}

class AdminEmpty extends StatelessWidget {
  final String message;
  const AdminEmpty({super.key, this.message = 'Belum ada data.'});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, style: const TextStyle(color: AppTheme.ink500)),
        ),
      );
}

class AdminField extends StatelessWidget {
  final String label;
  final Widget child;
  const AdminField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppTheme.ink600)),
        const SizedBox(height: 6),
        child,
      ]),
    );
  }
}

InputDecoration adminInputDecoration([String? hint]) => InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: AppTheme.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: AppTheme.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: AppTheme.ink)),
    );

Color adminStatusColor(int status) => status == 1 ? const Color(0xFF1B7A3D) : AppTheme.ink500;

String adminArticleStatusLabel(int status) => switch (status) {
      1 => 'Publish',
      2 => 'Draft',
      _ => 'Tidak aktif',
    };
