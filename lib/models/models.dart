class Article {
  final int id;
  final String uri;
  final String title;
  final String excerpt;
  final String? image;
  final String date;
  final String author;
  final int views;
  final String? labelName;
  final String? labelUri;

  // detail
  final String? content;
  final String? pdf;
  final List<ArticleCategoryRef> categories;
  final List<Referensi> referensi;
  final List<Article> related;
  final List<Comment> comments;

  Article({
    required this.id,
    required this.uri,
    required this.title,
    this.excerpt = '',
    this.image,
    this.date = '',
    this.author = '',
    this.views = 0,
    this.labelName,
    this.labelUri,
    this.content,
    this.pdf,
    this.categories = const [],
    this.referensi = const [],
    this.related = const [],
    this.comments = const [],
  });

  factory Article.fromJson(Map<String, dynamic> j) => Article(
        id: j['id'] ?? 0,
        uri: j['uri'] ?? '',
        title: j['title'] ?? '',
        excerpt: j['excerpt'] ?? '',
        image: j['image'],
        date: j['date'] ?? '',
        author: j['author'] ?? '',
        views: j['views'] ?? 0,
        labelName: j['label']?['name'],
        labelUri: j['label']?['uri'],
        content: j['content'],
        pdf: j['pdf'],
        categories: (j['categories'] as List? ?? [])
            .map((e) => ArticleCategoryRef.fromJson(e))
            .toList(),
        referensi: (j['referensi'] as List? ?? []).map((e) => Referensi.fromJson(e)).toList(),
        related: (j['related'] as List? ?? []).map((e) => Article.fromJson(e)).toList(),
        comments: (j['comments'] as List? ?? []).map((e) => Comment.fromJson(e)).toList(),
      );

  Map<String, dynamic> toBookmark() => {
        'id': id,
        'uri': uri,
        'title': title,
        'excerpt': excerpt,
        'image': image,
        'date': date,
        'author': author,
        'views': views,
      };
}

class ArticleCategoryRef {
  final String? categoryName;
  final String? categoryUri;
  final String? subName;
  final String? subUri;
  ArticleCategoryRef({this.categoryName, this.categoryUri, this.subName, this.subUri});
  factory ArticleCategoryRef.fromJson(Map<String, dynamic> j) => ArticleCategoryRef(
        categoryName: j['category']?['name'],
        categoryUri: j['category']?['uri'],
        subName: j['sub_category']?['name'],
        subUri: j['sub_category']?['uri'],
      );
}

class Referensi {
  final String title;
  final String? uri;
  final bool external;
  Referensi({required this.title, this.uri, this.external = false});
  factory Referensi.fromJson(Map<String, dynamic> j) =>
      Referensi(title: j['title'] ?? '', uri: j['uri'], external: j['external'] ?? false);
}

class Comment {
  final String name;
  final String fill;
  final String? reply;
  final String date;
  Comment({required this.name, required this.fill, this.reply, required this.date});
  factory Comment.fromJson(Map<String, dynamic> j) =>
      Comment(name: j['name'] ?? '', fill: j['fill'] ?? '', reply: j['reply'], date: j['date'] ?? '');
}

class Category {
  final int id;
  final String name;
  final String uri;
  final int count;
  final List<Category> subs;
  Category({required this.id, required this.name, required this.uri, this.count = 0, this.subs = const []});
  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        uri: j['uri'] ?? '',
        count: j['count'] ?? j['sub_count'] ?? 0,
        subs: (j['subs'] as List? ?? [])
            .map((e) => Category(id: e['id'] ?? 0, name: e['name'] ?? '', uri: e['uri'] ?? ''))
            .toList(),
      );
}

class Question {
  final int id;
  final String name;
  final String question;
  final String? answer;
  final String date;
  Question({required this.id, required this.name, required this.question, this.answer, required this.date});
  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        question: j['question'] ?? '',
        answer: j['answer'],
        date: j['date'] ?? '',
      );
}

class InfoPage {
  final String id;
  final String name;
  final String content;
  InfoPage({required this.id, required this.name, this.content = ''});
  factory InfoPage.fromJson(Map<String, dynamic> j) =>
      InfoPage(id: j['id'] ?? '', name: j['name'] ?? '', content: j['content'] ?? '');
}

class HomeData {
  final List<Article> slider;
  final List<Article> latest;
  final List<Article> headline;
  final List<Article> pilihanAtas;
  final List<Article> pilihanBawah;
  final List<Category> categories;
  final List<Category> labels;
  final bool showPertanyaan;
  final bool showYoutube;

  HomeData({
    required this.slider,
    required this.latest,
    required this.headline,
    required this.pilihanAtas,
    required this.pilihanBawah,
    required this.categories,
    required this.labels,
    required this.showPertanyaan,
    required this.showYoutube,
  });

  factory HomeData.fromJson(Map<String, dynamic> j) => HomeData(
        slider: (j['slider'] as List).map((e) => Article.fromJson(e)).toList(),
        latest: (j['latest'] as List).map((e) => Article.fromJson(e)).toList(),
        headline: (j['headline'] as List).map((e) => Article.fromJson(e)).toList(),
        pilihanAtas: (j['pilihan_atas'] as List? ?? []).map((e) => Article.fromJson(e)).toList(),
        pilihanBawah: (j['pilihan_bawah'] as List? ?? []).map((e) => Article.fromJson(e)).toList(),
        categories: (j['categories'] as List).map((e) => Category.fromJson(e)).toList(),
        labels: (j['labels'] as List).map((e) => Category.fromJson(e)).toList(),
        showPertanyaan: j['show_pertanyaan'] ?? true,
        showYoutube: j['show_youtube'] ?? true,
      );
}

class Paged<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;
  Paged({required this.data, required this.currentPage, required this.lastPage, required this.total});
}
