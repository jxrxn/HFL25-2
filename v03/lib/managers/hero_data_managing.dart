import 'package:v03/models/hero_model.dart';

/// Abstrakt kontrakt för alla datamanagers
abstract class HeroDataManaging {
  /// Spara en hjälte (ny eller uppdaterad)
  Future<void> saveHero(HeroModel hero);

  /// Hämta hela listan med hjältar
  Future<List<HeroModel>> getHeroList();

  /// Sök hjälte via namn (delsträng, case-insensitiv)
  Future<List<HeroModel>> searchHero(String query);

  /// Ta bort hjälte via id. Returnerar true om något togs bort.
  Future<bool> deleteHeroById(String id);
}
