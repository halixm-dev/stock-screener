import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

class AppTheme {
  static const Color _lightBackground = Color(0xFFF8F9FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightAccent = Color(0xFF2962FF);
  
  static const Color _darkBackground = Color(0xFF0B0E14);
  static const Color _darkSurface = Color(0xFF151A24);
  static const Color _darkAccent = Color(0xFF00F0FF);

  static final DesignTokens _lightTokens = DesignTokens(
    background60: _lightBackground,
    surface30: _lightSurface,
    accent10: _lightAccent,
    textPrimary: const Color(0xFF1E293B),
    textSecondary: const Color(0xFF64748B),
    cardShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.02),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
    glowEffect: [
      BoxShadow(
        color: _lightAccent.withValues(alpha: 0.3),
        blurRadius: 12,
        spreadRadius: 2,
      ),
    ],
  );

  static final DesignTokens _darkTokens = DesignTokens(
    background60: _darkBackground,
    surface30: _darkSurface,
    accent10: _darkAccent,
    textPrimary: const Color(0xFFF8FAFC),
    textSecondary: const Color(0xFF94A3B8),
    cardShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 12,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
    glowEffect: [
      BoxShadow(
        color: _darkAccent.withValues(alpha: 0.4),
        blurRadius: 16,
        spreadRadius: 2,
      ),
    ],
  );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _lightAccent,
        brightness: Brightness.light,
        surface: _lightBackground,
        primary: _lightAccent,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: _lightBackground,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      extensions: [_lightTokens],
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _darkAccent,
        brightness: Brightness.dark,
        surface: _darkBackground,
        primary: _darkAccent,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: _darkBackground,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFFF8FAFC),
        displayColor: const Color(0xFFF8FAFC),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: true,
      ),
      extensions: [_darkTokens],
    );
  }
}
