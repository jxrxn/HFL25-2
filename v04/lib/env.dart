import 'dart:io';

/// Enkel hantering av miljövariabler från .env-fil (utan paket).
/// Läser in filen rad för rad och lagrar nyckel/värde-par.
class Env {
  static final Map<String, String> _vars = {};

  /// Ladda `.env`-filen från projektroten (eller angiven path).
  static void load([String path = '.env']) {
    final file = File(path);
    if (!file.existsSync()) {
      print('⚠️  Ingen .env-fil hittades ($path) — fortsätter utan miljövariabler.');
      return;
    }

    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final split = trimmed.split('=');
      if (split.length >= 2) {
        final key = split.first.trim();
        final value = split.sublist(1).join('=').trim();
        _vars[key] = value;
      }
    }
  }

  /// Hämta en variabel (eller null om saknas).
  static String? get(String key) => _vars[key];

  /// Bekvämt alias för API-nyckeln.
  static String? get superheroToken => get('SUPERHERO_TOKEN');
}