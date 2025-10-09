import 'dart:io';
import 'dart:convert';

/// ====== Färger (ANSI) ======
const String red = '\x1B[31m';
const String green = '\x1B[32m';
const String yellow = '\x1B[33m';
const String cyan = '\x1B[36m';
const String reset = '\x1B[0m';

void printError(String msg) => print("$red$msg$reset");
void printSuccess(String msg) => print("$green$msg$reset");
void printInfo(String msg) => print("$cyan$msg$reset");
void printWarn(String msg) => print("$yellow$msg$reset");

/// ====== Data ======
List<Map<String, dynamic>> heroes = [];
const saveFile = 'heroes.json';

void main() {
  loadHeroes(); // Läs in tidigare sparade hjältar

  bool running = true;
  while (running) {
    printInfo("\n=== HeroDex 3000 ===");
    print("1. Lägg till hjälte");
    print("2. Visa hjältar");
    print("3. Sök hjälte");
    print("4. Ta bort hjälte");
    print("5. Avsluta (och spara)");
    stdout.write("Välj: ");

    final choice = stdin.readLineSync()?.trim();

    switch (choice) {
      case '1':
        addHero();
        saveHeroes();
        break;
      case '2':
        showHeroes();
        break;
      case '3':
        searchHeroes();
        break;
      case '4':
        deleteHero();
        break;
      case '5':
        saveHeroes();
        printSuccess("💾 Avslutar HeroDex 3000...");
        running = false;
        break;
      default:
        printError("⚠️  Ogiltigt val, försök igen.");
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
    printError("⚠️  Ogiltig styrka. Ange ett heltal mellan 1 och 1000.");
  }
}

/// Lägg till en hjälte
void addHero() {
  final name = askString("Ange namn", defaultValue: "Okänd");
  final strength = askStrength();
  final special = askString("Ange specialkraft", defaultValue: "ingen");
  final gender = askString("Ange kön", defaultValue: "Unknown");
  final origin = askString("Ange ursprung", defaultValue: "Unknown");
  final align  = askString("Ange alignment (t.ex. snäll/neutral/ond)", defaultValue: "neutral");

  final hero = {
    "name": name,
    "powerstats": {"strength": strength},
    "appearance": {"gender": gender, "race": origin},
    "biography": {"alignment": align},
    "special": special,
  };

  heroes.add(hero);
  printSuccess("✅ ${hero["name"]} tillagd!");
}

/// Visa alla hjältar sorterade efter styrka
void showHeroes() {
  if (heroes.isEmpty) {
    printWarn("Inga hjältar tillagda ännu.");
    return;
  }

  final sorted = [...heroes];
  sorted.sort((a, b) =>
      (b["powerstats"]["strength"] as int).compareTo(a["powerstats"]["strength"] as int));

  printInfo("\n=== Hjältar (starkast först) ===");
  for (final h in sorted) {
    final n = h["name"];
    final s = h["powerstats"]["strength"];
    final p = h["special"];
    final g = h["appearance"]["gender"];
    final r = h["appearance"]["race"];
    final a = h["biography"]["alignment"];
    print("- $n | styrka: $s | special: $p | kön: $g | ursprung: $r | alignment: $a");
  }
}

/// Sök efter hjälte
void searchHeroes() {
  if (heroes.isEmpty) {
    printWarn("Inga hjältar att söka i.");
    return;
  }

  stdout.write("Ange sökterm (namn): ");
  final query = stdin.readLineSync()?.trim().toLowerCase() ?? '';
  if (query.isEmpty) {
    printWarn("Tom sökterm.");
    return;
  }

  final results = heroes.where(
    (h) => (h["name"] as String).toLowerCase().contains(query),
  );

  if (results.isEmpty) {
    printError("❌ Inga matchande hjältar hittades.");
  } else {
    printInfo("\n=== Sökresultat ===");
    for (final h in results) {
      final n = h["name"];
      final s = h["powerstats"]["strength"];
      final p = h["special"];
      final g = h["appearance"]["gender"];
      final r = h["appearance"]["race"];
      final a = h["biography"]["alignment"];
      print("- $n | styrka: $s | special: $p | kön: $g | ursprung: $r | alignment: $a");
    }
  }
}

/// Ta bort hjälte (via nummer i sorterad lista eller exakt namn)
void deleteHero() {
  if (heroes.isEmpty) {
    printWarn("Det finns inga hjältar att ta bort.");
    return;
  }

  // Visa numrerad lista (starkast först)
  final sorted = [...heroes];
  sorted.sort((a, b) =>
      (b["powerstats"]["strength"] as int).compareTo(a["powerstats"]["strength"] as int));

  printInfo("\n=== Ta bort hjälte ===");
  for (var i = 0; i < sorted.length; i++) {
    final h = sorted[i];
    final n = h["name"];
    final s = h["powerstats"]["strength"];
    print("${i + 1}. $n (styrka: $s)");
  }

  stdout.write("Ange nummer att ta bort (eller skriv exakt namn, tomt för avbryt): ");
  final input = stdin.readLineSync()?.trim() ?? '';

  if (input.isEmpty) {
    printWarn("Avbrutet.");
    return;
  }

  Map<String, dynamic>? toRemove;

  // Försök tolka som index
  final idx = int.tryParse(input);
  if (idx != null && idx >= 1 && idx <= sorted.length) {
    toRemove = sorted[idx - 1];
  } else {
    // Matcha på exakt namn (case-insensitivt)
    final lower = input.toLowerCase();
    toRemove = sorted.firstWhere(
      (h) => (h["name"] as String).toLowerCase() == lower,
      orElse: () => {},
    );
    if (toRemove.isEmpty) {
      printError("❌ Hittade ingen hjälte med det numret/namnet.");
      return;
    }
  }

  final name = toRemove["name"] as String;
  stdout.write("Är du säker på att du vill ta bort '$name'? (j/N): ");
  final confirm = stdin.readLineSync()?.trim().toLowerCase();
  if (confirm != 'j' && confirm != 'ja' && confirm != 'y' && confirm != 'yes') {
    printWarn("Avbrutet.");
    return;
  }

  final removed = heroes.remove(toRemove);
  if (removed) {
    saveHeroes();
    printSuccess("🗑️  '$name' borttagen.");
  } else {
    printError("❌ Kunde inte ta bort '$name'. (Okänt fel.)");
  }
}

/// Spara hjältar till fil (JSON)
void saveHeroes() {
  final file = File(saveFile);
  final jsonData = jsonEncode(heroes);
  file.writeAsStringSync(jsonData, mode: FileMode.write);
}

/// Läs in hjältar från fil (JSON)
void loadHeroes() {
  final file = File(saveFile);
  if (file.existsSync()) {
    final contents = file.readAsStringSync();
    final List<dynamic> data = jsonDecode(contents);
    heroes = List<Map<String, dynamic>>.from(data);
  }
}