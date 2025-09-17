import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final DateTime datePublished;
  final String? imageUrl; // ✅ ADDED: To store the article's image link

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.datePublished,
    this.imageUrl, // ✅ ADDED
  });

  factory Article.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Article(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      datePublished: (data['datePublished'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'], // ✅ ADDED
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'datePublished': datePublished,
      'imageUrl': imageUrl, // ✅ ADDED
    };
  }
}
