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

  /// För tester: separat instans med egen fil (ej singleton)
  HeroDataManager.internalForTesting(String customPath) {
    _saveFile = customPath;
    _loaded = false;
  }

  // ==== Tillstånd ====
  // NOTE: inte final längre → kan växla mellan heroes.json och heroes_mock.json
  late String _saveFile;
  final List<HeroModel> _heroes = [];
  bool _loaded = false;

  // ==== Utilities ====
  static String _normalizeName(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  static bool _isInvalidName(String s) {
    final n = _normalizeName(s);
    return n.isEmpty || n == 'unknown' || n == 'null';
  }

  // ================= PUBLIC API =================

  /// Byt datafil (t.ex. vid mock-läge). Rensar cache och lazy-laddar nästa gång.
  void setDataFile(String path) {
    _saveFile = path;
    _loaded = false;     // tvinga omladdning från nya filen
    _heroes.clear();     // släpp tidigare cache
  }

  /// Töm all data och skriv tomt JSON-array till nuvarande fil.
  Future<void> clearAll() async {
    _heroes.clear();
    _loaded = true;      // cache är nu “laddad” men tom
    await _saveToDisk();
  }

  /// Bakåtkompatibelt: sparar via saveUnique (tyst dubblettskydd).
  @override
  Future<void> saveHero(HeroModel hero) async {
    await saveUnique(hero);
  }

  /// Spara endast om ingen dubblett (match på id **eller** namn, case-insensitive).
  /// Returnerar true om sparat, false om dubblett/ogiltigt.
  Future<bool> saveUnique(HeroModel hero) async {
    await _ensureLoaded();

    final id = (hero.id).toString().trim();
    final nameNorm = _normalizeName(hero.name);
    if (id.isEmpty || _isInvalidName(nameNorm)) return false;

    final exists = _heroes.any(
      (h) => h.id == id || _normalizeName(h.name) == nameNorm,
    );
    if (exists) return false;

    _heroes.add(hero);
    await _saveToDisk();
    return true;
  }

  /// Finns hjälte med exakt namn (case-insensitive)?
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
    return list
        .where((h) => _normalizeName(h.name).contains(q))
        .toList(growable: false);
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
        _heroes.clear(); // Oväntat format
        return;
      }

      final List<HeroModel> parsed = [];
      final seenIds = <String>{};
      final seenNames = <String>{};

      for (final e in decoded) {
        if (e is! Map<String, dynamic>) continue;

        HeroModel? h;
        try {
          h = HeroModel.fromJson(e);
        } catch (_) {
          try {
            h = HeroModel.fromLooseJson(e);
          } catch (_) {
            h = null;
          }
        }
        if (h == null) continue;

        final id = (h.id).toString().trim();
        final nameNorm = _normalizeName((h.name).toString());
        if (id.isEmpty || _isInvalidName(nameNorm)) continue;

        if (seenIds.contains(id) || seenNames.contains(nameNorm)) continue;

        seenIds.add(id);
        seenNames.add(nameNorm);
        parsed.add(h);
      }

      _heroes
        ..clear()
        ..addAll(parsed);
    } catch (_) {
      _heroes.clear(); // korrupt/sönder → börja om tomt
    }
  }

  Future<void> _saveToDisk() async {
    final file = File(_saveFile);
    final data = _heroes.map((h) => h.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }
}