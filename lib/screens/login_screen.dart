// ─────────────────────────────────────────────────────────────────────────────
// login_screen.dart
// Assigned to: Garchitorena
//
// PURPOSE:
// Where existing users enter their username and password to log in.
// Calls FirebaseService.login() which handles Firebase Auth.
// On success, navigates to HomeScreen passing the Firebase uid.
//
// UI STRUCTURE:
//   - Colorful 4-block background (red, pink, blue, yellow)
//   - White card centered on top with:
//       - App name (Orbitron font)
//       - "Welcome back 🧸" subtitle
//       - Username field
//       - Password field with show/hide eye icon
//       - Error message (shown in red if login fails)
//       - Login button (shows spinner while loading)
//       - "Don't have an account? Sign Up" link
// ─────────────────────────────────────────────────────────────────────────────

// TODO: import flutter material package
// TODO: import google_fonts package
// TODO: import firebase_service.dart
// TODO: import home_screen.dart
// TODO: import signup_screen.dart

// TODO: Create LoginScreen class that extends StatefulWidget

  // TODO: Create _LoginScreenState with these variables:
  //   - _usernameController = TextEditingController()
  //     HINT: captures username text field input
  //   - _passwordController = TextEditingController()
  //     HINT: captures password text field input
  //   - _errorMessage (String?) = null
  //     HINT: shown in red when login fails
  //   - _obscurePassword (bool) = true
  //     HINT: true = password hidden, false = password visible
  //   - _isLoading (bool) = false
  //     HINT: true while Firebase login request is in flight

  // TODO: Implement _login() as Future<void>
  // Steps:
  //   1. Get username and password using .text.trim()
  //      HINT: .trim() removes accidental leading/trailing spaces
  //   2. If either is empty, setState _errorMessage = 'Please fill in all fields.' and return
  //   3. setState _isLoading = true, _errorMessage = null
  //   4. Inside try/catch:
  //      - Call FirebaseService.login(username: username, password: password)
  //      - Check if (!mounted) return
  //      - Navigator.pushReplacement to HomeScreen(userId: user!.uid)
  //   5. In catch block:
  //      - setState _isLoading = false
  //      - setState _errorMessage = 'Invalid username or password.'
  //      HINT: generic message for security — don't reveal which field is wrong

  // TODO: Override build() and return Scaffold with:
  //   - backgroundColor: Colors.black
  //   - body: Stack with two children:
  //
  //   CHILD 1 — Colorful background:
  //     Row with two Expanded columns:
  //       Left column:  red (0xFFE60000) top, pink (0xFFFF66B3) bottom
  //       Right column: blue (0xFF4B5CFF) top, yellow (0xFFFFEB3B) bottom
  //
  //   CHILD 2 — White login card (Center → Container):
  //     - width: 420
  //     - padding: EdgeInsets.all(40)
  //     - white background, borderRadius 20, black26 shadow
  //     - Column with mainAxisSize.min containing:
  //         1. Text 'Stuff Media' with GoogleFonts.orbitron fontSize 28 bold
  //         2. Text 'Welcome back 🧸' grey fontSize 16
  //         3. SizedBox height 32
  //         4. _buildField('Username', _usernameController)
  //         5. SizedBox height 16
  //         6. _buildField('Password', _passwordController,
  //              obscure: _obscurePassword,
  //              suffixIcon: IconButton that toggles _obscurePassword)
  //            HINT: icon is Icons.visibility_off when hidden, Icons.visibility when shown
  //         7. If _errorMessage != null show red Text
  //         8. SizedBox height 28
  //         9. ElevatedButton 'Log In' (black, full width, height 50)
  //            HINT: disabled when _isLoading (pass null to onPressed)
  //            HINT: show CircularProgressIndicator inside button when _isLoading
  //        10. SizedBox height 20
  //        11. GestureDetector that navigates to SignupScreen
  //            HINT: use RichText — grey "Don't have an account? " + bold black "Sign Up"

  // TODO: Implement _buildField() helper method
  // Parameters: label (String), controller (TextEditingController),
  //             obscure (bool = false), suffixIcon (Widget? = null)
  // Returns: Widget (Column with label Text + TextField)
  // HINT: TextField uses obscureText: obscure and decoration with suffixIcon
