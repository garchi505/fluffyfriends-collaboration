// ─────────────────────────────────────────────────────────────────────────────
// splash_screen.dart
// Assigned to: Garchitorena
//
// PURPOSE:
// First screen shown when the app opens.
// Shows the app name + loading spinner for 2 seconds.
// Then checks if a user is already logged in and routes accordingly:
//   - Already logged in → go to HomeScreen (skip login)
//   - Not logged in     → go to LoginScreen
//
// Firebase Auth automatically remembers the session between app restarts.
// No manual session saving needed — just check FirebaseAuth.instance.currentUser
// ─────────────────────────────────────────────────────────────────────────────

// TODO: import flutter material package
// TODO: import google_fonts package
// TODO: import firebase_auth package
//       HINT: needed to check FirebaseAuth.instance.currentUser
// TODO: import home_screen.dart
// TODO: import login_screen.dart

// TODO: Create SplashScreen class that extends StatefulWidget

  // TODO: Create _SplashScreenState

    // TODO: Override initState()
    //       HINT: always call super.initState() first
    //       HINT: then call _checkSession()

    // TODO: Implement _checkSession() as Future<void>
    // Steps:
    //   1. await Future.delayed(const Duration(seconds: 2))
    //      HINT: this makes the splash visible for 2 seconds
    //   2. Check if (!mounted) return
    //      HINT: mounted check prevents errors if widget was disposed during delay
    //   3. Get current user: FirebaseAuth.instance.currentUser
    //   4. If user is not null:
    //      - Navigator.pushReplacement to HomeScreen(userId: user.uid)
    //      HINT: pushReplacement removes splash from stack so back button skips it
    //   5. If user is null:
    //      - Navigator.pushReplacement to LoginScreen()

    // TODO: Override build() and return Scaffold with:
    //   - backgroundColor: Colors.black
    //   - body: Center with Column containing:
    //       1. Text 'Stuff Media' with GoogleFonts.orbitron style
    //          HINT: color white, fontSize 36, fontWeight bold
    //       2. SizedBox height 20
    //       3. CircularProgressIndicator with white color
    //          HINT: this spins while the 2 second delay runs
