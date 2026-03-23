import 'dart:typed_data';                         // Uint8List — for converting stored image bytes to displayable format
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // QuerySnapshot and QueryDocumentSnapshot
import '../services/firebase_service.dart';       // getFeedStream, likePost, unlikePost, followUser, addComment
import '../screens/profile_screen.dart';          // pushed when tapping a username or avatar

// ─────────────────────────────────────────────────────────────────────────────
// HeroSection — the main Feed UI (white card over the colorful background).
//
// KEY UPGRADE FROM HIVE VERSION:
// This version uses StreamBuilder instead of setState for the feed.
// Firestore pushes live updates to the UI — when anyone posts, likes, or
// comments, every device's feed updates automatically without any manual refresh.
//
// Each post supports:
//   - Tapping avatar/username → opens that user's ProfileScreen
//   - Follow/Unfollow button  → toggles follow state instantly
//   - Like button (heart)     → toggles like, count updates in real time
//   - Comment button          → opens a bottom sheet with live comments
// ─────────────────────────────────────────────────────────────────────────────

// HeroSection is StatelessWidget because StreamBuilder handles all the state.
// No manual setState() needed — Firestore pushes changes automatically.
class HeroSection extends StatelessWidget {
  final Map<String, dynamic> currentUser; // logged-in user's Firestore profile
  final VoidCallback onRefresh;           // called after follow/unfollow to update HomeScreen

  const HeroSection({super.key, required this.currentUser, required this.onRefresh});

  // Pushes ProfileScreen for the given userId on top of the current screen.
  // Works for any user — Flutter automatically shows a back arrow.
  void _openProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          viewedUserId: userId,
          currentUser:  currentUser,
          onRefresh:    onRefresh, // propagate refresh upward
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      // Stack layers the white feed card on top of the colorful background
      children: [

        // ── Colorful 4-block background ────────────────────────────────────────
        Row(
          children: [
            Expanded(child: Column(children: [
              Expanded(child: Container(color: const Color(0xFFE60000))), // red
              Expanded(child: Container(color: const Color(0xFFFF66B3))), // pink
            ])),
            Expanded(child: Column(children: [
              Expanded(child: Container(color: const Color(0xFF4B5CFF))), // blue
              Expanded(child: Container(color: const Color(0xFFFFEB3B))), // yellow
            ])),
          ],
        ),

        // ── White feed card ────────────────────────────────────────────────────
        Center(
          child: Container(
            width:  MediaQuery.of(context).size.width  * 0.90, // 90% of screen width
            height: MediaQuery.of(context).size.height * 0.85, // 85% of screen height
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40, offset: const Offset(0, 20), // shadow below the card
              )],
            ),
            child: Column(
              children: [
                // "Feed" title bar at the top of the white card
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: const Row(children: [
                    Text('Feed',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ]),
                ),
                const Divider(height: 1), // thin line separating title from posts

                // ── StreamBuilder: the live feed ────────────────────────────────
                // Listens to Firestore's posts collection in real time.
                // Rebuilds automatically whenever any post is added, liked, or deleted.
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseService.getFeedStream(), // live Firestore stream
                    builder: (context, snapshot) {

                      // Show spinner while waiting for first data from Firestore
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? []; // list of post documents

                      // Empty state — shown when no posts exist yet in the app
                      if (docs.isEmpty) {
                        return Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🧸', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            const Text('No posts yet!',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Be the first to post something!',
                                style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ));
                      }

                      // Scrollable list of post cards
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 24),
                        itemCount: docs.length,
                        itemBuilder: (_, i) => _buildPost(context, docs[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Single post card ──────────────────────────────────────────────────────────
  // Renders one full post: header, image, caption, and action buttons.
  Widget _buildPost(BuildContext context, QueryDocumentSnapshot doc) {
    final postId      = doc.id;                                   // Firestore document ID — used for like/comment operations
    final myUid       = currentUser['uid'] as String;            // logged-in user's uid
    final likes       = List.from(doc['likes'] ?? []);           // list of uids who liked
    final isLiked     = likes.contains(myUid);                   // did I like this post?
    final isOwnPost   = doc['userId'] == myUid;                  // is this my own post?
    final myFollowing = List.from(currentUser['following'] ?? []); // who I follow
    final isFollowing = myFollowing.contains(doc['userId']);     // do I follow the poster?

    return Container(
      margin: const EdgeInsets.only(bottom: 32), // space between post cards
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300), // light border around each card
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Post header: avatar + username + follow button ──────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Tapping the avatar opens that user's full profile
                GestureDetector(
                  onTap: () => _openProfile(context, doc['userId']),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade300,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                // Tapping the username also opens their profile
                GestureDetector(
                  onTap: () => _openProfile(context, doc['userId']),
                  child: Text(doc['username'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const Spacer(), // pushes the follow button to the far right

                // Follow button — hidden on your own posts (no point following yourself)
                if (!isOwnPost)
                  TextButton(
                    onPressed: () async {
                      // Call the appropriate Firebase operation
                      if (isFollowing) {
                        await FirebaseService.unfollowUser(myUid, doc['userId']);
                      } else {
                        await FirebaseService.followUser(myUid, doc['userId']);
                      }
                      onRefresh(); // reload currentUser in HomeScreen so button state updates
                    },
                    style: TextButton.styleFrom(
                      backgroundColor:
                          isFollowing ? Colors.grey.shade200 : Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: isFollowing ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Post image ──────────────────────────────────────────────────────
          // Only shown if this post has an image (imageBytes is not null).
          // The image is stored as List<int> in Firestore — we convert back to
          // Uint8List so Image.memory() can display it (web-safe approach).
          if (doc['imageBytes'] != null)
            Image.memory(
              Uint8List.fromList(List<int>.from(doc['imageBytes'])),
              width:  double.infinity,
              height: 400,
              fit:    BoxFit.cover, // crop to fill without distortion
              errorBuilder: (_, __, ___) => Container( // shown if image fails to decode
                height: 200, color: Colors.grey.shade200,
                child: const Center(
                    child: Icon(Icons.broken_image, size: 48))),
            ),

          // ── Caption ─────────────────────────────────────────────────────────
          // Only shown if caption is not empty.
          // RichText bolds the username before the caption text (Instagram style).
          if ((doc['caption'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                  children: [
                    TextSpan(
                      text: '${doc['username']} ', // bold username prefix
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: doc['caption']), // regular weight caption
                  ],
                ),
              ),
            ),

          // ── Like and comment buttons ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [

                // Heart / like button — red when liked, black when not
                GestureDetector(
                  onTap: () async {
                    if (isLiked) {
                      await FirebaseService.unlikePost(postId, myUid); // remove like
                    } else {
                      await FirebaseService.likePost(postId, myUid);   // add like
                    }
                    // No setState() needed — StreamBuilder updates automatically
                  },
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 26,
                    color: isLiked ? Colors.red : Colors.black,
                  ),
                ),
                const SizedBox(width: 6),
                Text('${likes.length}'), // live like count next to the heart

                const SizedBox(width: 18),

                // Comment bubble button — opens the bottom sheet
                GestureDetector(
                  onTap: () => _showComments(context, postId),
                  child: const Icon(Icons.comment_outlined, size: 26),
                ),
                const SizedBox(width: 6),

                // Live comment count — its own StreamBuilder so it updates
                // independently from the post card (no full rebuild needed)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.getCommentsStream(postId),
                  builder: (_, snap) =>
                      Text('${snap.data?.docs.length ?? 0}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Comments bottom sheet ─────────────────────────────────────────────────────
  // Slides up from the bottom when the comment icon is tapped.
  // Uses StreamBuilder — new comments appear instantly without any refresh.
  void _showComments(BuildContext context, String postId) {
    final commentController = TextEditingController(); // captures what the user types

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows the sheet to resize when keyboard appears
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        // viewInsets.bottom = keyboard height — pushes the input field above keyboard
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Comments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),

              // Scrollable list of existing comments — updates live via StreamBuilder
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.getCommentsStream(postId),
                  builder: (_, snap) {
                    final comments = snap.data?.docs ?? [];

                    if (comments.isEmpty) {
                      return const Center(
                          child: Text('No comments yet. Be first! 🧸'));
                    }

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (_, i) {
                        final c = comments[i]; // a single comment document
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black),
                              children: [
                                // Bold username before the comment text
                                TextSpan(
                                  text: '${c['username']} ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: c['text']),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Comment input row at the bottom of the sheet ──────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.send), // paper plane icon
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty) return;

                      // Save the comment to Firestore sub-collection
                      await FirebaseService.addComment(
                        postId:   postId,
                        userId:   currentUser['uid'],
                        username: currentUser['username'],
                        text:     commentController.text.trim(),
                      );

                      commentController.clear(); // clear input after sending
                      // StreamBuilder updates the list automatically — no setState needed
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
