import 'dart:io';

import 'package:v03/managers/hero_data_manager.dart';
import 'package:v03/managers/hero_data_managing.dart';
import 'package:v03/models/hero_model.dart';

/// Globalt (sätts i main baserat på argument)
late HeroDataManaging store;

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

/// ====== Start & argument ======
/// - `dart run bin/herodex.dart`                → skarpt läge (heroes.json)
/// - `dart run bin/herodex.dart --mock`         → mock-läge (test/mock_heroes.json)
/// - `dart run bin/herodex.dart --data=PATH`    → använd valfri fil
Future<void> main(List<String> args) async {
  final isMock = args.contains('--mock');
  final dataPathArg = args.firstWhere(
    (a) => a.startsWith('--data='),
    orElse: () => '',
  );

  final dataFile = dataPathArg.isNotEmpty
      ? dataPathArg.split('=').last
      : (isMock ? 'test/mock_heroes.json' : 'heroes.json');

  // Initiera store: om datafilen är specificerad/mock → test-konstruktorn,
  // annars singletonen (produktion).
  store = (isMock || dataPathArg.isNotEmpty)
      ? HeroDataManager.internalForTesting(dataFile)
      : HeroDataManager();

  printInfo("🗂  Använder datafil: $dataFile");

  // Ladda ev. befintliga hjältar
  await store.getHeroList();

  var running = true;
  while (running) {
    printInfo("\n=== HeroDex 3000 ===");
    print("1. Lägg till hjälte");
    print("2. Visa hjältar");
    print("3. Sök hjälte");
    print("4. Ta bort hjälte");
    print("5. Avsluta");
    stdout.write("Välj: ");

    final choice = stdin.readLineSync()?.trim();
    switch (choice) {
      case '1':
        await addHero();
        break;
      case '2':
        await showHeroes();
        break;
      case '3':
        await searchHeroes();
        break;
      case '4':
        await deleteHero();
        break;
      case '5':
        printSuccess("💾 Avslutar HeroDex 3000...");
        running = false;
        break;
      default:
        printError("⚠️  Ogiltigt val, försök igen.");
    }
  }
}

/// ====== Hjälpfunktioner (input) ======
String askString(String prompt, {required String defaultValue}) {
  stdout.write("$prompt: ");
  final v = stdin.readLineSync()?.trim();
  if (v == null || v.isEmpty) return defaultValue;
  return v;
}

int askStrength() {
  while (true) {
    stdout.write("Ange styrka (1–1000): ");
    final input = stdin.readLineSync()?.trim();
    final value = int.tryParse(input ?? '');
    if (value != null && value >= 1 && value <= 1000) return value;
    printError("⚠️  Ogiltig styrka. Ange ett heltal mellan 1 och 1000.");
  }
}

/// ====== Funktioner ======

Future<void> addHero() async {
  final name = askString("Ange hjältenamn (alias)", defaultValue: "Okänd");
  final realName = askString("Ange riktigt namn (valfritt)", defaultValue: "");
  final strength = askStrength();
  final special = askString("Ange specialkraft", defaultValue: "ingen");
  final gender = askString("Ange kön", defaultValue: "Okänt");
  final origin = askString("Ange ursprung/ras", defaultValue: "Okänt");
  final align = askString(
    "Ange alignment (t.ex. snäll/neutral/ond)",
    defaultValue: "neutral",
  );

  final hero = HeroModel(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    name: name,
    powerstats: {"strength": strength},
    appearance: {"gender": gender, "race": origin},
    biography: {
      "alignment": align,
      if (realName.isNotEmpty) "full-name": realName,
    },
    work: {"occupation": special},
  );

  await store.saveHero(hero);
  printSuccess("✅ ${hero.name} tillagd!");
}

Future<void> showHeroes() async {
  final heroes = await store.getHeroList();
  if (heroes.isEmpty) {
    printWarn("Inga hjältar tillagda ännu.");
    return;
  }

  final sorted = [...heroes]
    ..sort((a, b) {
      final as = int.tryParse('${a.powerstats?['strength'] ?? 0}') ?? 0;
      final bs = int.tryParse('${b.powerstats?['strength'] ?? 0}') ?? 0;
      return bs.compareTo(as);
    });

  printInfo("\n=== Hjältar (starkast först) ===");
  for (final h in sorted) {
    print(h.toString());
  }
}

Future<void> searchHeroes() async {
  final heroes = await store.getHeroList();
  if (heroes.isEmpty) {
    printWarn("Inga hjältar att söka i.");
    return;
  }

  stdout.write("Ange sökterm (namn): ");
  final query = stdin.readLineSync()?.trim() ?? '';
  if (query.isEmpty) {
    printWarn("Tom sökterm.");
    return;
  }

  final results = await store.searchHero(query);
  if (results.isEmpty) {
    printError("❌ Inga matchande hjältar hittades.");
  } else {
    printInfo("\n=== Sökresultat ===");
    for (final h in results) {
      print(h.toString());
    }
  }
}

Future<void> deleteHero() async {
  final heroes = await store.getHeroList();
  if (heroes.isEmpty) {
    printWarn("Det finns inga hjältar att ta bort.");
    return;
  }

  final sorted = [...heroes]
    ..sort((a, b) {
      final as = int.tryParse('${a.powerstats?['strength'] ?? 0}') ?? 0;
      final bs = int.tryParse('${b.powerstats?['strength'] ?? 0}') ?? 0;
      return bs.compareTo(as);
    });

  printInfo("\n=== Ta bort hjälte ===");
  for (var i = 0; i < sorted.length; i++) {
    final s = int.tryParse('${sorted[i].powerstats?['strength'] ?? 0}') ?? 0;
    print("${i + 1}. ${sorted[i].name} (styrka: $s)");
  }

  stdout.write(
    "Ange nummer att ta bort (eller skriv exakt namn, tomt för avbryt): ",
  );
  final input = stdin.readLineSync()?.trim() ?? '';
  if (input.isEmpty) {
    printWarn("Avbrutet.");
    return;
  }

  HeroModel? toRemove;
  final idx = int.tryParse(input);
  if (idx != null && idx >= 1 && idx <= sorted.length) {
    toRemove = sorted[idx - 1];
  } else {
    final lower = input.toLowerCase();
    final matchIndex = sorted.indexWhere((h) => h.name.toLowerCase() == lower);
    if (matchIndex == -1) {
      printError("❌ Hittade ingen hjälte med det numret/namnet.");
      return;
    }
    toRemove = sorted[matchIndex];
  }

  stdout.write(
    "Är du säker på att du vill ta bort '${toRemove.name}'? (j/N): ",
  );
  final confirm = stdin.readLineSync()?.trim().toLowerCase();
  if (confirm != 'j' && confirm != 'ja' && confirm != 'y' && confirm != 'yes') {
    printWarn("Avbrutet.");
    return;
  }

  final ok = await store.deleteHeroById(toRemove.id);
  if (ok) {
    printSuccess("🗑️  '${toRemove.name}' borttagen.");
  } else {
    printError("❌ Kunde inte ta bort '${toRemove.name}'.");
  }
}