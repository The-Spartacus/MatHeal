import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../features/create_post_screen.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Moments"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatePostScreen())),
        child: const Icon(Icons.add_a_photo),
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: firestoreService.getCommunityPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No posts yet. Be the first to share a moment!"));
          }

          final posts = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPostCard(context, post, firestoreService, currentUserId);
            },
          );
        },
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, PostModel post, FirestoreService service, String currentUserId) {
    final isLiked = post.likes.contains(currentUserId);
    final timeAgo = DateFormat.yMMMd().add_jm().format(post.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Info
          FutureBuilder<UserModel?>(
            future: service.getUser(post.userId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const ListTile(title: Text("Loading..."));
              final author = snapshot.data!;
              
              return ListTile(
                leading: FutureBuilder<UserProfile?>(
                  future: service.getProfile(post.userId),
                  builder: (context, profileSnap) {
                    final avatarUrl = profileSnap.data?.avatarUrl;
                    return CircleAvatar(
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null ? const Icon(Icons.person) : null,
                    );
                  }
                ),
                title: Text(author.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(timeAgo),
              );
            },
          ),
          
          // Post Image
          Image.network(
            post.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
            loadingBuilder: (context, child, progress) => 
                progress == null ? child : const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
          ),

          // Post Caption
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(post.caption),
          ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? AppColors.accent : Colors.grey,
                      ),
                      onPressed: () => service.toggleLikePost(post.id, currentUserId, isLiked),
                    ),
                    Text("${post.likes.length} likes"),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.grey),
                  onPressed: () => _sharePost(post, service),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _sharePost(PostModel post, FirestoreService service) async {
    final author = await service.getUser(post.userId);
    final authorName = author?.name ?? "Unknown User";
    
    final shareText = 'Check out this moment from $authorName!\n\n"${post.caption}"\n\n${post.imageUrl}';
    
    Share.share(shareText);
  }
}