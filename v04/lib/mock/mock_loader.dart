// lib/mock/mock_loader.dart
import 'dart:convert';
import 'dart:io';
import 'package:v04/managers/hero_data_manager.dart';
import 'package:v04/models/hero_model.dart';

/// Läser in mock-hjältar från test/mock_heroes.json och sparar dem via HeroDataManager.
Future<void> loadMockHeroesFromFile(HeroDataManager manager) async {
  const path = 'test/mock_heroes.json';
  final file = File(path);

  if (!await file.exists()) {
    print("⚠️  Mockfil saknas: $path");
    return;
  }

  final contents = await file.readAsString();
  final data = jsonDecode(contents);

  if (data is! List) {
    print("⚠️  Fel format i $path — förväntar en lista med hjältar.");
    return;
  }

  await manager.clearAll();

  for (final heroMap in data) {
    try {
      final hero = HeroModel.fromJson(heroMap);
      await manager.saveUnique(hero);
    } catch (e) {
      print("⚠️  Kunde inte läsa in en hjälte: $e");
    }
  }

  print("🧪 ${data.length} mockhjältar inlästa från $path");
}