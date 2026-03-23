import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart'; // handles Firebase Auth account creation + Firestore profile save
import 'home_screen.dart';                  // destination after successful signup

// ─────────────────────────────────────────────────────────────────────────────
// SignupScreen — where new users create their account.
// Validates all fields locally first, then calls FirebaseService.signUp()
// which creates the Firebase Auth account AND saves the profile to Firestore.
//
// Password rules (stronger than Firebase's default 6-char minimum):
//   - At least 8 characters
//   - Must contain at least one number
//   - Must contain at least one letter
// Live hints appear below the password field as the user types.
// ─────────────────────────────────────────────────────────────────────────────

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // One controller per input field — each captures what the user types
  final _fullNameController  = TextEditingController();
  final _usernameController  = TextEditingController();
  final _passwordController  = TextEditingController();

  String? _errorMessage;        // shown in red when any validation fails
  bool _obscurePassword = true; // toggles password visibility
  bool _isLoading = false;      // true while Firebase signup request is in flight

  // Called when the user taps the "Sign Up" button
  Future<void> _signup() async {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // ── Client-side validation (runs before touching Firebase) ──────────────

    // All three fields are required
    if (fullName.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    // Usernames can't have spaces — would break @mentions and searching
    if (username.contains(' ')) {
      setState(() => _errorMessage = 'Username cannot have spaces.');
      return;
    }

    // Minimum 8 characters — stronger than Firebase's default 6
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }

    // Must contain at least one digit (0-9)
    if (!password.contains(RegExp(r'[0-9]'))) {
      setState(() => _errorMessage = 'Password must contain at least one number.');
      return;
    }

    // Must contain at least one letter (a-z or A-Z)
    if (!password.contains(RegExp(r'[a-zA-Z]'))) {
      setState(() => _errorMessage = 'Password must contain at least one letter.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; }); // show spinner

    try {
      // FirebaseService.signUp() checks username uniqueness, creates the Auth account,
      // and saves the profile to Firestore — all in one call
      final user = await FirebaseService.signUp(
        fullName: fullName,
        username: username,
        password: password,
      );

      if (!mounted) return;

      // Signup succeeded — go straight to the feed
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(userId: user!.uid)),
      );
    } catch (e) {
      // FirebaseService throws Exception('Username already taken.') for duplicates,
      // or Firebase Auth errors for other issues (e.g. weak password)
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', ''); // clean up message
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Colorful 4-block background
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

          // White signup card — wrapped in SingleChildScrollView so the password
          // hints don't get cut off on smaller screens when keyboard appears
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 420,
                margin: const EdgeInsets.symmetric(vertical: 40),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 15)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stuff Media',
                        style: GoogleFonts.orbitron(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Create your account 🧸',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 32),

                    // Full name field — shown on the profile page
                    _buildField('Full Name', _fullNameController),
                    const SizedBox(height: 16),

                    // Username field — shown on posts and searchable
                    _buildField('Username', _usernameController,
                        hint: 'No spaces, shown on your profile'),
                    const SizedBox(height: 16),

                    // Password field with show/hide toggle and strength hints
                    _buildField('Password', _passwordController,
                        obscure: _obscurePassword,
                        hint: 'Min 8 chars, include a letter and number',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        )),

                    // Live password strength hints — appear as user types
                    const SizedBox(height: 6),
                    _buildPasswordHint(),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 28),

                    // Sign Up button — shows spinner while loading
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Sign Up',
                                style:
                                    TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // "Already have an account? Log In" link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context), // goes back to LoginScreen
                        child: RichText(
                          text: const TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: Colors.grey),
                            children: [
                              TextSpan(
                                text: 'Log In',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
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
          ),
        ],
      ),
    );
  }

  // Builds the live password strength indicator shown below the password field.
  // Checks three rules and shows a green check or red X for each.
  Widget _buildPasswordHint() {
    final password  = _passwordController.text;
    final hasLength = password.length >= 8;                      // rule 1: 8+ chars
    final hasNumber = password.contains(RegExp(r'[0-9]'));       // rule 2: has a digit
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));    // rule 3: has a letter

    // Don't show anything until the user starts typing the password
    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hintRow(hasLength, 'At least 8 characters'),
        _hintRow(hasNumber, 'Contains a number'),
        _hintRow(hasLetter, 'Contains a letter'),
      ],
    );
  }

  // Single row in the password hints — green check if met, red X if not
  Widget _hintRow(bool met, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.cancel, // tick or X icon
            size: 14,
            color: met ? Colors.green : Colors.red.shade300,
          ),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                fontSize: 12,
                color: met ? Colors.green : Colors.red.shade300,
              )),
        ],
      ),
    );
  }

  // Reusable field builder — label above, TextField below.
  // Uses StatefulBuilder so calling setState() in onChanged() only rebuilds
  // the password hints widget instead of the entire screen.
  Widget _buildField(String label, TextEditingController controller,
      {bool obscure = false, String? hint, Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        StatefulBuilder(
          builder: (_, setField) => TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: (_) => setState(() {}), // rebuilds password hints on each keystroke
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
