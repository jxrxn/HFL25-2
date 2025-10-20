// lib/managers/hero_data_manager.dart
import 'dart:convert';
import 'dart:io';

import 'package:v04/managers/hero_data_managing.dart';
import 'package:v04/models/hero_model.dart';

/// Central lagringsenhet för hjältar.
/// - Produktion:  `HeroDataManager()` ger en singleton som skriver till `heroes.json`.
/// - Tester:      `HeroDataManager.internalForTesting('/tmp/foo.json')` ger en separat instans.
class HeroDataManager implements HeroDataManaging {
  // ==== Singleton (produktion) ====
  static final HeroDataManager _instance = HeroDataManager._internal();

  /// Fabrik som alltid returnerar samma instans (singleton).
  factory HeroDataManager() => _instance;

  /// Privat produktions-konstruktor – använder defaultfilen.
  HeroDataManager._internal() {
    _saveFile = 'heroes.json';
    _loaded = false; // lazyladdas första gången
  }

  /// Test-konstruktor: skapar en separat, icke-singleton instans med egen fil.
  HeroDataManager.internalForTesting(String customPath) {
    _saveFile = customPath;
    _loaded = false; // säkerställ lazy load med nya filen
  }

  // ==== Tillstånd ====
  late final String _saveFile;        // sätts i konstruktor
  final List<HeroModel> _heroes = []; // cache i minnet
  bool _loaded = false;               // har vi laddat från disk?

  // ==== Utilities ====
  static String _normName(String s) => s.trim().toLowerCase();

  // ==== Offentligt API ====

  /// Spara en hjälte om inte dubblett (match på id **eller** namn, case-insensitive).
  @override
  Future<void> saveHero(HeroModel hero) async {
    await _ensureLoaded();

    final norm = _normName(hero.name);
    final exists = _heroes.any((h) => h.id == hero.id || _normName(h.name) == norm);
    if (exists) {
      // Vill du få feedback i CLI:t kan du avkommentera raden nedan:
      // print("⚠️  Dubblett hoppad över: ${hero.name} (id: ${hero.id})");
      return;
    }

    _heroes.add(hero);
    await _saveToDisk();
  }

  /// Hämta hela listan (lazy-loadar första gången).
  @override
  Future<List<HeroModel>> getHeroList() async {
    await _ensureLoaded();
    return List<HeroModel>.unmodifiable(_heroes);
  }

  /// Sök på delsträng i namn (case-insensitivt).
  @override
  Future<List<HeroModel>> searchHero(String query) async {
    final list = await getHeroList();
    final q = _normName(query);
    return list.where((h) => _normName(h.name).contains(q)).toList(growable: false);
  }

  /// Ta bort hjälte via id. Returnerar true om någon togs bort.
  @override
  Future<bool> deleteHeroById(String id) async {
    await _ensureLoaded();
    final idx = _heroes.indexWhere((h) => h.id == id);
    if (idx == -1) return false;
    _heroes.removeAt(idx);
    await _saveToDisk();
    return true;
  }

  // ==== Privata hjälpmetoder ====

  /// Säkerställ att minnescachen är laddad.
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    await _loadFromDisk();
    _loaded = true;
  }

  /// Ladda från JSON på disk. Robust mot saknad/trasig fil.
  Future<void> _loadFromDisk() async {
    try {
      final file = File(_saveFile);
      if (!file.existsSync()) {
        _heroes.clear();
        return;
      }
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) {
        _heroes.clear();
        return;
      }
      final List<dynamic> data = jsonDecode(contents);
      _heroes
        ..clear()
        ..addAll(
          data.map((m) => HeroModel.fromJson(m as Map<String, dynamic>)),
        );
    } catch (_) {
      // Om något går fel – börja om från tom lista istället för att krascha.
      _heroes.clear();
    }
  }

  /// Spara till JSON på disk.
  Future<void> _saveToDisk() async {
    final file = File(_saveFile);
    final data = _heroes.map((h) => h.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }
}