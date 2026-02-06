import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'data/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise les locales pour les dates en français
  await initializeDateFormatting('fr_FR', null);

  // Configure l'orientation (portrait seulement)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialise Supabase
  await SupabaseService.initialize(
    url: 'https://yugurpwbgmzbrwwizibh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1Z3VycHdiZ216YnJ3d2l6aWJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNTU2NjQsImV4cCI6MjA4NTczMTY2NH0.i3nnR8EFibJb5UZS5i90u-57mA4PZXglxqdfPCayOLM',
  );

  runApp(
    const ProviderScope(
      child: GestionEgliseApp(),
    ),
  );
}
