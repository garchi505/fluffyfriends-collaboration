import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart'; // handles the actual Firebase Auth login call
import 'home_screen.dart';                  // destination after successful login
import 'signup_screen.dart';                // destination when tapping "Sign Up"

// ─────────────────────────────────────────────────────────────────────────────
// LoginScreen — where existing users enter their username and password.
// FirebaseService.login() handles authentication with Firebase Auth.
// On success, navigates to HomeScreen with the Firebase uid.
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers capture whatever the user types in each text field
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _errorMessage;        // shown in red below the fields when login fails
  bool _obscurePassword = true; // true = password hidden, false = characters visible
  bool _isLoading = false;      // true while the Firebase login request is in flight

  // Called when the user taps the "Log In" button
  Future<void> _login() async {
    final username = _usernameController.text.trim(); // trim removes accidental spaces
    final password = _passwordController.text.trim();

    // Validate fields before hitting Firebase — avoids unnecessary network calls
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return; // stop here
    }

    setState(() { _isLoading = true; _errorMessage = null; }); // show spinner

    try {
      // FirebaseService.login() builds the fake email from username and calls Firebase Auth
      final user = await FirebaseService.login(
        username: username,
        password: password,
      );

      if (!mounted) return; // widget may have been disposed while awaiting

      // Login succeeded — go to the feed, replacing the login screen so
      // pressing back doesn't bring the user back to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(userId: user!.uid)),
      );
    } catch (e) {
      // Firebase throws exceptions for wrong password, user not found, network issues, etc.
      // We show a generic message — don't reveal which field is wrong for security reasons
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid username or password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // black shows behind the colorful blocks
      body: Stack(
        // Stack layers the colorful background blocks behind the white login card
        children: [

          // ── Colorful 4-block background (your original UI style) ────────────
          Row(
            children: [
              Expanded(child: Column(children: [
                Expanded(child: Container(color: const Color(0xFFE60000))), // top-left: red
                Expanded(child: Container(color: const Color(0xFFFF66B3))), // bottom-left: pink
              ])),
              Expanded(child: Column(children: [
                Expanded(child: Container(color: const Color(0xFF4B5CFF))), // top-right: blue
                Expanded(child: Container(color: const Color(0xFFFFEB3B))), // bottom-right: yellow
              ])),
            ],
          ),

          // ── White login card centered over the background ────────────────────
          Center(
            child: Container(
              width: 420, // fixed width so card doesn't stretch on wide screens
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 15)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // shrink to fit content height
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App name at top of card
                  Text('Stuff Media',
                      style: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Welcome back 🧸',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 32),

                  // Username input field
                  _buildField('Username', _usernameController),
                  const SizedBox(height: 16),

                  // Password input field with show/hide eye icon
                  _buildField('Password', _passwordController,
                      obscure: _obscurePassword, // hides characters when true
                      suffixIcon: IconButton(
                        // Eye icon toggles password visibility
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off  // slash = hidden
                            : Icons.visibility),    // open eye = visible
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      )),

                  // Error message — only rendered if _errorMessage is not null
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 28),

                  // Login button — disabled while loading to prevent double-taps
                  SizedBox(
                    width: double.infinity, // stretches to full card width
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login, // null disables the button
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      // Shows a spinner inside the button while logging in
                      child: _isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Log In',
                              style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // "Don't have an account? Sign Up" link at the bottom
                  Center(
                    child: GestureDetector(
                      // push (not pushReplacement) so back arrow returns to login
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupScreen())),
                      child: RichText(
                        // RichText lets us style parts of the text differently
                        text: const TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: Colors.grey),
                          children: [
                            TextSpan(
                              text: 'Sign Up', // bold black clickable part
                              style: TextStyle(
                                  color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable text field builder — builds a label + TextField pair.
  // obscure: hides the text (used for password)
  // suffixIcon: optional widget on the right (eye toggle button)
  Widget _buildField(String label, TextEditingController controller,
      {bool obscure = false, Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller, // links field to its controller variable
          obscureText: obscure,   // true = show dots instead of characters
          decoration: InputDecoration(
            suffixIcon: suffixIcon, // eye button shown on the right for password
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
