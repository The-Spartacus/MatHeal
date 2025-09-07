import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  final String id;
  final String title;
  final String content;
  final String authorId; // Only doctor ID
  final String specialization;
  final DateTime datePublished;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.specialization,
    required this.datePublished,
  });

  // Convert Firestore document to Article object
  factory Article.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Article(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      specialization: data['specialization'] ?? '',
      datePublished: (data['datePublished'] as Timestamp).toDate(),
    );
  }

  // Convert Article object to Map (for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'specialization': specialization,
      'datePublished': Timestamp.fromDate(datePublished),
    };
  }
}
