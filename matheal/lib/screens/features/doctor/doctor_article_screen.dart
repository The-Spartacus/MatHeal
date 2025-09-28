import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/article_model.dart';
import '../../../services/image_upload_service.dart';
import '../../../utils/theme.dart';

class DoctorArticleScreen extends StatefulWidget {
  final String doctorId;
  const DoctorArticleScreen({super.key, required this.doctorId});

  @override
  State<DoctorArticleScreen> createState() => _DoctorArticleScreenState();
}

class _DoctorArticleScreenState extends State<DoctorArticleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _deleteArticle(String id) async {
    bool confirmed = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Article'),
            content: const Text('Are you sure you want to delete this article?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;

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
        onPressed: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateEditArticleScreen(doctorId: widget.doctorId))),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('articles')
            .where('authorId', isEqualTo: widget.doctorId)
            .orderBy('datePublished', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final articles = snapshot.data!.docs.map((doc) => Article.fromDocument(doc)).toList();
          if (articles.isEmpty) return const Center(child: Text('No articles found'));

          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: article.imageUrl != null
                      ? Image.network(article.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.article, size: 40),
                  title: Text(article.title),
                  subtitle: Text('Published on ${article.datePublished.toLocal().toString().split(' ')[0]}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => CreateEditArticleScreen(doctorId: widget.doctorId, article: article))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => _deleteArticle(article.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Separate screen for Create/Edit logic
class CreateEditArticleScreen extends StatefulWidget {
  final String doctorId;
  final Article? article;
  const CreateEditArticleScreen({super.key, required this.doctorId, this.article});

  @override
  State<CreateEditArticleScreen> createState() => _CreateEditArticleScreenState();
}

class _CreateEditArticleScreenState extends State<CreateEditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  File? _imageFile;
  String? _networkImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article?.title ?? '');
    _contentController = TextEditingController(text: widget.article?.content ?? '');
    _networkImageUrl = widget.article?.imageUrl;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _networkImageUrl = null; // Clear network image if a new local one is picked
      });
    }
  }

  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isUploading = true);

    try {
      String? imageUrl = _networkImageUrl;
      if (_imageFile != null) {
        imageUrl = await ImageUploadService().uploadImage(_imageFile!);
      }

      final articleData = {
        'title': _titleController.text,
        'content': _contentController.text,
        'authorId': widget.doctorId,
        'datePublished': widget.article?.datePublished ?? Timestamp.now(),
        'imageUrl': imageUrl,
      };

      if (widget.article == null) {
        await FirebaseFirestore.instance.collection('articles').add(articleData);
      } else {
        await FirebaseFirestore.instance.collection('articles').doc(widget.article!.id).update(articleData);
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving article: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article == null ? 'Create Article' : 'Edit Article'),
        actions: [
          IconButton(onPressed: _isUploading ? null : _saveArticle, icon: const Icon(Icons.save)),
        ],
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Image preview and picker
                    _buildImagePicker(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (val) => val == null || val.isEmpty ? 'Enter title' : null,
                    ),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(labelText: 'Content'),
                      maxLines: 10,
                      validator: (val) => val == null || val.isEmpty ? 'Enter content' : null,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: (_imageFile != null)
            ? Image.file(_imageFile!, fit: BoxFit.cover)
            : (_networkImageUrl != null)
                ? Image.network(_networkImageUrl!, fit: BoxFit.cover)
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.add_a_photo), Text('Add an image')],
                  ),
      ),
    );
  }
}
