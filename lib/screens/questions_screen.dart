import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/widgets.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});
  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final _items = <Question>[];
  final _scroll = ScrollController();
  int _page = 1;
  int _lastPage = 1;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
    });
  }

  Future<void> _loadMore() async {
    if (_loading || _page > _lastPage) return;
    setState(() => _loading = true);
    try {
      final p = await Api.questions(_page);
      setState(() {
        _items.addAll(p.data);
        _lastPage = p.lastPage;
        _page++;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final question = TextEditingController();
    bool sending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Kirim Pertanyaan', style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextField(controller: name, decoration: const InputDecoration(hintText: 'Nama Lengkap')),
              const SizedBox(height: 10),
              TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'Email')),
              const SizedBox(height: 10),
              TextField(controller: question, maxLines: 4, decoration: const InputDecoration(hintText: 'Pertanyaan')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        if (name.text.trim().isEmpty || email.text.trim().isEmpty || question.text.trim().isEmpty) return;
                        setSheet(() => sending = true);
                        try {
                          await Api.submitQuestion(name.text.trim(), email.text.trim(), question.text.trim());
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pertanyaan terkirim. Terima kasih!')),
                            );
                          }
                        } catch (e) {
                          setSheet(() => sending = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
                child: Text(sending ? 'MENGIRIM…' : 'KIRIM'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tanya-Jawab', style: TextStyle(fontFamily: 'serif'))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.brand,
        foregroundColor: Colors.white,
        onPressed: _openForm,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Tanya'),
      ),
      body: _items.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
          : _items.isEmpty && _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  color: AppTheme.brand,
                  onRefresh: () async {
                    setState(() {
                      _items.clear();
                      _page = 1;
                      _lastPage = 1;
                    });
                    await _loadMore();
                  },
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                    itemCount: _items.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('DAFTAR PERTANYAAN',
                              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 12.5, color: AppTheme.ink)),
                        );
                      }
                      final q = _items[i - 1];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.line))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q.question, style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('${q.name} · ${formatDate(q.date)}', style: const TextStyle(fontSize: 11, color: AppTheme.ink500)),
                            if (q.answer != null && q.answer!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 10, left: 10),
                                padding: const EdgeInsets.only(left: 12),
                                decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppTheme.brand, width: 3))),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Jawaban', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.brand)),
                                  const SizedBox(height: 2),
                                  Text(q.answer!),
                                ]),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
