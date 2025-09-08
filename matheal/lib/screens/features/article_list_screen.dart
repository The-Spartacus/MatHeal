import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:matheal/screens/article_detail_screen.dart';
import '../../models/article_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  bool showSaved = false; // toggle between all and saved

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text(showSaved ? "Saved Articles" : "Articles"),
        actions: [
          IconButton(
            icon: Icon(
              showSaved ? Icons.bookmark : Icons.bookmark_border,
              color: showSaved ? Colors.teal : null,
            ),
            tooltip: showSaved ? "Show All" : "Show Saved",
            onPressed: () {
              setState(() {
                showSaved = !showSaved;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: showSaved
            ? FirebaseFirestore.instance
                .collection("users")
                .doc(currentUser.uid)
                .collection("savedArticles")
                .orderBy("datePublished", descending: true)
                .snapshots()
            : FirebaseFirestore.instance
                .collection("articles")
                .orderBy("datePublished", descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final articles = snapshot.data!.docs
              .map((doc) => Article.fromDocument(doc))
              .toList();

          if (articles.isEmpty) {
            return Center(
              child: Text(
                showSaved
                    ? "No saved articles yet."
                    : "No articles available.",
              ),
            );
          }

          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];

              return FutureBuilder<UserModel?>(
                future: FirestoreService().getDoctorById(article.authorId),
                builder: (context, docSnap) {
                  if (!docSnap.hasData) {
                    return const SizedBox.shrink();
                  }

                  final doctor = docSnap.data!;
                  final doctorName = doctor.name;
                  final specialization =
                      doctor.doctorProfile?.specialization ?? '';
                  final hospital = doctor.doctorProfile?.hospitalName ?? '';

                  final preview = article.content.length > 100
                      ? "${article.content.substring(0, 100)}..."
                      : article.content;

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .doc(currentUser.uid)
                        .collection("savedArticles")
                        .doc(article.id)
                        .snapshots(),
                    builder: (context, savedSnap) {
                      final isSaved =
                          savedSnap.hasData && savedSnap.data!.exists;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(
                            article.title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                preview,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black87),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "By $doctorName • $specialization, $hospital",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isSaved ? Colors.teal : Colors.grey,
                            ),
                            onPressed: () async {
                              final ref = FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(currentUser.uid)
                                  .collection("savedArticles")
                                  .doc(article.id);

                              if (isSaved) {
                                await ref.delete();
                              } else {
                                await ref.set(article.toMap());
                              }
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ArticleDetailScreen(
                                  article: article,
                                  author: doctor,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
