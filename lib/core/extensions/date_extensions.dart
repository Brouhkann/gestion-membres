import 'package:intl/intl.dart';

extension DateExtensions on DateTime {
  /// Formate la date en "dd/MM/yyyy"
  String toDateString() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  /// Formate la date en "dd MMMM yyyy" (ex: 15 janvier 2024)
  String toFullDateString() {
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(this);
  }

  /// Formate la date en "dd MMM" (ex: 15 jan.)
  String toShortDateString() {
    return DateFormat('dd MMM', 'fr_FR').format(this);
  }

  /// Formate seulement jour et mois "dd/MM"
  String toDayMonthString() {
    return DateFormat('dd/MM').format(this);
  }

  /// Formate le jour et mois en texte (ex: "15 janvier")
  String toDayMonthFullString() {
    return DateFormat('dd MMMM', 'fr_FR').format(this);
  }

  /// Vérifie si c'est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Vérifie si c'est cette semaine
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Vérifie si c'est ce mois
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Vérifie si l'anniversaire est aujourd'hui (compare jour et mois)
  bool isBirthdayToday() {
    final now = DateTime.now();
    return day == now.day && month == now.month;
  }

  /// Vérifie si l'anniversaire est cette semaine
  bool isBirthdayThisWeek() {
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final checkDate = now.add(Duration(days: i));
      if (day == checkDate.day && month == checkDate.month) {
        return true;
      }
    }
    return false;
  }

  /// Vérifie si l'anniversaire est ce mois
  bool isBirthdayThisMonth() {
    final now = DateTime.now();
    return month == now.month;
  }

  /// Calcule l'âge
  int calculateAge() {
    final now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return age;
  }

  /// Retourne le prochain anniversaire
  DateTime get nextBirthday {
    final now = DateTime.now();
    var nextBday = DateTime(now.year, month, day);
    if (nextBday.isBefore(now) || nextBday.isAtSameMomentAs(now)) {
      nextBday = DateTime(now.year + 1, month, day);
    }
    return nextBday;
  }

  /// Nombre de jours jusqu'au prochain anniversaire
  int daysUntilNextBirthday() {
    return nextBirthday.difference(DateTime.now()).inDays;
  }
}

extension DateTimeNullableExtensions on DateTime? {
  /// Formate la date ou retourne une chaîne vide
  String toDateStringOrEmpty() {
    return this?.toDateString() ?? '';
  }

  /// Formate seulement jour et mois ou retourne une chaîne vide
  String toDayMonthStringOrEmpty() {
    return this?.toDayMonthString() ?? '';
  }
}
