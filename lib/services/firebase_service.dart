// ─────────────────────────────────────────────────────────────────────────────
// firebase_service.dart
// Assigned to: Garchitorena
//
// PURPOSE:
// This is the single place where ALL data is read from and written to Firebase.
// Every other screen calls methods from this file — nothing else touches Firebase directly.
//
// YOU NEED TO IMPLEMENT:
//   - Auth:     signUp, login, logout, currentUser
//   - Users:    getUserById, getUserByUsername, searchUsers
//   - Posts:    getFeedStream, getUserPostsStream, searchPosts, createPost
//   - Likes:    likePost, unlikePost
//   - Comments: addComment, getCommentsStream
//   - Follow:   followUser, unfollowUser
//
// HOW FIREBASE WORKS IN THIS APP:
//   Firebase Auth  = handles who is logged in (creates accounts, sessions)
//   Firestore      = the cloud database (stores users, posts, comments, follows)
//   Stream         = Firestore pushes live updates to the UI automatically
//
// All methods are static — called like: FirebaseService.login(...)
// ─────────────────────────────────────────────────────────────────────────────

// TODO: import firebase_auth package
// TODO: import cloud_firestore package

class FirebaseService {

  // TODO: Create two static final variables:
  //   - _auth = FirebaseAuth.instance
  //     HINT: this handles all authentication operations
  //   - _db = FirebaseFirestore.instance
  //     HINT: this handles all database read/write operations

  // ── Auth ───────────────────────────────────────────────────────────────────

  // TODO: Create a static getter called currentUser that returns User?
  // HINT: return _auth.currentUser
  // HINT: Firebase automatically remembers who is logged in — no manual saving needed

  // TODO: Implement signUp method
  // Parameters: fullName (String), username (String), password (String)
  // Returns: Future<User?>
  // Steps:
  //   1. Call getUserByUsername(username) to check if username is already taken
  //      HINT: if result is not null, throw Exception('Username already taken.')
  //   2. Build a fake email: '$username@fluffyfriends.app'
  //      HINT: Firebase Auth requires email format — users never see this email
  //   3. Call _auth.createUserWithEmailAndPassword(email: email, password: password)
  //      HINT: store result in a variable called cred
  //   4. Get uid from cred.user!.uid
  //   5. Save profile to Firestore: _db.collection('users').doc(uid).set({...})
  //      HINT: store these fields: uid, fullName, username, followers: [], following: [], createdAt
  //      HINT: use FieldValue.serverTimestamp() for createdAt
  //   6. Return cred.user

  // TODO: Implement login method
  // Parameters: username (String), password (String)
  // Returns: Future<User?>
  // Steps:
  //   1. Build the fake email: '$username@fluffyfriends.app'
  //      HINT: must match the exact format used in signUp
  //   2. Call _auth.signInWithEmailAndPassword(email: email, password: password)
  //   3. Return cred.user

  // TODO: Implement logout method
  // Returns: Future<void>
  // HINT: call _auth.signOut()
  // HINT: Firebase clears the session automatically after this

  // ── Users ──────────────────────────────────────────────────────────────────

  // TODO: Implement getUserById method
  // Parameters: uid (String)
  // Returns: Future<Map<String, dynamic>?>
  // Steps:
  //   1. Call _db.collection('users').doc(uid).get()
  //   2. Return snap.data()
  //      HINT: .data() returns null if the document doesn't exist

  // TODO: Implement getUserByUsername method
  // Parameters: username (String)
  // Returns: Future<Map<String, dynamic>?>
  // Steps:
  //   1. Query _db.collection('users').where('username', isEqualTo: username).limit(1).get()
  //      HINT: .limit(1) stops Firestore from reading more than needed
  //   2. If snap.docs.isEmpty return null
  //   3. Otherwise return snap.docs.first.data()

  // TODO: Implement searchUsers method
  // Parameters: query (String)
  // Returns: Future<List<Map<String, dynamic>>>
  // Steps:
  //   1. Convert query to lowercase: query.toLowerCase()
  //   2. Get ALL users: _db.collection('users').get()
  //   3. Map each doc to its data()
  //   4. Filter where username OR fullName contains the query (case-insensitive)
  //   5. Return as list
  //   HINT: Firestore doesn't support full-text search so we filter client-side

  // ── Posts ──────────────────────────────────────────────────────────────────

  // TODO: Implement getFeedStream method
  // Returns: Stream<QuerySnapshot>
  // Steps:
  //   1. Return _db.collection('posts').orderBy('createdAt', descending: true).snapshots()
  //   HINT: .snapshots() = live stream, updates automatically when data changes
  //   HINT: descending: true = newest post at the top

  // TODO: Implement getUserPostsStream method
  // Parameters: uid (String)
  // Returns: Stream<QuerySnapshot>
  // Steps:
  //   1. Return _db.collection('posts')
  //      .where('userId', isEqualTo: uid)
  //      .orderBy('createdAt', descending: true)
  //      .snapshots()
  //   HINT: This requires a Firestore composite index (userId ASC, createdAt DESC)

  // TODO: Implement searchPosts method
  // Parameters: query (String)
  // Returns: Future<List<QueryDocumentSnapshot>>
  // Steps:
  //   1. Convert query to lowercase
  //   2. Get ALL posts: _db.collection('posts').get()
  //   3. Filter where caption contains the query (case-insensitive)
  //   4. Return as list

  // TODO: Implement createPost method
  // Parameters: userId, username, caption (all String), imageBytes (List<int>?)
  // Returns: Future<void>
  // Steps:
  //   1. Call _db.collection('posts').add({...})
  //      HINT: .add() auto-generates the document ID
  //      HINT: store these fields: userId, username, caption, imageBytes, likes: [], createdAt
  //      HINT: imageBytes is null if text-only post
  //      HINT: use FieldValue.serverTimestamp() for createdAt

  // ── Likes ──────────────────────────────────────────────────────────────────

  // TODO: Implement likePost method
  // Parameters: postId (String), uid (String)
  // Returns: Future<void>
  // Steps:
  //   1. Update the post: _db.collection('posts').doc(postId).update({...})
  //   2. Set likes: FieldValue.arrayUnion([uid])
  //      HINT: arrayUnion adds uid without duplicates — atomic and safe

  // TODO: Implement unlikePost method
  // Parameters: postId (String), uid (String)
  // Returns: Future<void>
  // Steps:
  //   1. Update the post: _db.collection('posts').doc(postId).update({...})
  //   2. Set likes: FieldValue.arrayRemove([uid])
  //      HINT: arrayRemove removes uid if it exists — atomic and safe

  // ── Comments ───────────────────────────────────────────────────────────────

  // TODO: Implement addComment method
  // Parameters: postId, userId, username, text (all String)
  // Returns: Future<void>
  // Steps:
  //   1. Add to sub-collection: _db.collection('posts').doc(postId).collection('comments').add({...})
  //      HINT: sub-collection path: posts/{postId}/comments/{commentId}
  //      HINT: store these fields: userId, username, text, createdAt
  //      HINT: using sub-collection avoids Firestore's 1MB document size limit

  // TODO: Implement getCommentsStream method
  // Parameters: postId (String)
  // Returns: Stream<QuerySnapshot>
  // Steps:
  //   1. Return _db.collection('posts').doc(postId).collection('comments')
  //      .orderBy('createdAt').snapshots()
  //      HINT: orderBy WITHOUT descending = oldest first (like a chat conversation)

  // ── Follow ─────────────────────────────────────────────────────────────────

  // TODO: Implement followUser method
  // Parameters: myUid (String), theirUid (String)
  // Returns: Future<void>
  // Steps:
  //   1. Create a batch: _db.batch()
  //      HINT: batch groups multiple writes into one atomic operation
  //      HINT: if one fails, both fail — prevents inconsistent data
  //   2. batch.update myUid's document: add theirUid to 'following' using arrayUnion
  //   3. batch.update theirUid's document: add myUid to 'followers' using arrayUnion
  //   4. await batch.commit()
  //      HINT: both updates happen simultaneously

  // TODO: Implement unfollowUser method
  // Parameters: myUid (String), theirUid (String)
  // Returns: Future<void>
  // Steps:
  //   1. Create a batch: _db.batch()
  //   2. batch.update myUid's document: remove theirUid from 'following' using arrayRemove
  //   3. batch.update theirUid's document: remove myUid from 'followers' using arrayRemove
  //   4. await batch.commit()
}
