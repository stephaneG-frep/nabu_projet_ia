import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:nabu_projet_ia/core/services/database_service.dart';
import 'package:nabu_projet_ia/core/providers/providers.dart';
import 'package:nabu_projet_ia/screens/app_shell.dart';

void main() {
  late Directory tempDir;
  final db = DatabaseService();

  // Real file I/O must run outside testWidgets' fake-async zone,
  // otherwise opening the Hive boxes never completes.
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
    tempDir = await Directory.systemTemp.createTemp('nabu_test_');
    await db.init(path: tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('NabuProjet IA app builds and shows navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pump();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Let delayed entrance animations (flutter_animate) finish so no timer
    // is left pending when the test ends.
    await tester.pump(const Duration(seconds: 5));
  });

  test('computeProjectProgress returns 0 on empty tasks', () {
    expect(computeProjectProgress([]), 0.0);
  });
}
