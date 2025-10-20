import 'dart:io';

/// Enkel hantering av miljövariabler från .env-fil (utan externa paket).
/// Läser in filen rad för rad och lagrar nyckel/värde-par.
/// Prioritet: 1) Miljövariabler (t.ex. GitHub Actions) → 2) .env-fil lokalt.
class Env {
  static final Map<String, String> _vars = {};

  /// Ladda `.env`-filen från projektroten (eller angiven path).
  static void load([String path = '.env']) {
    final file = File(path);
    if (!file.existsSync()) {
      // Ignorera tyst i CI (där miljövariabler används)
      if (Platform.environment.containsKey('GITHUB_ACTIONS')) return;
      print('⚠️  Ingen .env-fil hittades ($path) — fortsätter utan lokala miljövariabler.');
      return;
    }

    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final index = trimmed.indexOf('=');
      if (index != -1) {
        final key = trimmed.substring(0, index).trim();
        final value = trimmed.substring(index + 1).trim();
        _vars[key] = value;
      }
    }
  }

  /// Hämtar en miljövariabel (först från OS, sedan .env)
  static String? get(String key) {
    final fromEnv = Platform.environment[key];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    return _vars[key];
  }

  /// Bekvämt alias för SuperHero API-token.
  /// (Söker efter SUPERHERO_API_TOKEN både i OS och .env)
  static String? get superheroToken => get('SUPERHERO_API_TOKEN');
}