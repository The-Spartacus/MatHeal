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
        title: Text(article.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Author + Metadata
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(author.avatarUrl ?? ''),
                ),
                title: Text("By ${author.name}", style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text("$specialization at $hospital\nPublished on ${DateFormat("MMMM dd, yyyy").format(article.datePublished)}"),
              ),
              const Divider(height: 24),


              // Title
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // ✅ Article Image (moved to the bottom)
              if (article.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    article.imageUrl!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),

              // Content
              Text(
                article.content,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

