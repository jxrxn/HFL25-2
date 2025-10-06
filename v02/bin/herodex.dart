import 'dart:io';
import 'dart:convert';

/// Hjältarna lagras här
List<Map<String, dynamic>> heroes = [];

void main() {
  loadHeroes(); // Läs in tidigare sparade hjältar om de finns

  bool running = true;

  while (running) {
    print("\n=== HeroDex 3000 ===");
    print("1. Lägg till hjälte");
    print("2. Visa hjältar");
    print("3. Sök hjälte");
    print("4. Avsluta (och spara)");
    stdout.write("Välj: ");

    final choice = stdin.readLineSync()?.trim();

    switch (choice) {
      case '1':
        addHero();
        break;
      case '2':
        showHeroes();
        break;
      case '3':
        searchHeroes();
        break;
      case '4':
        saveHeroes();
        print("💾 Avslutar HeroDex 3000...");
        running = false;
        break;
      default:
        print("⚠️ Ogiltigt val, försök igen.");
    }
  }
}

/// Hjälpfunktion: fråga med möjlighet till default (utan att skriva ut den)
String askString(String prompt, {required String defaultValue}) {
  stdout.write("$prompt: ");
  final v = stdin.readLineSync()?.trim();
  if (v == null || v.isEmpty) return defaultValue;
  return v;
}

/// Hjälpfunktion: fråga efter styrka med gräns 1–1000
int askStrength() {
  while (true) {
    stdout.write("Ange styrka (1–1000): ");
    final input = stdin.readLineSync()?.trim();
    final value = int.tryParse(input ?? '');
    if (value != null && value >= 1 && value <= 1000) return value;
    print("⚠️ Ogiltig styrka. Ange ett heltal mellan 1 och 1000.");
  }
}

/// Lägg till en hjälte
void addHero() {
  final name = askString("Ange namn", defaultValue: "Okänd");
  final strength = askStrength();
  final special = askString("Ange specialkraft", defaultValue: "ingen");
  final gender = askString("Ange kön", defaultValue: "Unknown");
  final race   = askString("Ange ursprung", defaultValue: "Unknown");
  final align  = askString("Ange alignment (t.ex. snäll/neutral/ond)", defaultValue: "neutral");

  final hero = {
    "name": name,
    "powerstats": {"strength": strength},
    "appearance": {"gender": gender, "race": race},
    "biography": {"alignment": align},
    "special": special,
  };

  heroes.add(hero);
  print("${hero["name"]} tillagd!");
}

/// Visa alla hjältar sorterade efter styrka
void showHeroes() {
  if (heroes.isEmpty) {
    print("Inga hjältar tillagda ännu.");
    return;
  }

  final sorted = [...heroes];
  sorted.sort((a, b) =>
      (b["powerstats"]["strength"] as int).compareTo(a["powerstats"]["strength"] as int));

  print("\n=== Hjältar ===");
  for (final h in sorted) {
    final n = h["name"];
    final s = h["powerstats"]["strength"];
    final p = h["special"];
    final g = h["appearance"]["gender"];
    final r = h["appearance"]["race"];
    final a = h["biography"]["alignment"];
    print("- $n | styrka: $s | special: $p | gender: $g | race: $r | alignment: $a");
  }
}

/// Sök efter hjälte
void searchHeroes() {
  if (heroes.isEmpty) {
    print("Inga hjältar att söka i.");
    return;
  }

  stdout.write("Ange sökterm (namn): ");
  final query = stdin.readLineSync()?.trim().toLowerCase() ?? '';
  if (query.isEmpty) {
    print("Tom sökterm.");
    return;
  }

  final results = heroes.where(
    (h) => (h["name"] as String).toLowerCase().contains(query),
  );

  if (results.isEmpty) {
    print("Inga matchande hjältar hittades.");
  } else {
    print("\n=== Sökresultat ===");
    for (final h in results) {
      final n = h["name"];
      final s = h["powerstats"]["strength"];
      final p = h["special"];
      final g = h["appearance"]["gender"];
      final r = h["appearance"]["race"];
      final a = h["biography"]["alignment"];
      print("- $n | styrka: $s | special: $p | gender: $g | race: $r | alignment: $a");
    }
  }
}

/// Spara hjältar till fil (JSON)
void saveHeroes() {
  final file = File('heroes.json');
  final jsonData = jsonEncode(heroes);
  file.writeAsStringSync(jsonData);
  print("💾 Hjältar sparade till heroes.json");
}

/// Läs in hjältar från fil (JSON)
void loadHeroes() {
  final file = File('heroes.json');
  if (file.existsSync()) {
    final contents = file.readAsStringSync();
    final List<dynamic> data = jsonDecode(contents);
    heroes = List<Map<String, dynamic>>.from(data);
    print("📂 ${heroes.length} hjältar laddades in från heroes.json");
  }
}