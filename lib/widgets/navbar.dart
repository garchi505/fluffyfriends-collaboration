import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Orbitron font for the app name

// ─────────────────────────────────────────────────────────────────────────────
// NavBar — the top bar that stays visible on every screen inside HomeScreen.
// Shows only the app name "Fluffy Friends" in the Orbitron font.
// Navigation is handled by the BottomNavigationBar in HomeScreen instead.
// Unchanged from the original Hive version — no Firebase calls needed here.
// ─────────────────────────────────────────────────────────────────────────────

class NavBar extends StatelessWidget {
  const NavBar({super.key}); // const constructor so Flutter can cache and reuse this widget

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,                                        // fixed height for the top bar
      color: const Color(0xFF1C1C1C),                   // dark charcoal — matches bottom nav
      padding: const EdgeInsets.symmetric(horizontal: 30), // left/right breathing room
      child: Row(
        children: [
          Text(
            'Fluffy Friends', // app name shown in every screen's top bar
            style: GoogleFonts.orbitron( // Orbitron gives the modern/techy look
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
