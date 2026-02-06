import 'package:flutter/material.dart';

/// Palette de couleurs Vases d'Honneur
/// - Rouge Cramoisi : Royaume des Cieux, Sang du Christ
/// - Jaune Doré : Honneur, Excellence, Pureté
/// - Vert Espérance : Espérance chrétienne
class AppColors {
  AppColors._();

  // Couleurs principales - Evening Sea (Vert/Bleu foncé)
  static const Color primary = Color(0xFF025456);
  static const Color primaryLight = Color(0xFF037A7D);
  static const Color primaryDark = Color(0xFF013638);

  // Couleurs secondaires - Old Gold (Or)
  static const Color secondary = Color(0xFFD0C140);
  static const Color secondaryLight = Color(0xFFE0D160);
  static const Color secondaryDark = Color(0xFFB0A130);

  // Couleurs d'accentuation - Rouge Cramoisi
  static const Color accent = Color(0xFFA31621);
  static const Color accentLight = Color(0xFFC62828);

  // Couleurs de fond
  static const Color background = Color(0xFFFAF8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Couleurs de texte
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF5D4E37);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Couleurs d'état
  static const Color success = Color(0xFF025456);
  static const Color warning = Color(0xFFD0C140);
  static const Color error = Color(0xFFA31621);
  static const Color info = Color(0xFF1565C0);

  // Couleurs pour les rôles
  static const Color pasteurColor = Color(0xFF025456);
  static const Color patriarcheColor = Color(0xFFD0C140);
  static const Color responsableColor = Color(0xFFA31621);

  // Couleurs pour les statuts
  static const Color actif = Color(0xFF025456);
  static const Color inactif = Color(0xFF9E9E9E);

  // Couleurs de présence
  static const Color present = Color(0xFF025456);
  static const Color absent = Color(0xFFA31621);

  // Autres
  static const Color divider = Color(0xFFE8E0D5);
  static const Color shadow = Color(0x1A000000);
}
