import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class Helpers {
  Helpers._();

  /// Génère une couleur à partir d'une chaîne
  static Color getColorFromString(String text) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.pasteurColor,
      AppColors.patriarcheColor,
      AppColors.responsableColor,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }

  /// Formate un nombre avec séparateur de milliers
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  /// Calcule le pourcentage
  static double calculatePercentage(int value, int total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  /// Formate le pourcentage
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Retourne le texte du sexe
  static String getSexeText(String sexe) {
    switch (sexe.toLowerCase()) {
      case 'm':
      case 'homme':
      case 'masculin':
        return 'Homme';
      case 'f':
      case 'femme':
      case 'feminin':
        return 'Femme';
      default:
        return sexe;
    }
  }

  /// Retourne l'icône du sexe
  static IconData getSexeIcon(String sexe) {
    switch (sexe.toLowerCase()) {
      case 'm':
      case 'homme':
      case 'masculin':
        return Icons.male;
      case 'f':
      case 'femme':
      case 'feminin':
        return Icons.female;
      default:
        return Icons.person;
    }
  }

  /// Génère un message de salutation selon l'heure
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bonjour';
    } else if (hour < 18) {
      return 'Bon après-midi';
    } else {
      return 'Bonsoir';
    }
  }

  /// Retourne le texte pour la durée depuis une date
  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  /// Génère un ID unique simple
  static String generateSimpleId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
