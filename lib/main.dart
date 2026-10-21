import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'core/providers/providers.dart';
import 'core/services/database_service.dart';
import 'core/services/key_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Required before any DateFormat(..., 'fr_FR'); also makes dates without
  // an explicit locale (e.g. month names in the journal) display in French.
  await initializeDateFormatting('fr_FR');
  Intl.defaultLocale = 'fr_FR';

  final db = DatabaseService();
  await db.init();

  // Move keys saved in plain text by older versions into secure storage.
  final keyStorage = KeyStorageService();
  final legacyKeys = db.getLegacyAIKeys();
  if (legacyKeys != null) {
    await keyStorage.save(legacyKeys);
    await db.deleteLegacyAIKeys();
  }
  final keys = await keyStorage.load();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        keyStorageProvider.overrideWithValue(keyStorage),
        aiKeysProvider.overrideWith((ref) => keys),
      ],
      child: const NabuProjetApp(),
    ),
  );
}

class NabuProjetApp extends ConsumerStatefulWidget {
  const NabuProjetApp({super.key});

  @override
  ConsumerState<NabuProjetApp> createState() => _NabuProjetAppState();
}

class _NabuProjetAppState extends ConsumerState<NabuProjetApp> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: 'NabuProjet IA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AppShell(),
    );
  }
}