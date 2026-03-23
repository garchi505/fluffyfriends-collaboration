import 'package:flutter/material.dart';
import '../services/firebase_service.dart'; // to load the current user's Firestore profile
import '../widgets/hero_section.dart';      // Feed screen content (tab 0)
import '../widgets/navbar.dart';            // top "Fluffy Friends" bar — always visible
import 'create_post_screen.dart';           // opened as a modal when tapping "+"
import 'profile_screen.dart';              // shown when tapping the Profile tab (tab 3)
import 'search_screen.dart';               // shown when tapping the Search tab (tab 1)

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — the main shell of the app after login.
// Holds two persistent UI elements:
//   1. NavBar at the top (app name, always visible on every tab)
//   2. BottomNavigationBar at the bottom (switches between screens)
//
// Tab layout: 0=Feed | 1=Search | 2=Create(modal) | 3=Profile
//
// userId is the Firebase uid passed in from SplashScreen or LoginScreen.
// We load the full user profile from Firestore on init.
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final String userId; // Firebase uid of the logged-in user
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;              // which bottom nav tab is currently active (default: Feed)
  Map<String, dynamic>? _currentUser; // the logged-in user's Firestore profile data
  bool _loaded = false;                // false while the profile is being loaded from Firestore

  @override
  void initState() {
    super.initState();
    _loadUser(); // fetch the user profile from Firestore as soon as this screen appears
  }

  // Loads the current user's profile from Firestore.
  // Called on init AND after follow/unfollow so the following list stays accurate
  // (which keeps the Follow/Following buttons in the feed correct).
  Future<void> _loadUser() async {
    final user = await FirebaseService.getUserById(widget.userId);
    if (user != null && mounted) { // mounted check — widget might be disposed while awaiting
      setState(() {
        _currentUser = user; // store the Firestore profile map
        _loaded = true;      // allow the UI to render now that data is ready
      });
    }
  }

  // Called whenever the user taps one of the bottom nav items
  void _onNavTap(int index) {
    if (index == 2) {
      // Index 2 is the "+" Create button.
      // We open CreatePostScreen as a full-screen modal overlay instead of
      // switching to a tab, because creating a post is an action not a destination.
      // The selected tab index does NOT change when tapping "+".
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreatePostScreen(
            currentUser: _currentUser!,
            onPostCreated: () => setState(() {}), // triggers a rebuild so feed refreshes
          ),
        ),
      );
      return; // exit early — don't fall through to setState below
    }
    // For Feed (0), Search (1), and Profile (3), just update the selected index
    setState(() => _selectedIndex = index);
  }

  // Returns the correct screen widget based on which tab is active
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        // Feed — shows all posts from Firestore in real time via StreamBuilder
        return HeroSection(currentUser: _currentUser!, onRefresh: _loadUser);
      case 1:
        // Search — lets user search for other users and posts
        return SearchScreen(currentUser: _currentUser!, onRefresh: _loadUser);
      case 3:
        // Profile — shows the logged-in user's own profile with posts grid + logout
        return ProfileScreen(
          viewedUserId: widget.userId, // show YOUR profile
          currentUser:  _currentUser!,
          onRefresh:    _loadUser,     // reload user data after follow/logout changes
        );
      default:
        return HeroSection(currentUser: _currentUser!, onRefresh: _loadUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a spinner while the user profile loads from Firestore on first launch
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black, // black fills the gap between NavBar and card
      body: Column(
        children: [
          const NavBar(),               // top bar always visible — shows "Fluffy Friends"
          Expanded(child: _buildBody()), // fills remaining space with the active screen
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // highlights the active tab
        onTap: _onNavTap,             // handles all tab taps
        type: BottomNavigationBarType.fixed, // fixed = all labels always visible
        backgroundColor: const Color(0xFF1C1C1C), // dark bar matching the top NavBar
        selectedItemColor: Colors.white,   // active tab = white icon + label
        unselectedItemColor: Colors.grey,  // inactive tabs = grey
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home),             label: 'Home'),    // index 0
          BottomNavigationBarItem(icon: Icon(Icons.search),           label: 'Search'),  // index 1
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Create'),  // index 2
          BottomNavigationBarItem(icon: Icon(Icons.person),           label: 'Profile'), // index 3
        ],
      ),
    );
  }
}
