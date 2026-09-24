import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class Api {
  static const _timeout = Duration(seconds: 25);

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('${AppConfig.apiRoot}/$path').replace(queryParameters: q?.isEmpty ?? true ? null : q);
  }

  static Future<Map<String, dynamic>> _get(String path, [Map<String, dynamic>? query]) async {
    try {
      final res = await http.get(_uri(path, query)).timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      throw ApiException('Gagal memuat (${res.statusCode})');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server.');
    }
  }

  static Future<List<dynamic>> _getList(String path, [Map<String, dynamic>? query]) async {
    try {
      final res = await http.get(_uri(path, query)).timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      }
      throw ApiException('Gagal memuat (${res.statusCode})');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server.');
    }
  }

  static Future<void> _post(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(_uri(path), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final m = jsonDecode(res.body);
        throw ApiException(m['message']?.toString() ?? 'Gagal mengirim (${res.statusCode})');
      } catch (_) {
        throw ApiException('Gagal mengirim (${res.statusCode})');
      }
    }
  }

  static Paged<T> _paged<T>(Map<String, dynamic> j, T Function(dynamic) map) => Paged<T>(
        data: (j['data'] as List).map(map).toList(),
        currentPage: j['current_page'] ?? 1,
        lastPage: j['last_page'] ?? 1,
        total: j['total'] ?? 0,
      );

  static Future<HomeData> home() async => HomeData.fromJson(await _get('home'));

  static Future<Paged<Article>> articles({
    String? category,
    String? subCategory,
    String? label,
    String? q,
    String sort = 'date',
    int page = 1,
    int perPage = 12,
  }) async {
    final j = await _get('articles', {
      if (category != null) 'category': category,
      if (subCategory != null) 'sub_category': subCategory,
      if (label != null) 'label': label,
      if (q != null && q.isNotEmpty) 'q': q,
      'sort': sort,
      'page': page,
      'per_page': perPage,
    });
    return _paged(j, (e) => Article.fromJson(e));
  }

  static Future<Article> article(String uri) async => Article.fromJson(await _get('articles/$uri'));

  static Future<List<Category>> categories() async =>
      (await _getList('categories')).map((e) => Category.fromJson(e)).toList();

  static Future<List<Category>> labels() async =>
      (await _getList('labels')).map((e) => Category.fromJson(e)).toList();

  static Future<Paged<Article>> taxonomyArticles(String kind, String uri, int page) async {
    final j = await _get('$kind/$uri', {'page': page, 'per_page': 12});
    return _paged(j['articles'], (e) => Article.fromJson(e));
  }

  static Future<Paged<Question>> questions(int page) async =>
      _paged(await _get('questions', {'page': page, 'per_page': 15}), (e) => Question.fromJson(e));

  static Future<void> submitQuestion(String name, String email, String question) =>
      _post('questions', {'name': name, 'email': email, 'question': question});

  static Future<void> submitComment(int articleId, String name, String fill) =>
      _post('comments', {'article_id': articleId, 'name': name, 'fill': fill});

  static Future<Map<String, dynamic>> settings() async => _get('settings');

  static Future<InfoPage> info(String id) async => InfoPage.fromJson(await _get('settings/$id'));
}
