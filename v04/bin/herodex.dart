// bin/herodex.dart
import 'dart:io';

import 'package:uuid/uuid.dart';

import 'package:v04/env.dart';
import 'package:v04/managers/hero_data_manager.dart';
import 'package:v04/models/models.dart';             // barrel: alla modeller
import 'package:v04/services/superhero_api_service.dart';
import 'package:v04/ui/cli_utils.dart';              // färger + print* helpers + label()
import 'package:v04/usecases/hero_usecases.dart';    // AlignmentFilter/SortOrder + logik

final _uuid = Uuid();

/// ====== Banner (färger kommer från cli_utils.dart) ======
void printBanner() {
  print(cyan);
  print(r'''
╔═════════════════════════════════════════════════════════════════╗
║                                                                 ║
║    ██╗  ██╗███████╗██████╗  ██████╗ ██████╗ ███████╗██╗  ██╗    ║
║    ██║  ██║██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔════╝╚██╗██╔╝    ║
║    ███████║█████╗  ██████╔╝██║   ██║██║  ██║█████╗   ╚███╔╝     ║
║    ██╔══██║██╔══╝  ██╔══██╗██║   ██║██║  ██║██╔══╝   ██╔██╗     ║
║    ██║  ██║███████╗██║  ██║╚██████╔╝██████╔╝███████╗██╔╝ ██╗    ║
║    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ║
║                                                                 ║
║               ██████╗  ██████╗  ██████╗  ██████╗                ║
║                ╚══███╗██╔═══██╗██╔═══██╗██╔═══██╗               ║
║                ████╔═╝██║   ██║██║   ██║██║   ██║               ║
║                 ╚═███╗██║   ██║██║   ██║██║   ██║               ║
║               ██████╔╝╚██████╔╝╚██████╔╝╚██████╔╝               ║
║               ╚═════╝  ╚═════╝  ╚═════╝  ╚═════╝                ║
║                                                                 ║
║                  HeroDex 3000 — Superhero CLI                   ║
║                                                                 ║
╚═════════════════════════════════════════════════════════════════╝
''');
  print(reset);
}

/// ====== Presentationshjälp (UI-lager) ======
int _strengthOf(HeroModel h) => h.powerstats?.strength ?? 0;

String _nameColor(HeroModel h) {
  final a = h.alignmentNormalized; // 'good' | 'bad' | 'neutral'
  if (a == 'bad') return red;
  if (a == 'good') return green;
  return cyan;
}

// Kort rad (för online-söklistor)
String shortLine(HeroModel h) {
  final fullName = h.biography?.fullName ?? 'Okänt';
  final gender   = h.appearance?.gender ?? 'Okänt';
  final strength = _strengthOf(h);
  final color    = _nameColor(h);

  return "$color${h.name}$reset ($fullName) | "
         "${label('styrka')} $strength | "
         "${label('kön')} $gender";
}

// Full rad (för lokala hjälte-listningar)
String heroLine(HeroModel h) {
  final fullName   = h.biography?.fullName ?? 'Okänt';
  final gender     = h.appearance?.gender ?? 'Okänt';
  final race       = h.appearance?.race ?? 'Okänt';
  final alignment  = h.biography?.alignment ?? 'neutral';
  final special    = h.work?.occupation ?? 'ingen';
  final strength   = _strengthOf(h);
  final nameColor  = _nameColor(h);

  return "$nameColor${h.name}$reset ($fullName) | "
         "${label('styrka')} $strength | "
         "${label('kön')} $gender | "
         "${label('ursprung')} $race | "
         "${label('alignment')} $alignment | "
         "${label('special')} $special";
}

/// ====== Inputhjälpare (CLI) ======
AlignmentFilter _askAlignmentFilter() {
  printInfo("\nVälj filter för visning:");
  print("1. Alla");
  print("2. Heroes (good)");
  print("3. Villains (bad/evil)");
  print("4. Neutral");
  stdout.write("Val (1–4, tomt = 1): ");
  switch ((stdin.readLineSync() ?? '').trim()) {
    case '2': return AlignmentFilter.heroes;
    case '3': return AlignmentFilter.villains;
    case '4': return AlignmentFilter.neutral;
    default:  return AlignmentFilter.all;
  }
}

SortOrder _askSortOrder() {
  printInfo("\nVälj sorteringsordning:");
  print("1. Efter styrka (standard)");
  print("2. Efter namn (A–Ö)");
  print("3. Efter namn (Ö–A)");
  stdout.write("Val (1–3, tomt = 1): ");
  switch ((stdin.readLineSync() ?? '').trim()) {
    case '2': return SortOrder.nameAZ;
    case '3': return SortOrder.nameZA;
    default:  return SortOrder.strength;
  }
}

int _askIntInRange(String prompt, {required int min, required int max, required int fallback}) {
  while (true) {
    stdout.write("$prompt ($min–$max): ");
    final raw = stdin.readLineSync()?.trim() ?? '';
    final v = int.tryParse(raw);
    if (v != null && v >= min && v <= max) return v;
    if (raw.isEmpty) return fallback; // Enter ⇒ fallback inom intervallet
    printWarn("⚠️  Ogiltigt värde. Ange heltal $min–$max eller Enter för $fallback.");
  }
}

/// ====== Use cases / manager ======
final manager = HeroDataManager();
final useCases = HeroUseCases(manager);

Future<bool> _existsByNameOrId(String name, String id) {
  return useCases.existsByNameOrId(name, id);
}

/// ====== Kommandon ======
Future<void> addHero() async {
  stdout.write("Ange nytt hjältenamn: ");
  final name = stdin.readLineSync()?.trim();
  if (name == null || name.isEmpty) return;

  final heroes = await manager.getHeroList();
  final exists = heroes.any((h) => h.name.toLowerCase() == name.toLowerCase());
  if (exists) {
    printWarn("⚠️  Hjälten '$name' finns redan i databasen.");
    return;
  }

  final id = _uuid.v4();
  final str = _askIntInRange("Styrka", min: 0, max: 100, fallback: 50);
  stdout.write("Kön: ");
  final gender = stdin.readLineSync()?.trim() ?? 'Okänt';
  stdout.write("Ursprung: ");
  final race = stdin.readLineSync()?.trim() ?? 'Okänt';
  stdout.write("Alignment (good/neutral/bad): ");
  final align = stdin.readLineSync()?.trim().toLowerCase() ?? 'neutral';
  stdout.write("Specialitet: ");
  final occ = stdin.readLineSync()?.trim() ?? 'ingen';

  final newHero = HeroModel(
    id: id,
    name: name,
    powerstats: Powerstats(strength: str),
    appearance: Appearance(gender: gender, race: race),
    biography: Biography(alignment: align),
    work: Work(occupation: occ),
  );

  final saved = await useCases.addHero(newHero);
  if (saved) {
    printSuccess("✅ Hjälten '$name' har lagts till!");
  } else {
    printWarn("⚠️  Kunde inte spara (dubblett eller ogiltiga fält).");
  }
}

Future<void> listHeroes() async {
  final all = await manager.getHeroList();
  if (all.isEmpty) {
    printWarn("Inga hjältar sparade ännu.");
    return;
  }

  // 1) Fråga efter filter + sort
  final filter = _askAlignmentFilter();
  final sortOrder = _askSortOrder();

  // 2) Hämta listan via use case (logik utanför CLI)
  final sorted = await useCases.listHeroes(filter: filter, sortOrder: sortOrder);

  // 3) Titel
  final title = switch (filter) {
    AlignmentFilter.heroes   => "Hjältar (good)",
    AlignmentFilter.villains => "Skurkar (bad)",
    AlignmentFilter.neutral  => "Neutrala",
    AlignmentFilter.all      => "Alla",
  };
  final sortLabel = switch (sortOrder) {
    SortOrder.nameAZ   => " (A–Ö)",
    SortOrder.nameZA   => " (Ö–A)",
    SortOrder.strength => " (styrka)",
  };

  if (sorted.isEmpty) {
    printWarn("Inga poster matchade filtret.");
    return;
  }

  printInfo("\n=== $title$sortLabel — ${sorted.length} st ===");
  for (final h in sorted) {
    print(heroLine(h));
  }
}

Future<void> deleteHero() async {
  final heroes = await manager.getHeroList();
  if (heroes.isEmpty) {
    printWarn("Det finns inga hjältar att ta bort.");
    return;
  }

  for (var i = 0; i < heroes.length; i++) {
    print("${i + 1}. ${heroes[i].name}");
  }

  stdout.write("Ange numret på hjälten att ta bort (eller tomt för avbryt): ");
  final input = stdin.readLineSync()?.trim();
  if (input == null || input.isEmpty) {
    printWarn("Avbrutet.");
    return;
  }

  final idx = int.tryParse(input);
  if (idx == null || idx < 1 || idx > heroes.length) {
    printError("❌ Ogiltigt nummer.");
    return;
  }

  final hero = heroes[idx - 1];
  stdout.write("Är du säker på att du vill ta bort '${hero.name}'? (j/N): ");
  final confirm = stdin.readLineSync()?.trim().toLowerCase();
  if (confirm != 'j') {
    printWarn("Avbrutet.");
    return;
  }

  final ok = await useCases.deleteHeroById(hero.id);
  if (ok) {
    printSuccess("🗑️  Hjälten '${hero.name}' borttagen.");
  } else {
    printError("⚠️  Något gick fel vid borttagning.");
  }
}

Future<void> searchHeroesOnline() async {
  final token = Env.superheroToken;
  if (token == null || token.isEmpty || token == 'DIN_TOKEN_HÄR') {
    printWarn("🔒 Ingen giltig SUPERHERO_TOKEN — hoppar över onlinesökning.");
    return;
  }

  stdout.write("Ange sökterm (namn): ");
  final query = stdin.readLineSync()?.trim() ?? '';
  if (query.isEmpty) {
    printWarn("Tom sökterm.");
    return;
  }

  final api = SuperheroApiService(token);
  try {
    final results = await api.searchByName(query);
    if (results.isEmpty) {
      printWarn("❌ Inga online-träffar hittades.");
      return;
    }

    printInfo("\n=== Online-sökresultat (SuperHero API) ===");
    for (var i = 0; i < results.length; i++) {
      final h = results[i];
      print("${i + 1}. ${shortLine(h)}");
    }

    stdout.write("Spara en av dessa? Ange nummer (tomt = nej): ");
    final choice = stdin.readLineSync()?.trim();
    if (choice == null || choice.isEmpty) return;

    final idx = int.tryParse(choice);
    if (idx == null || idx < 1 || idx > results.length) {
      printWarn("Ogiltigt nummer, sparar inget.");
      return;
    }

    final selected = results[idx - 1];
    if (await _existsByNameOrId(selected.name, selected.id)) {
      printWarn("⚠️  '${selected.name}' finns redan (namn eller id).");
      return;
    }

    final saved = await manager.saveUnique(selected);
    if (saved) {
      printSuccess("✅ '${selected.name}' sparad i lokal lista.");
    } else {
      printWarn("⚠️  Kunde inte spara (dubblett/ogiltiga fält).");
    }
  } finally {
    api.close();
  }
}

// ============================================================
// MAIN
// ============================================================

Future<void> main(List<String> args) async {
  Env.load();
  printBanner();

  var running = true;
  while (running) {
    printInfo("\n=== HeroDex 3000 ===");
    print("1. Lägg till hjälte");
    print("2. Visa hjältar");
    print("3. Sök online (SuperHero API)");
    print("4. Ta bort hjälte");
    print("5. Avsluta");
    stdout.write("Välj: ");

    switch (stdin.readLineSync()?.trim()) {
      case '1':
        await addHero();
        break;
      case '2':
        await listHeroes();
        break;
      case '3':
        await searchHeroesOnline();
        break;
      case '4':
        await deleteHero();
        break;
      case '5':
        printSuccess("💾 Avslutar HeroDex 3000...");
        running = false;
        break;
      default:
        printWarn("⚠️  Ogiltigt val, försök igen.");
    }
  }
}