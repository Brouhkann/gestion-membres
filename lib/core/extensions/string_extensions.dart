extension StringExtensions on String {
  /// Capitalise la première lettre
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Capitalise chaque mot
  String capitalizeEachWord() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Vérifie si c'est un numéro de téléphone valide
  bool isValidPhone() {
    // Pattern pour les numéros camerounais et internationaux
    final phoneRegex = RegExp(r'^(\+?237|0)?[6-9][0-9]{8}$');
    return phoneRegex.hasMatch(replaceAll(' ', '').replaceAll('-', ''));
  }

  /// Formate le numéro de téléphone
  String formatPhone() {
    String cleaned = replaceAll(' ', '').replaceAll('-', '');
    if (cleaned.startsWith('+237')) {
      cleaned = cleaned.substring(4);
    } else if (cleaned.startsWith('237')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    if (cleaned.length == 9) {
      return '+237 ${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }
    return this;
  }

  /// Vérifie si c'est un email valide
  bool isValidEmail() {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Retourne les initiales (max 2 caractères)
  String getInitials() {
    if (isEmpty) return '';
    final words = trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Tronque le texte avec "..."
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Vérifie si la chaîne contient uniquement des chiffres
  bool get isNumeric => RegExp(r'^[0-9]+$').hasMatch(this);

  /// Enlève les espaces en trop
  String removeExtraSpaces() {
    return trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

extension NullableStringExtensions on String? {
  /// Retourne true si null ou vide
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Retourne true si non null et non vide
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  /// Retourne la valeur ou une chaîne par défaut
  String orDefault([String defaultValue = '']) => this ?? defaultValue;
}
