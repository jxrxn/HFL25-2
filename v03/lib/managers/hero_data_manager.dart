import 'dart:convert';
import 'dart:io';

import 'package:v03/models/hero_model.dart';
import 'package:v03/managers/hero_data_managing.dart';

class HeroDataManager implements HeroDataManaging {
  // ---- Singleton-standardinstans (produktion) ----
  static final HeroDataManager _instance = HeroDataManager._internal();

  /// Fabrik som returnerar singleton i appen
  factory HeroDataManager() => _instance;

  /// Test-hook: (valfritt) tillåt att skapa en separat *icke-singleton* instans med egen fil.
  /// Används bara i tester: HeroDataManager._internalForTesting('/tmp/foo.json')
  HeroDataManager.internalForTesting(this._saveFile) {
    _loadFromDisk();
  }

  /// Privat produktionskonstruktor – använder defaultfilen.
  HeroDataManager._internal() : _saveFile = 'heroes.json' {
    _loadFromDisk();
  }

  // ---- Tillstånd ----
  final String _saveFile; // final, men initieras i konstruktorn
  final List<HeroModel> _heroes = [];

  // ---- Offentliga API (krav från HeroDataManaging) ----

  @override
  Future<void> saveHero(HeroModel hero) async {
    final idx = _heroes.indexWhere((h) => h.id == hero.id);
    if (idx >= 0) {
      _heroes[idx] = hero;
    } else {
      _heroes.add(hero);
    }
    await _saveToDisk();
  }

  @override
  Future<List<HeroModel>> getHeroList() async {
    // Returnera en kopia så att listan inte kan muteras externt
    return List<HeroModel>.unmodifiable(_heroes);
  }

  @override
  Future<List<HeroModel>> searchHero(String query) async {
    final q = query.toLowerCase();
    return _heroes
        .where((h) => h.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Future<bool> deleteHeroById(String id) async {
    final idx = _heroes.indexWhere((h) => h.id == id);
    if (idx == -1) return false;
    _heroes.removeAt(idx);
    await _saveToDisk();
    return true;
  }

  // ---- Hjälpmetoder (privata) ----

  Future<void> _saveToDisk() async {
    final file = File(_saveFile);
    final data = _heroes.map((h) => h.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }

  Future<void> _loadFromDisk() async {
    final file = File(_saveFile);
    if (!file.existsSync()) return;
    final contents = await file.readAsString();
    final List<dynamic> data = jsonDecode(contents);
    _heroes
      ..clear()
      ..addAll(data.map((m) => HeroModel.fromJson(m as Map<String, dynamic>)));
  }
}
