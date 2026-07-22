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
  // --- TANGERINE & NAVY CORE PALETTE ---
  static const Color tangerine = Color(0xFFFF6D00);
  static const Color navy = Color(0xFF0A1128);
  static const Color navyLighter = Color(0xFF16203B);
  static const Color navyDarkest = Color(0xFF050A18);
  
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // Background Gradients
  static LinearGradient bgGradient(bool dark) {
    return dark
        ? const LinearGradient(
            colors: [navyDarkest, navy],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFF4F6F9), Color(0xFFE0E5EC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  // Blob Card Gradients
  static LinearGradient blobGradient(bool dark, [int index = 0]) {
    if (dark) {
      return LinearGradient(
        colors: [
          navyLighter.withOpacity(0.8),
          navy.withOpacity(0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: [
          Colors.white,
          const Color(0xFFF0F2F5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  // Primary Button Gradient
  static LinearGradient primaryButtonGradient(bool dark) {
    return const LinearGradient(
      colors: [tangerine, Color(0xFFFF9E00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  // Secondary/Action Button Gradient
  static LinearGradient secondaryButtonGradient(bool dark) {
    return dark
        ? const LinearGradient(
            colors: [navyLighter, navy],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFE0E5EC), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  // Text Colors
  static Color textTitle(bool dark) => dark ? Colors.white : navy;
  static Color textMain(bool dark) => dark ? const Color(0xFFA0AABF) : navyLighter;
  static Color textSecondary(bool dark) => dark ? const Color(0xFF5A6B87) : Colors.grey[600]!;
  static Color textButton(bool dark) => Colors.white;
  
  // Borders and Shadows
  static Color borderMain(bool dark) => dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);
  static Color borderButton(bool dark) => tangerine.withOpacity(0.5);
  static Color shadowMain(bool dark) => dark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1);
  static Color brutalistShadow(bool dark) => dark ? Colors.black : Colors.black.withOpacity(0.2);
  
  // Claymorphism: Soft, matte 3D shadow
  static BoxShadow claymorphismShadow(bool dark) {
    return BoxShadow(
      color: dark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1),
      blurRadius: 15,
      offset: const Offset(8, 8),
    );
  }

  // Claymorphism: Inset shadow
  static BoxShadow claymorphismHighlight(bool dark) {
    return BoxShadow(
      color: dark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
      blurRadius: 12,
      offset: const Offset(-4, -4),
    );
  }

  // Glassmorphism
  static Color glassHeaderColor(bool dark) {
    return dark
      ? navyLighter.withOpacity(0.8)
      : Colors.white.withOpacity(0.8);
  }

  static List<BoxShadow> glassmorphismShadow(bool dark) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static Color searchBarBackground(bool dark) {
    return dark ? navyLighter.withOpacity(0.5) : Colors.white;
  }

  static Color categoryChipBackground(bool dark, bool selected) {
    if (selected) return tangerine;
    return dark ? navyLighter : Colors.white;
  }
}
