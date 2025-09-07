import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/article_model.dart';

class PatientArticleScreen extends StatefulWidget {
  const PatientArticleScreen({super.key});

  @override
  State<PatientArticleScreen> createState() => _PatientArticleScreenState();
}

class _PatientArticleScreenState extends State<PatientArticleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userId = '';
  List<String> bookmarkedArticleIds = [];

  // Filter options
  String? selectedDoctor;
  String? selectedSpecialization;
  bool showSavedOnly = false;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    setState(() {
      userId = user.uid;
      bookmarkedArticleIds = List<String>.from(doc['bookmarks'] ?? []);
    });
  }

  // Toggle bookmark
  void _toggleBookmark(String articleId) async {
    setState(() {
      if (bookmarkedArticleIds.contains(articleId)) {
        bookmarkedArticleIds.remove(articleId);
      } else {
        bookmarkedArticleIds.add(articleId);
      }
    });

    await _firestore.collection('users').doc(userId).update({
      'bookmarks': bookmarkedArticleIds,
    });
  }

  Stream<QuerySnapshot> _getArticleStream() {
    return _firestore.collection('articles')
      .orderBy('datePublished', descending: true)
      .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles'),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getArticleStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                List<Article> articles = snapshot.data!.docs
                    .map((doc) => Article.fromDocument(doc))
                    .toList();

                // Apply filters
                if (showSavedOnly) {
                  articles = articles.where((a) => bookmarkedArticleIds.contains(a.id)).toList();
                }
                if (selectedDoctor != null) {
                  articles = articles.where((a) => a.authorId == selectedDoctor).toList();
                }
                if (selectedSpecialization != null) {
                  articles = articles.where((a) => a.specialization == selectedSpecialization).toList();
                }

                if (articles.isEmpty) return const Center(child: Text('No articles found'));

                return ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(article.title),
                        subtitle: Text(
                          'Doctor ID: ${article.authorId} | ${article.datePublished.toLocal().toString().split(' ')[0]} | ${article.specialization}',
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            bookmarkedArticleIds.contains(article.id)
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                          ),
                          onPressed: () => _toggleBookmark(article.id),
                        ),
                        onTap: () {
                          // Open detailed article view if needed
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'Filter by Doctor ID'),
                  onChanged: (val) {
                    setState(() {
                      selectedDoctor = val.isEmpty ? null : val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'Filter by Specialization'),
                  onChanged: (val) {
                    setState(() {
                      selectedSpecialization = val.isEmpty ? null : val;
                    });
                  },
                ),
              ),
            ],
          ),
          CheckboxListTile(
            value: showSavedOnly,
            onChanged: (val) {
              setState(() {
                showSavedOnly = val ?? false;
              });
            },
            title: const Text('Show Saved Articles Only'),
          ),
        ],
      ),
    );
  }
}
