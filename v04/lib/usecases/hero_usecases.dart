// lib/usecases/hero_usecases.dart
import 'package:v04/managers/hero_data_manager.dart';
import 'package:v04/models/models.dart';

/// Filtreringsalternativ för listning.
enum AlignmentFilter { all, heroes, villains, neutral }

/// Sorteringsalternativ för listning.
enum SortOrder { strength, nameAZ, nameZA }

class HeroUseCases {
  final HeroDataManager manager;
  HeroUseCases(this.manager);

  /// Lägg till hjälte (skyddar mot dubbletter via manager.saveUnique).
  Future<bool> addHero(HeroModel hero) async {
    return manager.saveUnique(hero);
  }

  /// Hjälp för existenskoll (namn eller id).
  Future<bool> existsByNameOrId(String name, String id) async {
    final list = await manager.getHeroList();
    final norm = name.trim().toLowerCase();
    return list.any((h) => h.id == id || h.name.trim().toLowerCase() == norm);
  }

  /// Lista hjältar med filter + sorteringsordning.
  Future<List<HeroModel>> listHeroes({
    AlignmentFilter filter = AlignmentFilter.all,
    SortOrder sortOrder = SortOrder.strength,
  }) async {
    final heroes = await manager.getHeroList();

    // 1) Filtrera
    Iterable<HeroModel> filtered = heroes;
    switch (filter) {
      case AlignmentFilter.heroes:
        filtered = heroes.where((h) => h.alignmentNormalized == 'good');
        break;
      case AlignmentFilter.villains:
        filtered = heroes.where((h) => h.alignmentNormalized == 'bad');
        break;
      case AlignmentFilter.neutral:
        filtered = heroes.where((h) => h.alignmentNormalized == 'neutral');
        break;
      case AlignmentFilter.all:
        // ofiltrerat
        break;
    }

    // 2) Sortera
    final sorted = [...filtered];
    switch (sortOrder) {
      case SortOrder.nameAZ:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOrder.nameZA:
        sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortOrder.strength:
        sorted.sort((a, b) => (b.powerstats?.strength ?? 0).compareTo(a.powerstats?.strength ?? 0));
        break;
    }
    return sorted;
  }

  /// Radera via id (enkel vidaredelegering till manager).
  Future<bool> deleteHeroById(String id) => manager.deleteHeroById(id);
}