import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';

class AdminApiException implements Exception {
  final String message;
  final int status;
  AdminApiException(this.message, [this.status = 0]);
  @override
  String toString() => message;
}

/// Klien API admin (panel mobile). Membutuhkan token Bearer dari login.
class AdminApi {
  static const _timeout = Duration(seconds: 30);
  static String? token;

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null) q[k] = '$v';
    });
    return Uri.parse('${AppConfig.apiRoot}/admin/$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  static Map<String, String> _headers({bool json = true}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Map<String, dynamic> _decode(http.Response res) {
    final body = res.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body is Map ? body.cast<String, dynamic>() : {'data': body};
    }
    var msg = 'Gagal (${res.statusCode})';
    if (body is Map && body['message'] != null) {
      msg = body['message'].toString();
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) msg = first.first.toString();
      }
    }
    throw AdminApiException(msg, res.statusCode);
  }

  static Future<Map<String, dynamic>> _get(String path, [Map<String, dynamic>? q]) async =>
      _decode(await http.get(_uri(path, q), headers: _headers()).timeout(_timeout));

  static Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? body]) async =>
      _decode(await http.post(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})).timeout(_timeout));

  static Future<Map<String, dynamic>> _delete(String path) async =>
      _decode(await http.delete(_uri(path), headers: _headers()).timeout(_timeout));

  static Future<Map<String, dynamic>> _multipart(String path, Map<String, String> fields, String fileField, String? filePath) async {
    final req = http.MultipartRequest('POST', _uri(path));
    req.headers.addAll(_headers(json: false));
    req.fields.addAll(fields);
    if (filePath != null) {
      req.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }
    final res = await http.Response.fromStream(await req.send().timeout(_timeout));
    return _decode(res);
  }

  // ---- Auth ----

  static Future<Map<String, dynamic>> login(String email, String password) =>
      _post('login', {'email': email, 'password': password});

  static Future<Map<String, dynamic>> me() => _get('me');

  static Future<void> logout() => _post('logout');

  // ---- Dashboard ----

  static Future<Map<String, dynamic>> dashboard() => _get('dashboard');

  // ---- Artikel ----

  static Future<Map<String, dynamic>> options() => _get('options');

  static Future<Map<String, dynamic>> articles({String? q, int? status, int? label, int page = 1}) =>
      _get('articles', {'q': q, 'status': status, 'label': label, 'page': page});

  static Future<Map<String, dynamic>> article(int id) => _get('articles/$id');

  static Future<Map<String, dynamic>> saveArticle({
    int? id,
    required String title,
    required String content,
    int? labelId,
    int? categoryId,
    int? subCategoryId,
    String? author,
    String? date,
    required int status,
    bool headline = false,
    String? imagePath,
    String? imageName,
    bool removeImage = false,
  }) {
    final fields = <String, String>{
      'title': title,
      'content': content,
      'label_id': '${labelId ?? 0}',
      'category_id': '${categoryId ?? 0}',
      'sub_category_id': '${subCategoryId ?? 0}',
      'author': author ?? '',
      'status': '$status',
      'headline': headline ? '1' : '0',
      if (date != null && date.isNotEmpty) 'article_date': date,
      if (imageName != null && imageName.isNotEmpty) 'image_name': imageName,
      if (removeImage) 'remove_image': '1',
    };
    final path = id == null ? 'articles' : 'articles/$id';
    if (imagePath != null) {
      return _multipart(path, fields, 'image', imagePath);
    }
    return _post(path, fields);
  }

  static Future<void> deleteArticle(int id) => _delete('articles/$id').then((_) {});

  static Future<void> publishArticle(int id) => _post('articles/$id/publish').then((_) {});

  static Future<void> draftArticle(int id) => _post('articles/$id/draft').then((_) {});

  static Future<Map<String, dynamic>> articleComments(int id) => _get('articles/$id/comments');

  static Future<void> commentPublish(int id) => _post('comments/$id/publish').then((_) {});

  static Future<void> commentUnpublish(int id) => _post('comments/$id/unpublish').then((_) {});

  static Future<void> commentDelete(int id) => _delete('comments/$id').then((_) {});

  static Future<Map<String, dynamic>> referensi(int id) => _get('articles/$id/referensi');

  static Future<void> referensiAdd(int articleId, Map<String, dynamic> body) =>
      _post('articles/$articleId/referensi', body).then((_) {});

  static Future<void> referensiDelete(int id) => _delete('referensi/$id').then((_) {});

  // ---- Moderasi (admin) ----

  static Future<Map<String, dynamic>> comments({String? q, int? status, int page = 1}) =>
      _get('comments', {'q': q, 'status': status, 'page': page});

  static Future<void> commentReply(int id, String reply) => _post('comments/$id/reply', {'reply': reply}).then((_) {});

  static Future<Map<String, dynamic>> questions({int? status, int page = 1}) =>
      _get('questions', {'status': status, 'page': page});

  static Future<void> answerQuestion(int id, String answer) =>
      _post('questions/$id/answer', {'answer': answer}).then((_) {});

  static Future<void> deleteQuestion(int id) => _delete('questions/$id').then((_) {});

  // ---- Data master (admin) ----

  static Future<Map<String, dynamic>> categories() => _get('categories');

  static Future<void> saveCategory({int? id, required String name, required bool show, int urutan = 0}) {
    final body = {'name': name, 'show': show, 'urutan': urutan};
    return id == null ? _post('categories', body).then((_) {}) : _post('categories/$id', body).then((_) {});
  }

  static Future<void> deleteCategory(int id) => _delete('categories/$id').then((_) {});

  static Future<Map<String, dynamic>> subCategories() => _get('sub-categories');

  static Future<void> saveSubCategory({int? id, required int categoryId, required String name, required bool show}) {
    final body = {'category_id': categoryId, 'name': name, 'show': show};
    return id == null ? _post('sub-categories', body).then((_) {}) : _post('sub-categories/$id', body).then((_) {});
  }

  static Future<void> deleteSubCategory(int id) => _delete('sub-categories/$id').then((_) {});

  static Future<Map<String, dynamic>> labels() => _get('labels');

  static Future<void> saveLabel({int? id, required String name, required bool show, int urutan = 0}) {
    final body = {'name': name, 'show': show, 'urutan': urutan};
    return id == null ? _post('labels', body).then((_) {}) : _post('labels/$id', body).then((_) {});
  }

  static Future<void> deleteLabel(int id) => _delete('labels/$id').then((_) {});

  static Future<Map<String, dynamic>> users() => _get('users');

  static Future<void> saveUser({int? id, required String name, required String email, required String level, String? password}) {
    final body = {'name': name, 'email': email, 'level': level, if (password != null && password.isNotEmpty) 'password': password};
    return id == null ? _post('users', body).then((_) {}) : _post('users/$id', body).then((_) {});
  }

  static Future<void> deleteUser(int id) => _delete('users/$id').then((_) {});

  static Future<Map<String, dynamic>> settings() => _get('settings');

  static Future<void> saveSetting({int? id, required String name, required String content, String tipe = 'info', int urutan = 0}) {
    final body = {'name': name, 'content': content, 'tipe': tipe, 'urutan': urutan};
    return id == null ? _post('settings', body).then((_) {}) : _post('settings/$id', body).then((_) {});
  }

  static Future<void> deleteSetting(int id) => _delete('settings/$id').then((_) {});

  static Future<void> saveSysSettings({required bool showPertanyaan, required bool showYoutube}) =>
      _post('settings/sys', {'show_pertanyaan': showPertanyaan, 'show_youtube': showYoutube}).then((_) {});

  // ---- Slider / sorotan beranda (admin) ----

  static Future<Map<String, dynamic>> slider() => _get('slider');

  static Future<List<Map<String, dynamic>>> sliderArticles(String q) async {
    final res = await _get('slider/articles', {'q': q});
    return ((res['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  static Future<void> saveSlider({int? id, required int articleId, int? urutan}) {
    final body = <String, dynamic>{'article_id': articleId};
    if (urutan != null) body['urutan'] = urutan;
    return id == null ? _post('slider', body).then((_) {}) : _post('slider/$id', body).then((_) {});
  }

  static Future<void> deleteSlider(int id) => _delete('slider/$id').then((_) {});

  static Future<void> saveSliderOrder(List<int> ids) => _post('slider/urutan', {'position': ids}).then((_) {});
}
