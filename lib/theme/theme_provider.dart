import 'package:flutter/material.dart';

class ThemeProvider {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  static void toggleTheme() {
    if (themeMode.value == ThemeMode.light) {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }
  }
}

class AppColors {
  // Common Neon Colors
  static const Color neonPink = Color(0xFFFF007F);
  static const Color electricCyan = Color(0xFF00F0FF);
  
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // Background Gradients
  static LinearGradient bgGradient(bool dark) {
    return dark
        ? const LinearGradient(
            colors: [Color(0xFF0B0510), Color(0xFF1A0B2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  // Blob Card Gradients
  static LinearGradient blobGradient(bool dark, [int index = 0]) {
    if (dark) {
      if (index % 2 == 0) {
        return const LinearGradient(colors: [Color(0xFF1A0B2E), Color(0xFF2C1B4D)]);
      } else {
        return const LinearGradient(colors: [Color(0xFF0B0510), Color(0xFF200F3A)]);
      }
    } else {
      if (index % 2 == 0) {
        return const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFE3EEFF)]);
      } else {
        return const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFFE5D9)]);
      }
    }
  }

  // Brutalist Button Gradient (Primary)
  static LinearGradient primaryButtonGradient(bool dark) {
    return dark
        ? const LinearGradient(
            colors: [neonPink, electricCyan],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }
  
  // Brutalist Button Gradient (Secondary/Success)
  static LinearGradient secondaryButtonGradient(bool dark) {
    return dark
        ? const LinearGradient(
            colors: [Color(0xFF200F3A), electricCyan],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFD8F3DC), Color(0xFFA3CEF1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  // Text Colors
  static Color textTitle(bool dark) => dark ? Colors.white : const Color(0xFF5A189A);
  static Color textMain(bool dark) => dark ? Colors.white : Colors.deepPurple[900]!;
  static Color textSecondary(bool dark) => dark ? Colors.grey[400]! : Colors.blueGrey[600]!;
  static Color textButton(bool dark) => dark ? Colors.black : const Color(0xFF003049);
  
  // Borders and Shadows
  static Color borderMain(bool dark) => dark ? electricCyan.withOpacity(0.5) : Colors.white;
  static Color borderButton(bool dark) => dark ? electricCyan : Colors.black;
  static Color shadowMain(bool dark) => dark ? electricCyan.withOpacity(0.3) : Colors.deepPurple.withOpacity(0.15);
  static Color brutalistShadow(bool dark) => dark ? electricCyan : Colors.black;
  
  // Input Fields
  static Color inputBackground(bool dark) => dark ? const Color(0xFF2C1B4D).withOpacity(0.8) : Colors.white.withOpacity(0.7);
  static Color navBarColor(bool dark) => dark ? const Color(0xFF0B0510).withOpacity(0.9) : Colors.white.withOpacity(0.8);
}
