import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/article_model.dart'; // Simplified Article model

class DoctorArticleScreen extends StatefulWidget {
  final String doctorId; // Current doctor UID
  const DoctorArticleScreen({super.key, required this.doctorId});

  @override
  State<DoctorArticleScreen> createState() => _DoctorArticleScreenState();
}

class _DoctorArticleScreenState extends State<DoctorArticleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // For creating/updating articles
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _content = '';
  String _specialization = '';

  void _createOrUpdateArticle([Article? article]) {
    if (article != null) {
      // Updating
      _title = article.title;
      _content = article.content;
      _specialization = article.specialization;
    } else {
      _title = '';
      _content = '';
      _specialization = '';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(article == null ? 'Create Article' : 'Edit Article'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    initialValue: _title,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter title' : null,
                    onSaved: (val) => _title = val!,
                  ),
                  TextFormField(
                    initialValue: _content,
                    decoration: const InputDecoration(labelText: 'Content'),
                    maxLines: 5,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter content' : null,
                    onSaved: (val) => _content = val!,
                  ),
                  TextFormField(
                    initialValue: _specialization,
                    decoration:
                        const InputDecoration(labelText: 'Specialization'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter specialization' : null,
                    onSaved: (val) => _specialization = val!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    if (article == null) {
                      // Create
                      await _firestore.collection('articles').add({
                        'title': _title,
                        'content': _content,
                        'authorId': widget.doctorId, // Only doctor ID
                        'specialization': _specialization,
                        'datePublished': Timestamp.now(),
                      });
                    } else {
                      // Update
                      await _firestore
                          .collection('articles')
                          .doc(article.id)
                          .update({
                        'title': _title,
                        'content': _content,
                        'specialization': _specialization,
                      });
                    }

                    Navigator.pop(context);
                  }
                },
                child: Text(article == null ? 'Create' : 'Update')),
          ],
        );
      },
    );
  }

  void _deleteArticle(String id) async {
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Article'),
        content: const Text('Are you sure you want to delete this article?'),
        actions: [
          TextButton(
            onPressed: () {
              confirmed = false;
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              confirmed = true;
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed) {
      await _firestore.collection('articles').doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Articles'),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _createOrUpdateArticle(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('articles')
            .where('authorId', isEqualTo: widget.doctorId)
            .orderBy('datePublished', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final articles = snapshot.data!.docs
              .map((doc) => Article.fromDocument(doc))
              .toList();

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
                    'Published on ${article.datePublished.toLocal().toString().split(' ')[0]} | ${article.specialization}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _createOrUpdateArticle(article),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteArticle(article.id),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Optionally navigate to detailed view
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
