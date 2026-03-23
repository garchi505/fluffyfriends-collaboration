// ─────────────────────────────────────────────────────────────────────────────
// hero_section.dart
// Assigned to: Kilat
//
// PURPOSE:
// This is the main Feed UI — the white card that sits over the colorful
// background and shows all posts from Firestore in real time.
//
// KEY CONCEPT — StreamBuilder:
// Instead of manually refreshing the feed with setState(), this widget uses
// StreamBuilder which listens to Firestore continuously.
// When anyone posts, likes, or comments — the feed updates automatically
// on every device without any manual refresh needed.
//
// EACH POST SUPPORTS:
//   - Tapping avatar or username → opens that user's ProfileScreen
//   - Follow/Unfollow button     → toggles follow state instantly
//   - Like button (heart)        → toggles like, count updates in real time
//   - Comment button             → opens a bottom sheet with live comments
//
// THIS IS A StatelessWidget because StreamBuilder handles all the state.
// No manual setState() needed anywhere in this file.
// ─────────────────────────────────────────────────────────────────────────────

// TODO: import dart:typed_data
//       HINT: needed for Uint8List — converts stored image bytes to displayable format
// TODO: import flutter material package
// TODO: import cloud_firestore package
//       HINT: needed for QuerySnapshot and QueryDocumentSnapshot types
// TODO: import firebase_service.dart
//       HINT: provides getFeedStream, likePost, unlikePost, followUser, addComment, getCommentsStream
// TODO: import profile_screen.dart
//       HINT: pushed when tapping a username or avatar

// TODO: Create HeroSection class that extends StatelessWidget
// HINT: StatelessWidget is correct here — StreamBuilder manages all state

  // TODO: Add two final fields:
  //   - currentUser (Map<String, dynamic>) — logged-in user's Firestore profile
  //   - onRefresh (VoidCallback) — called after follow/unfollow to update HomeScreen

  // TODO: Add const constructor with super.key, required currentUser, required onRefresh

  // TODO: Implement _openProfile(BuildContext context, String userId)
  // Steps:
  //   1. Call Navigator.push with MaterialPageRoute
  //   2. Build ProfileScreen with:
  //      - viewedUserId: userId
  //      - currentUser: currentUser
  //      - onRefresh: onRefresh
  //   HINT: Flutter automatically shows a back arrow when pushing a new screen

  // TODO: Override build(BuildContext context) → Widget
  // Return a Stack with two children:
  //
  // CHILD 1 — Colorful 4-block background:
  //   Row with two Expanded columns:
  //     Left:  red (0xFFE60000) top, pink (0xFFFF66B3) bottom
  //     Right: blue (0xFF4B5CFF) top, yellow (0xFFFFEB3B) bottom
  //
  // CHILD 2 — White feed card (Center → Container):
  //   - width: MediaQuery.of(context).size.width * 0.90
  //   - height: MediaQuery.of(context).size.height * 0.85
  //   - white background, borderRadius 20, black shadow offset (0,20)
  //   - Column with two children:
  //       1. "Feed" title bar Container:
  //          - height: 70, padding horizontal 30
  //          - Row with Text 'Feed' fontSize 22 bold
  //       2. Divider(height: 1)
  //       3. Expanded → StreamBuilder<QuerySnapshot>:
  //          - stream: FirebaseService.getFeedStream()
  //          HINT: .getFeedStream() returns a live stream of all posts newest first
  //          - builder: (context, snapshot) → Widget
  //            a. If snapshot.connectionState == ConnectionState.waiting
  //               → return Center(child: CircularProgressIndicator())
  //               HINT: shown while waiting for first data from Firestore
  //            b. Get docs: snapshot.data?.docs ?? []
  //            c. If docs.isEmpty → return Center with empty state:
  //               - '🧸' emoji fontSize 48
  //               - 'No posts yet!' fontSize 18 bold
  //               - 'Be the first to post something!' grey text
  //            d. Return ListView.builder:
  //               - padding: symmetric horizontal 40, vertical 24
  //               - itemCount: docs.length
  //               - itemBuilder: (_, i) => _buildPost(context, docs[i])

  // TODO: Implement _buildPost(BuildContext context, QueryDocumentSnapshot doc) → Widget
  // Steps:
  //   1. Extract these variables from doc:
  //      - postId = doc.id
  //        HINT: Firestore document ID — used for like/comment operations
  //      - myUid = currentUser['uid'] as String
  //      - likes = List.from(doc['likes'] ?? [])
  //      - isLiked = likes.contains(myUid)
  //        HINT: true if logged-in user already liked this post
  //      - isOwnPost = doc['userId'] == myUid
  //        HINT: true if this is the logged-in user's own post
  //      - myFollowing = List.from(currentUser['following'] ?? [])
  //      - isFollowing = myFollowing.contains(doc['userId'])
  //        HINT: true if logged-in user follows the post author
  //
  //   2. Return Container with:
  //      - margin: EdgeInsets.only(bottom: 32)
  //      - border: Border.all(color: Colors.grey.shade300)
  //      - borderRadius: 16
  //      - child: Column with crossAxisAlignment.start containing:
  //
  //        A. POST HEADER (Padding all 16 → Row):
  //           - GestureDetector (onTap: _openProfile) → CircleAvatar radius 22
  //             HINT: tapping avatar opens that user's profile
  //           - SizedBox width 14
  //           - GestureDetector (onTap: _openProfile) → Text doc['username'] bold 16
  //             HINT: tapping username also opens their profile
  //           - Spacer()
  //           - if (!isOwnPost) TextButton Follow/Following:
  //             HINT: hidden on your own posts
  //             HINT: black background when not following, grey when following
  //             HINT: onPressed calls FirebaseService.followUser or unfollowUser
  //             HINT: after follow/unfollow call onRefresh()
  //
  //        B. POST IMAGE (only if doc['imageBytes'] != null):
  //           Image.memory(
  //             Uint8List.fromList(List<int>.from(doc['imageBytes'])),
  //             width: double.infinity, height: 400, fit: BoxFit.cover
  //           )
  //           HINT: image stored as List<int> in Firestore — convert back to Uint8List
  //           HINT: add errorBuilder that shows broken_image icon
  //
  //        C. CAPTION (only if doc['caption'] is not empty):
  //           Padding fromLTRB(16, 12, 16, 0) → RichText:
  //           - Bold username + regular caption text
  //           HINT: use TextSpan children for mixed styles
  //
  //        D. ACTION BUTTONS (Padding all 16 → Row):
  //           - GestureDetector → Icon heart (favorite/favorite_border)
  //             HINT: red when isLiked, black when not
  //             HINT: onTap calls FirebaseService.likePost or unlikePost
  //             HINT: NO setState needed — StreamBuilder updates automatically
  //           - SizedBox width 6
  //           - Text likes.length
  //           - SizedBox width 18
  //           - GestureDetector → Icon comment_outlined
  //             HINT: onTap calls _showComments(context, postId)
  //           - SizedBox width 6
  //           - StreamBuilder<QuerySnapshot> for live comment count:
  //             stream: FirebaseService.getCommentsStream(postId)
  //             HINT: separate StreamBuilder so count updates independently

  // TODO: Implement _showComments(BuildContext context, String postId)
  // Steps:
  //   1. Create commentController = TextEditingController()
  //   2. Call showModalBottomSheet with:
  //      - isScrollControlled: true
  //        HINT: allows sheet to resize when keyboard appears
  //      - shape: RoundedRectangleBorder top radius 20
  //      - builder: (ctx) → Padding:
  //          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom)
  //          HINT: viewInsets.bottom = keyboard height, pushes input above keyboard
  //          child: Container height 500, padding all 20:
  //            Column with:
  //              1. Text 'Comments' fontSize 18 bold
  //              2. Divider
  //              3. Expanded → StreamBuilder<QuerySnapshot>:
  //                 stream: FirebaseService.getCommentsStream(postId)
  //                 HINT: live stream so new comments appear instantly
  //                 - If empty: Center text 'No comments yet. Be first! 🧸'
  //                 - If has comments: ListView.builder showing each comment
  //                   HINT: use RichText — bold username + regular comment text
  //              4. Row (comment input):
  //                 - Expanded TextField with controller
  //                 - SizedBox width 10
  //                 - IconButton Icons.send:
  //                   HINT: if text is empty return early
  //                   HINT: call FirebaseService.addComment with postId, userId, username, text
  //                   HINT: clear controller after sending
  //                   HINT: NO setState needed — StreamBuilder updates automatically
