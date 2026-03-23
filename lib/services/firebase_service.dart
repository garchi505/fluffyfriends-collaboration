import 'package:firebase_auth/firebase_auth.dart';   // Firebase Authentication — handles login, signup, logout, session
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore — our cloud database for users, posts, comments, follows

// ─────────────────────────────────────────────────────────────────────────────
// FirebaseService — the single place where ALL data is read and written.
// Replaces the old LocalStorageService (Hive) entirely.
//
// WHY FIREBASE?
// Unlike Hive which stored data only on the device, Firebase stores data in
// the cloud. This means multiple users can see each other's posts, follow each
// other, and comment in real time — across different devices.
//
// HOW IT WORKS:
// Firebase Auth  = handles who is logged in (email/password accounts)
// Firestore      = the database (stores users, posts, comments, follow lists)
// StreamSnapshot = Firestore can push live updates to the UI automatically
//
// All methods are static — call them anywhere like: FirebaseService.login(...)
// ─────────────────────────────────────────────────────────────────────────────

class FirebaseService {
  // Cached references to Firebase services — created once, reused everywhere
  static final _auth = FirebaseAuth.instance;  // handles authentication
  static final _db   = FirebaseFirestore.instance; // handles database reads/writes

  // ── Auth ──────────────────────────────────────────────────────────────────────

  // Returns the currently logged-in Firebase user object, or null if nobody is logged in.
  // Firebase automatically persists the session — no manual saving needed like Hive.
  static User? get currentUser => _auth.currentUser;

  // Sign up — does two things:
  //   1. Creates a Firebase Auth account (for login/logout/session)
  //   2. Saves the user's public profile to Firestore (for display in the app)
  static Future<User?> signUp({
    required String fullName,
    required String username,
    required String password,
  }) async {
    // Check username is unique BEFORE creating the account.
    // If we didn't check, two users could have the same @username.
    final existing = await getUserByUsername(username);
    if (existing != null) {
      throw Exception('Username already taken.'); // caught by signup screen
    }

    // Firebase Auth requires an email address — our app uses usernames instead.
    // We build a fake email from the username so Firebase Auth is satisfied.
    // The user never sees this email — they always log in with their username.
    final email = '$username@fluffyfriends.app';

    // Creates the Firebase Auth account — Firebase assigns a unique uid
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid; // unique ID that Firebase assigns — used everywhere

    // Save the user's profile to Firestore so other users can see their name,
    // follow them, and their posts can display their username.
    // This is SEPARATE from Auth — Auth handles login, Firestore handles profile.
    await _db.collection('users').doc(uid).set({
      'uid':       uid,        // stored here too so we can read it back easily
      'fullName':  fullName,   // displayed on the profile page (e.g. "Rey Aventura")
      'username':  username,   // shown on posts and searchable (e.g. "@rey_av")
      'followers': [],         // list of uids who follow this user — starts empty
      'following': [],         // list of uids this user follows — starts empty
      'createdAt': FieldValue.serverTimestamp(), // Firebase server sets this timestamp
    });

    return cred.user; // return the Firebase user so the app can get the uid
  }

  // Login — rebuilds the fake email from the username and signs in with Firebase Auth.
  // Firebase Auth handles session persistence automatically after this call.
  static Future<User?> login({
    required String username,
    required String password,
  }) async {
    final email = '$username@fluffyfriends.app'; // must match the format used in signUp
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user; // return user so HomeScreen gets the uid
  }

  // Logout — signs out of Firebase Auth. Firebase clears the session automatically.
  // After this, FirebaseAuth.instance.currentUser will return null.
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Users ──────────────────────────────────────────────────────────────────────

  // Fetches one user's Firestore profile by their Firebase uid.
  // Returns a Map like {'uid': '...', 'username': 'rex', 'fullName': '...', ...}
  // Returns null if the user document doesn't exist in Firestore.
  static Future<Map<String, dynamic>?> getUserById(String uid) async {
    final snap = await _db.collection('users').doc(uid).get(); // read one document
    return snap.data(); // .data() returns null if document doesn't exist
  }

  // Finds a user by their username — used during login and username uniqueness check.
  // Firestore doesn't have a built-in username lookup, so we use a where() query.
  static Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final snap = await _db
        .collection('users')
        .where('username', isEqualTo: username) // filter to exact username match
        .limit(1)  // we only ever need one result — stops Firestore reading more
        .get();
    if (snap.docs.isEmpty) return null; // no user with that username exists
    return snap.docs.first.data();      // return the first (and only) match
  }

  // Searches users by username OR full name — used in the Search screen.
  // Firestore doesn't support full-text search, so we load all users and
  // filter client-side. Fine for small apps, but would need Algolia at scale.
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final q    = query.toLowerCase(); // normalize to lowercase for case-insensitive match
    final snap = await _db.collection('users').get(); // loads ALL users
    return snap.docs
        .map((d) => d.data()) // convert each document to a Map
        .where((u) =>
            (u['username'] as String).toLowerCase().contains(q) || // match username
            (u['fullName']  as String).toLowerCase().contains(q))  // OR full name
        .toList();
  }

  // ── Posts ──────────────────────────────────────────────────────────────────────

  // Returns a LIVE STREAM of all posts sorted newest first.
  // The feed uses StreamBuilder — it rebuilds automatically whenever anyone posts.
  // This replaces the old getFeedPosts() which required manual setState() to refresh.
  static Stream<QuerySnapshot> getFeedStream() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true) // newest post at the top of the feed
        .snapshots(); // .snapshots() = live stream, pushes updates automatically
  }

  // Returns a live stream of ONE user's posts — used in the profile grid.
  // Requires a Firestore composite index on (userId ASC, createdAt DESC).
  static Stream<QuerySnapshot> getUserPostsStream(String uid) {
    return _db
        .collection('posts')
        .where('userId', isEqualTo: uid)        // only this user's posts
        .orderBy('createdAt', descending: true) // newest first
        .snapshots();
  }

  // Searches posts by caption text — used in the Search screen Posts tab.
  // Same client-side filter approach as searchUsers().
  static Future<List<QueryDocumentSnapshot>> searchPosts(String query) async {
    final q    = query.toLowerCase();
    final snap = await _db.collection('posts').get(); // loads ALL posts
    return snap.docs
        .where((d) => (d['caption'] as String).toLowerCase().contains(q))
        .toList();
  }

  // Creates a new post document in Firestore.
  // imageBytes is stored as a List<int> (array of byte values) directly in the document.
  // This avoids needing Firebase Storage (which requires a paid plan).
  static Future<void> createPost({
    required String userId,
    required String username,
    required String caption,
    List<int>? imageBytes, // null if this is a text-only post (no image)
  }) async {
    await _db.collection('posts').add({ // .add() auto-generates the document ID
      'userId':     userId,     // links the post back to its author
      'username':   username,   // cached so the feed doesn't need a user lookup per post
      'caption':    caption,    // the text content of the post
      'imageBytes': imageBytes, // raw image data as int array, or null
      'likes':      [],         // starts with zero likes
      'createdAt':  FieldValue.serverTimestamp(), // server sets the exact time
    });
  }

  // ── Likes ──────────────────────────────────────────────────────────────────────

  // Adds the user's uid to the post's likes array.
  // arrayUnion is atomic — safe if multiple people like at the same moment.
  // It also prevents duplicates — liking twice doesn't add the uid twice.
  static Future<void> likePost(String postId, String uid) async {
    await _db.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayUnion([uid]), // add uid to likes array if not already there
    });
  }

  // Removes the user's uid from the post's likes array.
  // arrayRemove is also atomic — safe for concurrent operations.
  static Future<void> unlikePost(String postId, String uid) async {
    await _db.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayRemove([uid]), // remove uid from likes array
    });
  }

  // ── Comments ──────────────────────────────────────────────────────────────────

  // Adds a comment to a post's sub-collection.
  // Comments live at: posts/{postId}/comments/{commentId}
  // Using a sub-collection instead of an inline array avoids the 1MB Firestore
  // document limit that would eventually be hit if comments were stored inside the post.
  static Future<void> addComment({
    required String postId,
    required String userId,
    required String username,
    required String text,
  }) async {
    await _db
        .collection('posts')
        .doc(postId)
        .collection('comments') // sub-collection under this specific post
        .add({
      'userId':    userId,
      'username':  username,   // cached so we don't need a user lookup to display comments
      'text':      text,       // the actual comment text
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Returns a live stream of comments for one post, ordered oldest first.
  // The comment bottom sheet uses StreamBuilder so new comments appear instantly.
  static Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt') // oldest comment at top, newest at bottom (like a chat)
        .snapshots();
  }

  // ── Follow ────────────────────────────────────────────────────────────────────

  // Follows a user — updates BOTH users' documents in one atomic batch.
  // A Firestore batch means: if one update fails, both fail together.
  // This prevents the inconsistent state where I follow you but your follower
  // count doesn't increase (or vice versa).
  static Future<void> followUser(String myUid, String theirUid) async {
    final batch = _db.batch(); // group multiple writes into one atomic operation

    // Add theirUid to MY following list (I am now following them)
    batch.update(_db.collection('users').doc(myUid), {
      'following': FieldValue.arrayUnion([theirUid]),
    });

    // Add myUid to THEIR followers list (they have gained a new follower)
    batch.update(_db.collection('users').doc(theirUid), {
      'followers': FieldValue.arrayUnion([myUid]),
    });

    await batch.commit(); // both updates happen simultaneously
  }

  // Unfollows a user — same atomic batch pattern as followUser.
  static Future<void> unfollowUser(String myUid, String theirUid) async {
    final batch = _db.batch();

    // Remove theirUid from MY following list
    batch.update(_db.collection('users').doc(myUid), {
      'following': FieldValue.arrayRemove([theirUid]),
    });

    // Remove myUid from THEIR followers list
    batch.update(_db.collection('users').doc(theirUid), {
      'followers': FieldValue.arrayRemove([myUid]),
    });

    await batch.commit();
  }
}
