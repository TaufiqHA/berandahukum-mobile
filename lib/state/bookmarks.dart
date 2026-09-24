import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Simpan artikel (bookmark) secara lokal untuk dibaca offline.
class Bookmarks extends ChangeNotifier {
  static const _key = 'bookmarks_v1';
  final List<Article> _items = [];

  List<Article> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  bool has(int id) => _items.any((a) => a.id == id);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _items
        ..clear()
        ..addAll(list.map((e) => Article.fromJson((e as Map).cast<String, dynamic>())));
      notifyListeners();
    }
  }

  Future<void> toggle(Article a) async {
    final i = _items.indexWhere((x) => x.id == a.id);
    if (i >= 0) {
      _items.removeAt(i);
    } else {
      _items.insert(0, a);
    }
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items.map((a) => a.toBookmark()).toList()));
  }
}
