import 'dart:typed_data';                         // Uint8List — for displaying image thumbnails in search results
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // QueryDocumentSnapshot type for post results
import '../services/firebase_service.dart';       // searchUsers() and searchPosts()
import 'profile_screen.dart';                     // opened when tapping any result

// ─────────────────────────────────────────────────────────────────────────────
// SearchScreen — lets users find other people and posts.
// Has two tabs: "People" (search by username or full name)
//               "Posts"  (search by caption text)
//
// Results update as the user types (live search).
// Tapping any result opens that user's profile page.
// Follow/unfollow buttons appear directly in the People results.
//
// Search is done client-side — we load all users/posts from Firestore
// and filter locally. Fine for small apps.
// ─────────────────────────────────────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser; // logged-in user's data (for follow state)
  final VoidCallback onRefresh;           // called after follow/unfollow so parent updates
  const SearchScreen({super.key, required this.currentUser, required this.onRefresh});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

// SingleTickerProviderStateMixin is required by TabController for its animations
class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {

  final _searchController = TextEditingController(); // captures what the user types
  late TabController _tabController; // controls which tab (People/Posts) is active

  List<Map<String, dynamic>>   _userResults = []; // matching users from Firestore
  List<QueryDocumentSnapshot>  _postResults = []; // matching posts from Firestore
  bool _hasSearched = false; // false = show "start searching" prompt instead of empty list
  bool _isSearching = false; // true while Firestore queries are in flight (shows spinner)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 tabs: People and Posts
  }

  @override
  void dispose() {
    // Always dispose controllers when screen is removed to free memory
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Called on every keystroke. Runs both user and post searches simultaneously
  // using Future.wait() so both finish in parallel (faster than sequential).
  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      // Empty query — reset to the "start searching" hint state
      setState(() { _hasSearched = false; _userResults = []; _postResults = []; });
      return;
    }

    setState(() { _hasSearched = true; _isSearching = true; }); // show spinner

    // Run both searches at the same time for speed
    final results = await Future.wait([
      FirebaseService.searchUsers(query), // returns List<Map<String, dynamic>>
      FirebaseService.searchPosts(query), // returns List<QueryDocumentSnapshot>
    ]);

    if (mounted) { // check widget is still in the tree before calling setState
      setState(() {
        _userResults = results[0] as List<Map<String, dynamic>>;
        _postResults = results[1] as List<QueryDocumentSnapshot>;
        _isSearching = false; // hide spinner
      });
    }
  }

  // Pushes ProfileScreen for the given userId.
  // Works for both own profile and others — back button always appears.
  void _openProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          viewedUserId: userId,
          currentUser:  widget.currentUser,
          onRefresh: () {
            widget.onRefresh();  // refresh parent (e.g. HomeScreen user data)
            setState(() {});     // re-render search results (follow button may have changed)
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Colorful 4-block background ────────────────────────────────────────
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

        // ── White search card ──────────────────────────────────────────────────
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
            child: Column(
              children: [

                // ── Search text field ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearch, // fires on every keystroke for live search
                    decoration: InputDecoration(
                      hintText: 'Search users or posts...',
                      // Show spinner while searching, magnifying glass when idle
                      prefixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2)))
                          : const Icon(Icons.search),
                      // X button to clear the field — only visible when there's text
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch(''); // also reset the results
                              })
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                // ── Tab bar: switch between People and Posts ───────────────────
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,          // selected tab = black text
                  unselectedLabelColor: Colors.grey, // unselected = grey text
                  indicatorColor: Colors.black,      // black underline on active tab
                  tabs: const [
                    Tab(text: 'People'), // tab 0
                    Tab(text: 'Posts'),  // tab 1
                  ],
                ),
                const Divider(height: 1),

                // ── Tab content ────────────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPeopleTab(), // shown when People tab is selected
                      _buildPostsTab(),  // shown when Posts tab is selected
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── People tab ────────────────────────────────────────────────────────────────
  // Shows matching users with their follow buttons.
  Widget _buildPeopleTab() {
    if (!_hasSearched) {
      // No search typed yet — show a prompt to encourage the user to search
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔍', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('Search for people',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ));
    }

    // Filter yourself out of results — no point finding your own profile here
    final results = _userResults
        .where((u) => u['uid'] != widget.currentUser['uid'])
        .toList();

    if (results.isEmpty) return const Center(child: Text('No users found.'));

    // ListView.separated adds a thin divider line between each result row
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, i) => _buildUserTile(results[i]),
    );
  }

  // ── Single user result row ────────────────────────────────────────────────────
  // Shows avatar, @username, full name, and a Follow/Following button.
  Widget _buildUserTile(Map<String, dynamic> user) {
    // Check the currentUser's following list to see if we already follow this person
    final myFollowing = List.from(widget.currentUser['following'] ?? []);
    final isFollowing = myFollowing.contains(user['uid']);

    return ListTile(
      onTap: () => _openProfile(user['uid']), // tap the entire row to open their profile
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade300,
        child: const Icon(Icons.person, color: Colors.white), // placeholder avatar
      ),
      title: Text('@${user['username']}',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(user['fullName']), // full name shown below username
      trailing: TextButton(
        // Follow/Unfollow button on the right side
        onPressed: () async {
          final myUid    = widget.currentUser['uid'] as String;
          final theirUid = user['uid']               as String;
          if (isFollowing) {
            await FirebaseService.unfollowUser(myUid, theirUid);
          } else {
            await FirebaseService.followUser(myUid, theirUid);
          }
          widget.onRefresh(); // update HomeScreen's currentUser data
          setState(() {});    // re-render this screen so button label flips
        },
        style: TextButton.styleFrom(
          // Grey when following, black when not following
          backgroundColor: isFollowing ? Colors.grey.shade200 : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color: isFollowing ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold, fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ── Posts tab ─────────────────────────────────────────────────────────────────
  // Shows posts whose caption matches the search query.
  Widget _buildPostsTab() {
    if (!_hasSearched) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔍', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('Search for posts',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ));
    }

    if (_postResults.isEmpty) return const Center(child: Text('No posts found.'));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _postResults.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, i) => _buildPostTile(_postResults[i]),
    );
  }

  // ── Single post result row ─────────────────────────────────────────────────────
  // Shows a thumbnail (if image), @username, caption preview, and like count.
  Widget _buildPostTile(QueryDocumentSnapshot doc) {
    final imageBytes = doc['imageBytes']; // stored as List<dynamic> in Firestore
    return ListTile(
      onTap: () => _openProfile(doc['userId']), // tapping a post opens the poster's profile
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        // Show image thumbnail in the circle if the post has an image
        backgroundImage: imageBytes != null
            ? MemoryImage(Uint8List.fromList(List<int>.from(imageBytes)))
            : null, // null = let the child icon show instead
        child: imageBytes == null
            ? const Icon(Icons.article_outlined, color: Colors.grey) // placeholder icon
            : null,
      ),
      title: Text('@${doc['username']}',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      // Caption preview capped at 2 lines to keep the list compact
      subtitle: Text(doc['caption'],
          maxLines: 2, overflow: TextOverflow.ellipsis),
      // Like count on the right
      trailing: Text('❤️ ${(doc['likes'] as List).length}',
          style: const TextStyle(color: Colors.grey)),
    );
  }
}
