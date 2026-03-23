import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // lets us check if a user is already logged in
import 'home_screen.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SplashScreen — the first screen shown when the app opens.
// Shows the app name + spinner for 2 seconds, then automatically routes:
//   - Already logged in  → go straight to the Feed (HomeScreen)
//   - Not logged in      → go to LoginScreen
//
// Firebase Auth automatically remembers the logged-in user between app restarts.
// We just check FirebaseAuth.instance.currentUser — no manual session saving needed.
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState(); // always call super first in Flutter lifecycle methods
    _checkSession();   // check login state as soon as the screen appears
  }

  // Waits 2 seconds (so the splash is visible), then checks if anyone is logged in.
  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2)); // pause for the splash animation

    // mounted checks if this widget is still in the tree.
    // If the user somehow navigated away during the delay, don't push another route.
    if (!mounted) return;

    // Firebase Auth keeps the user logged in automatically.
    // currentUser is non-null if a session exists, null if nobody is logged in.
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Session found — go straight to the feed, skipping login
      Navigator.pushReplacement( // pushReplacement removes the splash from the stack
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(userId: user.uid)), // pass Firebase uid
      );
    } else {
      // No session — user needs to log in or sign up
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // full black background for the splash
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // vertically center everything
          children: [
            // App name in the Orbitron font — same font used in the NavBar
            Text(
              'Stuff Media',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20), // space between title and spinner
            // White loading spinner shown while the 2-second delay runs
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
