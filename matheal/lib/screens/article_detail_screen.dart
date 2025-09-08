import 'package:flutter/material.dart';
import '../../models/article_model.dart';
import '../../models/user_model.dart';
import 'package:intl/intl.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Article article;
  final UserModel author;

  const ArticleDetailScreen({
    super.key,
    required this.article,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    final specialization = author.doctorProfile?.specialization ?? '';
    final hospital = author.doctorProfile?.hospitalName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Article"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Author + Metadata
            Text(
              "By ${author.name} (${specialization.isNotEmpty ? specialization : 'Doctor'})\n$hospital",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat("MMMM dd, yyyy")
                  .format(article.datePublished ?? DateTime.now()),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  article.content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
