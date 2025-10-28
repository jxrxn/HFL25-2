// lib/managers/hero_data_manager.dart
import 'dart:convert';
import 'dart:io';

import 'package:v04/managers/hero_data_managing.dart';
import 'package:v04/models/hero_model.dart';

class HeroDataManager implements HeroDataManaging {
  // ==== Singleton (produktion) ====
  static final HeroDataManager _instance = HeroDataManager._internal();
  factory HeroDataManager() => _instance;

  HeroDataManager._internal() {
    _saveFile = 'heroes.json';
    _loaded = false;
  }

  // För tester: separat instans (ej singleton) med egen fil
  HeroDataManager.internalForTesting(String customPath) {
    _saveFile = customPath;
    _loaded = false;
  }

  // ==== Tillstånd ====
  late final String _saveFile;
  final List<HeroModel> _heroes = [];
  bool _loaded = false;

  // ==== Utilities ====
  static String _normalizeName(String s) => s.trim().toLowerCase();

  // ================= PUBLIC API =================

  /// Bakåtkompatibel signatur – använder tyst dubblettskydd.
  @override
  Future<void> saveHero(HeroModel hero) async {
    await saveUnique(hero);
  }

  /// Sparar endast om ingen dubblett (match på id **eller** normaliserat namn).
  Future<bool> saveUnique(HeroModel hero) async {
    await _ensureLoaded();
    if (!_isSane(hero)) return false; // spara inte trasig post

    final norm = _normalizeName(hero.name);
    final exists = _heroes.any((h) => h.id == hero.id || _normalizeName(h.name) == norm);
    if (exists) return false;

    _heroes.add(hero);
    await _saveToDisk();
    return true;
  }

  /// Finns hjälte med exakt namn (case-insensitivt)?
  Future<bool> existsByName(String name) async {
    await _ensureLoaded();
    final norm = _normalizeName(name);
    return _heroes.any((h) => _normalizeName(h.name) == norm);
  }

  @override
  Future<List<HeroModel>> getHeroList() async {
    await _ensureLoaded();
    return List<HeroModel>.unmodifiable(_heroes);
  }

  @override
  Future<List<HeroModel>> searchHero(String query) async {
    final list = await getHeroList();
    final q = _normalizeName(query);
    return list.where((h) => _normalizeName(h.name).contains(q)).toList(growable: false);
  }

  @override
  Future<bool> deleteHeroById(String id) async {
    await _ensureLoaded();
    final idx = _heroes.indexWhere((h) => h.id == id);
    if (idx == -1) return false;
    _heroes.removeAt(idx);
    await _saveToDisk();
    return true;
  }

  Future<bool> deleteHeroByName(String name) async {
    await _ensureLoaded();
    final norm = _normalizeName(name);
    final idx = _heroes.indexWhere((h) => _normalizeName(h.name) == norm);
    if (idx == -1) return false;
    _heroes.removeAt(idx);
    await _saveToDisk();
    return true;
  }

  // ================= PRIVATE =================

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    await _loadFromDisk();
    _loaded = true;
  }

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

      final decoded = jsonDecode(contents);
      if (decoded is! List) {
        _heroes.clear(); // oväntat format
        return;
      }

      final List<HeroModel> parsed = [];
      final seenIds = <String>{};
      final seenNames = <String>{};

      for (final e in decoded) {
        if (e is! Map<String, dynamic>) continue;

        HeroModel? h;
        // Försök primärt med typad parsing
        try {
          h = HeroModel.fromJson(e);
        } catch (_) {
          // Fallback (identisk idag men behålls för framtiden)
          try {
            h = HeroModel.fromLooseJson(e);
          } catch (_) {
            h = null;
          }
        }
        if (h == null) continue;

        // === SANITY: hoppa över trasiga ===
        if (!_isSane(h)) continue;

        final id = h.id.trim();
        final nameNorm = _normalizeName(h.name);
        if (id.isEmpty || nameNorm.isEmpty) continue;

        // Deduplikat: id ELLER namn
        if (seenIds.contains(id) || seenNames.contains(nameNorm)) continue;

        seenIds.add(id);
        seenNames.add(nameNorm);
        parsed.add(h);
      }

      _heroes
        ..clear()
        ..addAll(parsed);
    } catch (_) {
      // korrupt/sönder → börja med tom lista
      _heroes.clear();
    }
  }

  /// Enkel rimlighetskoll – styr hur "strikt" du vill vara i testerna.
  bool _isSane(HeroModel h) {
    if (h.id.trim().isEmpty) return false;
    if (h.name.trim().isEmpty) return false;

    // Godta att powerstats kan vara null i äldre sparfiler,
    // men om den finns, låt åtminstone strength vara inom rimliga gränser.
    final s = h.powerstats?.strength;
    if (s != null && (s < 0 || s > 10000)) {
      return false;
    }
    return true;
  }

  Future<void> _saveToDisk() async {
    final file = File(_saveFile);
    final data = _heroes.map((h) => h.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }
}