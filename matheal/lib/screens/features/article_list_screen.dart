import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:matheal/screens/article_detail_screen.dart';
import '../../models/article_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  bool showSaved = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text(showSaved ? "Saved Articles" : "Health Articles"),
        actions: [
          IconButton(
            icon: Icon(showSaved ? Icons.bookmark : Icons.bookmark_border, color: showSaved ? AppColors.primary : null),
            onPressed: () => setState(() => showSaved = !showSaved),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: showSaved
            ? FirebaseFirestore.instance.collection("users").doc(currentUser.uid).collection("savedArticles").orderBy("datePublished", descending: true).snapshots()
            : FirebaseFirestore.instance.collection("articles").orderBy("datePublished", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final articles = snapshot.data!.docs.map((doc) => Article.fromDocument(doc)).toList();
          if (articles.isEmpty) return Center(child: Text(showSaved ? "No saved articles yet." : "No articles available."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return FutureBuilder<UserModel?>(
                future: FirestoreService().getDoctorById(article.authorId),
                builder: (context, docSnap) {
                  if (!docSnap.hasData) return const SizedBox.shrink();
                  final doctor = docSnap.data!;
                  return _buildArticleCard(article, doctor, currentUser.uid);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildArticleCard(Article article, UserModel doctor, String currentUserId) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article, author: doctor))),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(doctor.avatarUrl ?? '')),
              title: Text("Dr. ${doctor.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(doctor.specialization ?? 'Specialist'),
            ),

            // Image
            if (article.imageUrl != null)
              Image.network(
                article.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(height: 200, child: Icon(Icons.image_not_supported)),
              ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                article.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Content Preview
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                article.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection("users").doc(currentUserId).collection("savedArticles").doc(article.id).snapshots(),
                builder: (context, savedSnap) {
                  final isSaved = savedSnap.hasData && savedSnap.data!.exists;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.grey),
                        onPressed: () { /* TODO: Implement Share */ },
                      ),
                      IconButton(
                        icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? AppColors.primary : Colors.grey),
                        onPressed: () async {
                          final ref = FirebaseFirestore.instance.collection("users").doc(currentUserId).collection("savedArticles").doc(article.id);
                          if (isSaved) {
                            await ref.delete();
                          } else {
                            await ref.set(article.toMap());
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

