import 'package:flutter/material.dart';

class DesignTokens extends ThemeExtension<DesignTokens> {
  final Color background60;
  final Color surface30;
  final Color accent10;
  final Color textPrimary;
  final Color textSecondary;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> glowEffect;

  const DesignTokens({
    required this.background60,
    required this.surface30,
    required this.accent10,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardShadow,
    required this.glowEffect,
  });

  @override
  ThemeExtension<DesignTokens> copyWith({
    Color? background60,
    Color? surface30,
    Color? accent10,
    Color? textPrimary,
    Color? textSecondary,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? glowEffect,
  }) {
    return DesignTokens(
      background60: background60 ?? this.background60,
      surface30: surface30 ?? this.surface30,
      accent10: accent10 ?? this.accent10,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      cardShadow: cardShadow ?? this.cardShadow,
      glowEffect: glowEffect ?? this.glowEffect,
    );
  }

  @override
  ThemeExtension<DesignTokens> lerp(
    covariant ThemeExtension<DesignTokens>? other,
    double t,
  ) {
    if (other is! DesignTokens) {
      return this;
    }
    return DesignTokens(
      background60: Color.lerp(background60, other.background60, t)!,
      surface30: Color.lerp(surface30, other.surface30, t)!,
      accent10: Color.lerp(accent10, other.accent10, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t) ?? cardShadow,
      glowEffect: BoxShadow.lerpList(glowEffect, other.glowEffect, t) ?? glowEffect,
    );
  }
}
