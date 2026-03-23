// ─────────────────────────────────────────────────────────────────────────────
// main.dart
// Assigned to: Garchitorena
// 
// PURPOSE:
// This is the entry point of the entire app — Flutter always starts here.
// Your job is to:
//   1. Ensure Flutter engine is ready for async work
//   2. Initialize Firebase before any screen loads
//   3. Launch the app starting at SplashScreen
// ─────────────────────────────────────────────────────────────────────────────

// TODO: import Flutter material package
// TODO: import google_fonts package
// TODO: import firebase_core package
// TODO: import firebase_options.dart (auto-generated config file)
// TODO: import splash_screen.dart

void main() async {
  // TODO: Call WidgetsFlutterBinding.ensureInitialized()
  // HINT: This is required before any async work in main()

  // TODO: Call Firebase.initializeApp()
  // HINT: Pass options: DefaultFirebaseOptions.currentPlatform
  // HINT: This must complete before any screen tries to read/write Firebase

  // TODO: Call runApp() and pass MyApp()
}

// TODO: Create MyApp class that extends StatelessWidget
// HINT: This is the root widget that wraps everything in MaterialApp

  // TODO: Override build() and return MaterialApp with:
  //   - debugShowCheckedModeBanner: false
  //     HINT: hides the red DEBUG banner on screen
  //   - title: 'Fluffy Friends'
  //     HINT: app name shown in the OS task switcher
  //   - theme: ThemeData with Inter font from GoogleFonts
  //     HINT: GoogleFonts.inter().fontFamily sets the default font
  //   - home: SplashScreen()
  //     HINT: SplashScreen checks login state and routes accordingly
