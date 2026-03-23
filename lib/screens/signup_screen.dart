// ─────────────────────────────────────────────────────────────────────────────
// signup_screen.dart
// Assigned to: Garchitorena
//
// PURPOSE:
// Where new users create their account.
// Validates all fields locally first, then calls FirebaseService.signUp()
// which creates the Firebase Auth account AND saves the profile to Firestore.
//
// PASSWORD RULES (stronger than Firebase's default):
//   - At least 8 characters
//   - Must contain at least one number (0-9)
//   - Must contain at least one letter (a-z or A-Z)
//   - Live hints appear below the field as the user types
//     showing green check ✓ or red X for each rule
//
// UI STRUCTURE:
//   - Same colorful 4-block background as LoginScreen
//   - White card with SingleChildScrollView (so hints fit on small screens)
//   - Full Name, Username, Password fields
//   - Live password strength hints below password field
//   - Sign Up button + "Already have an account? Log In" link
// ─────────────────────────────────────────────────────────────────────────────

// TODO: import flutter material package
// TODO: import google_fonts package
// TODO: import firebase_service.dart
// TODO: import home_screen.dart

// TODO: Create SignupScreen class that extends StatefulWidget

  // TODO: Create _SignupScreenState with these variables:
  //   - _fullNameController = TextEditingController()
  //   - _usernameController = TextEditingController()
  //   - _passwordController = TextEditingController()
  //   - _errorMessage (String?) = null
  //   - _obscurePassword (bool) = true
  //   - _isLoading (bool) = false

  // TODO: Implement _signup() as Future<void>
  // Steps:
  //   1. Get fullName, username, password using .text.trim()
  //   2. Validate — check each rule and setState _errorMessage if broken:
  //      a. All fields empty → 'Please fill in all fields.'
  //      b. Username contains space → 'Username cannot have spaces.'
  //      c. Password length < 8 → 'Password must be at least 8 characters.'
  //      d. No digit in password → 'Password must contain at least one number.'
  //         HINT: use RegExp(r'[0-9]') with .contains()
  //      e. No letter in password → 'Password must contain at least one letter.'
  //         HINT: use RegExp(r'[a-zA-Z]') with .contains()
  //   3. setState _isLoading = true, _errorMessage = null
  //   4. Inside try/catch:
  //      - Call FirebaseService.signUp(fullName, username, password)
  //      - Check if (!mounted) return
  //      - Navigator.pushReplacement to HomeScreen(userId: user!.uid)
  //   5. In catch block:
  //      - setState _isLoading = false
  //      - setState _errorMessage = e.toString().replaceAll('Exception: ', '')
  //        HINT: this cleans up the error message shown to the user

  // TODO: Override build() and return Scaffold with:
  //   - backgroundColor: Colors.black
  //   - body: Stack with:
  //
  //   CHILD 1 — Same colorful background as LoginScreen
  //
  //   CHILD 2 — White signup card wrapped in SingleChildScrollView:
  //     Center → SingleChildScrollView → Container:
  //       - width: 420, margin vertical 40, padding all 40
  //       - white background, borderRadius 20, shadow
  //       - Column containing:
  //           1. Text 'Stuff Media' Orbitron bold 28
  //           2. Text 'Create your account 🧸' grey 16
  //           3. SizedBox height 32
  //           4. _buildField('Full Name', _fullNameController)
  //           5. SizedBox height 16
  //           6. _buildField('Username', _usernameController, hint: 'No spaces, shown on your profile')
  //           7. SizedBox height 16
  //           8. _buildField('Password', _passwordController,
  //                obscure: _obscurePassword,
  //                hint: 'Min 8 chars, include a letter and number',
  //                suffixIcon: eye toggle IconButton)
  //           9. SizedBox height 6
  //          10. _buildPasswordHint()
  //              HINT: shows live green/red indicators as user types
  //          11. If _errorMessage != null show red Text
  //          12. SizedBox height 28
  //          13. ElevatedButton 'Sign Up' (black, full width, height 50)
  //              HINT: show spinner inside when _isLoading
  //          14. SizedBox height 20
  //          15. GestureDetector → Navigator.pop(context) → back to LoginScreen
  //              HINT: RichText — grey "Already have an account? " + bold black "Log In"

  // TODO: Implement _buildPasswordHint() → Widget
  // Steps:
  //   1. Get password from _passwordController.text
  //   2. Check three booleans:
  //      - hasLength = password.length >= 8
  //      - hasNumber = password.contains(RegExp(r'[0-9]'))
  //      - hasLetter = password.contains(RegExp(r'[a-zA-Z]'))
  //   3. If password.isEmpty return SizedBox.shrink() (show nothing)
  //   4. Return Column with three _hintRow() calls:
  //      - _hintRow(hasLength, 'At least 8 characters')
  //      - _hintRow(hasNumber, 'Contains a number')
  //      - _hintRow(hasLetter, 'Contains a letter')

  // TODO: Implement _hintRow(bool met, String text) → Widget
  // Returns a Row with:
  //   - Icon: Icons.check_circle (green) if met, Icons.cancel (red) if not
  //     HINT: size 14, color met ? Colors.green : Colors.red.shade300
  //   - SizedBox width 6
  //   - Text with matching color and fontSize 12

  // TODO: Implement _buildField() helper method
  // Same as LoginScreen but with extra optional 'hint' parameter (String?)
  // HINT: Uses StatefulBuilder so onChanged: (_) => setState((){})
  //       only rebuilds password hints instead of the entire screen
