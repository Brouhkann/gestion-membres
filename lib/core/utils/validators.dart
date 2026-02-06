import '../constants/app_strings.dart';

class Validators {
  Validators._();

  /// Valide un champ obligatoire
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName est obligatoire'
          : AppStrings.champObligatoire;
    }
    return null;
  }

  /// Valide un numéro de téléphone (format flexible)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.champObligatoire;
    }

    // Nettoie le numéro (espaces, tirets, parenthèses)
    String cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Retire les préfixes internationaux courants
    if (cleaned.startsWith('+225')) {
      cleaned = cleaned.substring(4); // Côte d'Ivoire
    } else if (cleaned.startsWith('225')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('+237')) {
      cleaned = cleaned.substring(4); // Cameroun
    } else if (cleaned.startsWith('237')) {
      cleaned = cleaned.substring(3);
    }

    // Retire le 0 initial si présent
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    // Vérifie que c'est un numéro valide (9 chiffres minimum après nettoyage)
    if (cleaned.length < 9 || cleaned.length > 10) {
      return AppStrings.telephoneInvalide;
    }

    // Vérifie que ce sont bien des chiffres
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return AppStrings.telephoneInvalide;
    }

    return null;
  }

  /// Valide un mot de passe
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return AppStrings.champObligatoire;
    }
    if (value.length < minLength) {
      return 'Minimum $minLength caractères';
    }
    return null;
  }

  /// Valide un email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.champObligatoire;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }

    return null;
  }

  /// Valide un nom (lettres, espaces, tirets, apostrophes)
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.champObligatoire;
    }

    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$");
    if (!nameRegex.hasMatch(value)) {
      return 'Caractères invalides';
    }

    if (value.trim().length < 2) {
      return 'Minimum 2 caractères';
    }

    return null;
  }

  /// Valide une date de naissance
  static String? birthDate(DateTime? value) {
    if (value == null) {
      return AppStrings.champObligatoire;
    }

    final now = DateTime.now();
    if (value.isAfter(now)) {
      return 'La date ne peut pas être dans le futur';
    }

    // Vérifie que la personne a moins de 150 ans
    final minDate = DateTime(now.year - 150);
    if (value.isBefore(minDate)) {
      return 'Date invalide';
    }

    return null;
  }

  /// Valide une longueur minimale
  static String? minLength(String? value, int min) {
    if (value == null || value.isEmpty) {
      return AppStrings.champObligatoire;
    }
    if (value.length < min) {
      return 'Minimum $min caractères';
    }
    return null;
  }

  /// Valide une longueur maximale
  static String? maxLength(String? value, int max) {
    if (value != null && value.length > max) {
      return 'Maximum $max caractères';
    }
    return null;
  }

  /// Combine plusieurs validateurs
  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}
