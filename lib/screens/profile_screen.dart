import 'dart:typed_data';                        // Uint8List — for converting stored image bytes back to displayable format
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // QuerySnapshot and QueryDocumentSnapshot types
import '../services/firebase_service.dart';      // to load user data, posts stream, follow/unfollow, logout
import 'login_screen.dart';                      // destination after logout

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen — handles THREE different situations with one screen:
//
//   1. Your own profile from the bottom nav "Profile" tab
//      → No back button (it's a tab, nothing to go back to)
//      → AppBar title: "Profile"
//      → Shows Logout button
//
//   2. Someone else's profile, opened by tapping in feed or search
//      → Back arrow shown (Navigator.canPop() = true)
//      → AppBar title: "@username"
//      → Shows Follow / Following button
//
//   3. YOUR OWN profile, opened by tapping your own avatar in the feed
//      → Back arrow still shown (got here via Navigator.push)
//      → AppBar title: "Profile"
//      → Shows Logout button
//
// KEY RULE:
//   _isOwnProfile = WHOSE profile is this? (decides content)
//   canPop()      = HOW did I get here?    (decides back button)
//   Never use one to answer the other!
//
// The post grid uses StreamBuilder — it updates in real time when posts are added.
// The follower/following counts use FutureBuilder to reload fresh Firestore data.
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  final String viewedUserId;             // uid of the user whose profile is being shown
  final Map<String, dynamic> currentUser; // logged-in user's data (for follow logic)
  final VoidCallback onRefresh;          // called after follow/unfollow so parent updates

  const ProfileScreen({
    super.key,
    required this.viewedUserId,
    required this.currentUser,
    required this.onRefresh,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _viewedUser; // Firestore profile of the person being viewed
  bool _isOwnProfile = false;        // true when viewedUserId == currentUser['uid']
  bool _loaded = false;              // false while initial Firestore load is running

  @override
  void initState() {
    super.initState();
    _load(); // fetch the viewed user's profile as soon as the screen opens
  }

  // Loads the viewed user's profile from Firestore.
  // Also called after follow/unfollow to refresh follower/following counts.
  Future<void> _load() async {
    final user = await FirebaseService.getUserById(widget.viewedUserId);
    if (user != null && mounted) {
      setState(() {
        _viewedUser   = user;
        _isOwnProfile = widget.viewedUserId == widget.currentUser['uid']; // am I viewing myself?
        _loaded       = true; // allow the UI to render
      });
    }
  }

  // Signs out from Firebase Auth and removes all screens from the navigation stack.
  // pushAndRemoveUntil with (_) => false removes EVERYTHING so the user
  // can't press back and accidentally return to the app while logged out.
  void _logout() {
    FirebaseService.logout(); // Firebase clears the session token
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false, // predicate false = remove every existing route
    );
  }

  // Toggles follow/unfollow for the viewed user.
  // Reloads fresh user data before modifying to avoid overwriting changes
  // made elsewhere since this screen was last loaded.
  Future<void> _toggleFollow() async {
    final myUid    = widget.currentUser['uid'] as String;
    final theirUid = widget.viewedUserId;

    // Always fetch fresh data — the cached widget.currentUser may be stale
    final freshMe    = await FirebaseService.getUserById(myUid);
    final isFollowing = (freshMe?['following'] as List? ?? []).contains(theirUid);

    if (isFollowing) {
      await FirebaseService.unfollowUser(myUid, theirUid); // unfollow
    } else {
      await FirebaseService.followUser(myUid, theirUid);   // follow
    }

    widget.onRefresh(); // tell parent (HomeScreen) to reload currentUser
    _load();            // reload this screen so follower count updates immediately
  }

  @override
  Widget build(BuildContext context) {
    // Show spinner while waiting for Firestore to return the user profile
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Navigator.canPop() = true if there is a screen behind this one in the stack.
    // This is how we know whether to show the back arrow — NOT _isOwnProfile.
    final canGoBack = Navigator.canPop(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: canGoBack, // back arrow only when we can go back
        title: Text(
          _isOwnProfile
              ? 'Profile'                          // your own profile
              : '@${_viewedUser!['username']}',    // someone else's profile
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ── Colorful 4-block background ──────────────────────────────────────
          Row(
            children: [
              Expanded(child: Column(children: [
                Expanded(child: Container(color: const Color(0xFFE60000))),
                Expanded(child: Container(color: const Color(0xFFFF66B3))),
              ])),
              Expanded(child: Column(children: [
                Expanded(child: Container(color: const Color(0xFF4B5CFF))),
                Expanded(child: Container(color: const Color(0xFFFFEB3B))),
              ])),
            ],
          ),

          // ── White profile card ───────────────────────────────────────────────
          Center(
            child: Container(
              width:  MediaQuery.of(context).size.width  * 0.90,
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 40, offset: const Offset(0, 20),
                )],
              ),
              // StreamBuilder listens to this user's posts in real time.
              // The post grid updates automatically when they add or delete a post.
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.getUserPostsStream(widget.viewedUserId),
                builder: (context, snapshot) {
                  final posts = snapshot.data?.docs ?? []; // list of post documents

                  // FutureBuilder reloads the user's profile data so follower/following
                  // counts stay accurate after follow/unfollow operations.
                  return FutureBuilder<Map<String, dynamic>?>(
                    future: FirebaseService.getUserById(widget.viewedUserId),
                    builder: (context, userSnap) {
                      final user      = userSnap.data ?? _viewedUser!; // fallback to cached
                      final followers = (user['followers'] as List?)?.length ?? 0;
                      final following = (user['following'] as List?)?.length ?? 0;

                      // Check if the VIEWED user's followers list contains the logged-in user's uid
                      // This determines whether to show "Follow" or "Following" on the button
                      final isFollowing = ((user['followers'] ?? []) as List)
                          .contains(widget.currentUser['uid']);

                      return CustomScrollView(
                        // CustomScrollView lets us mix a fixed header with a scrollable grid
                        slivers: [
                          // Profile header: avatar, stats, name, action button
                          SliverToBoxAdapter(
                            child: _buildHeader(
                                user, posts.length, followers, following, isFollowing),
                          ),
                          const SliverToBoxAdapter(child: Divider()),

                          // Post grid — or empty state if no posts yet
                          posts.isEmpty
                              ? const SliverFillRemaining( // fills remaining scroll space
                                  child: Center(child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('🧸', style: TextStyle(fontSize: 48)),
                                      SizedBox(height: 12),
                                      Text('No posts yet', style: TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  )),
                                )
                              : SliverGrid(
                                  delegate: SliverChildBuilderDelegate(
                                    (_, i) => _buildPostTile(posts[i]),
                                    childCount: posts.length,
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,   // 3 columns like Instagram
                                    crossAxisSpacing: 2, // gap between columns
                                    mainAxisSpacing:  2, // gap between rows
                                  ),
                                ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile header ──────────────────────────────────────────────────────────
  // Shows: avatar, Posts/Followers/Following counts, full name, @username,
  // and either a Logout button (own profile) or Follow button (others).
  Widget _buildHeader(Map<String, dynamic> user, int postCount,
      int followers, int following, bool isFollowing) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar placeholder (profile photos not implemented yet)
              CircleAvatar(
                radius: 44,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, size: 44, color: Colors.white),
              ),
              const SizedBox(width: 30),
              // Stats: three numbers in a row
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem(postCount.toString(), 'Posts'),
                    _statItem(followers.toString(), 'Followers'),
                    _statItem(following.toString(), 'Following'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Full name in bold
          Text(user['fullName'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          // @username in grey below the name
          Text('@${user['username']}',
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 16),

          // Action button — full width
          SizedBox(
            width: double.infinity,
            child: _isOwnProfile
                // Own profile → Logout button (outlined style)
                ? OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Log Out',
                        style: TextStyle(color: Colors.black)),
                  )
                // Other profile → Follow/Following toggle (filled style)
                : ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      // Black when not following, grey when already following
                      backgroundColor:
                          isFollowing ? Colors.grey.shade200 : Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: isFollowing ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Stat column: a number above a label ─────────────────────────────────────
  Widget _statItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  // ── Single square tile in the 3-column post grid ────────────────────────────
  // Shows the image if the post has one, otherwise shows caption text.
  Widget _buildPostTile(QueryDocumentSnapshot doc) {
    final imageBytes = doc['imageBytes']; // List<dynamic> stored in Firestore, or null
    if (imageBytes != null) {
      // Convert List<dynamic> → List<int> → Uint8List so Image.memory can display it
      final bytes = Uint8List.fromList(List<int>.from(imageBytes));
      return Image.memory(bytes, fit: BoxFit.cover, // crop to fill the square tile
          errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image)));
    }
    // Text-only post — show caption in a light grey tile
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(8),
      child: Text(doc['caption'],
          style: const TextStyle(fontSize: 12),
          maxLines: 4,
          overflow: TextOverflow.ellipsis), // "..." if caption is too long
    );
  }
}
