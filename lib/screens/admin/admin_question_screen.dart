import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import 'admin_ui.dart';

/// Moderasi pertanyaan pengunjung.
class AdminQuestionScreen extends StatefulWidget {
  const AdminQuestionScreen({super.key});
  @override
  State<AdminQuestionScreen> createState() => _AdminQuestionScreenState();
}

class _AdminQuestionScreenState extends State<AdminQuestionScreen> {
  final _scroll = ScrollController();
  final _items = <Map<String, dynamic>>[];
  int _page = 1;
  int _lastPage = 1;
  int? _status;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _load();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (_loading || _page > _lastPage)) return;
    if (reset) {
      _page = 1;
      _lastPage = 1;
    }
    setState(() => _loading = true);
    try {
      final res = await AdminApi.questions(status: _status, page: _page);
      final data = ((res['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
      setState(() {
        if (reset || _page == 1) _items.clear();
        _items.addAll(data);
        _lastPage = res['last_page'] as int? ?? 1;
        _page++;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _answer(Map<String, dynamic> row) async {
    final controller = TextEditingController(text: row['answer']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Jawab Pertanyaan', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(row['question'].toString(), style: const TextStyle(fontSize: 13.5, color: AppTheme.ink600, height: 1.5)),
          const SizedBox(height: 12),
          TextField(controller: controller, minLines: 3, maxLines: 6, decoration: adminInputDecoration('Jawaban')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              try {
                await AdminApi.answerQuestion(row['id'] as int, controller.text.trim());
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) adminSnack(context, e.toString(), error: true);
              }
            },
            child: const Text('KIRIM'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (ok == true) await _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          children: [
            for (final f in const [null, 0, 1])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f == null ? 'Semua' : (f == 0 ? 'Belum dijawab' : 'Sudah dijawab')),
                  selected: _status == f,
                  onSelected: (_) {
                    setState(() => _status = f);
                    _load(reset: true);
                  },
                ),
              ),
          ],
        ),
      ),
      Expanded(child: _body()),
    ]);
  }

  Widget _body() {
    if (_items.isEmpty && _loading) return const AdminLoading();
    if (_items.isEmpty && _error != null) return AdminErrorView(message: _error!, onRetry: () => _load(reset: true));
    if (_items.isEmpty) return const AdminEmpty(message: 'Belum ada pertanyaan.');
    return RefreshIndicator(
      color: AppTheme.brand,
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        itemCount: _items.length + (_page <= _lastPage ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i >= _items.length) return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: AdminLoading());
          final q = _items[i];
          final answered = (q['status'] as int? ?? 0) == 1;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(q['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.ink)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(border: Border.all(color: (answered ? const Color(0xFF1B7A3D) : AppTheme.brand).withValues(alpha: .5))),
                  child: Text(answered ? 'DIJAWAB' : 'BARU',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: .5, color: answered ? const Color(0xFF1B7A3D) : AppTheme.brand)),
                ),
              ]),
              const SizedBox(height: 2),
              Text('${q['email']} · ${q['date']}', style: const TextStyle(fontSize: 11, color: AppTheme.ink500)),
              const SizedBox(height: 6),
              Text(q['question'].toString(), style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppTheme.ink600)),
              if (answered && (q['answer'] ?? '').toString().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.tint, border: Border.all(color: AppTheme.line)),
                  child: Text('Jawaban: ${q['answer']}', style: const TextStyle(fontSize: 12.5, color: AppTheme.ink600)),
                ),
              Row(children: [
                TextButton(onPressed: () => _answer(q), child: Text(answered ? 'Ubah Jawaban' : 'Jawab')),
                TextButton(
                  onPressed: () async {
                    if (await adminConfirm(context, 'Hapus pertanyaan ini?')) {
                      try {
                        await AdminApi.deleteQuestion(q['id'] as int);
                        if (context.mounted) adminSnack(context, 'Pertanyaan dihapus.');
                        await _load(reset: true);
                      } catch (e) {
                        if (context.mounted) adminSnack(context, e.toString(), error: true);
                      }
                    }
                  },
                  child: const Text('Hapus', style: TextStyle(color: AppTheme.brand)),
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }
}
