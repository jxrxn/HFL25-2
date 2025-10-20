/// Abstrakt kontrakt för alla API-klienter.
abstract class ApiManager {
  /// I en ”riktig” klient görs ett nätverksanrop här.
  Future<String> fetchHeroName();
}
