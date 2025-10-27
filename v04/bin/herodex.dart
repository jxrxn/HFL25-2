import 'dart:io';
import 'package:uuid/uuid.dart';

import 'package:v04/env.dart';
import 'package:v04/models/hero_model.dart';
import 'package:v04/managers/hero_data_manager.dart'; // ✅ Ny import
import 'package:v04/services/superhero_api_service.dart';

final _uuid = Uuid();

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



// === Hjälp för färgade rubriker och namn ===
String label(String text) => "$cyan$text:$reset";
String? _m(Map<String, dynamic>? map, String key) => map?[key]?.toString();

int _strengthOf(HeroModel h) {
  final v = h.powerstats?['strength'];
  if (v is int) return v;
  return int.tryParse('$v') ?? 0;
}

String _alignmentOf(HeroModel h) =>
    (h.biography?['alignment']?.toString().toLowerCase() ?? '').trim();

String _nameColor(HeroModel h) {
  final a = _alignmentOf(h);
  if (a.contains('bad') || a.contains('evil')) return red; // skurkar
  if (a.contains('good')) return green;                    // hjältar
  return cyan;                                             // neutrala/okända
}

// Kort rad (för online-söklistor)
String shortLine(HeroModel h) {
  final fullName = _m(h.biography, 'full-name') ?? 'Okänt';
  final gender   = _m(h.appearance, 'gender')   ?? 'Okänt';
  final strength = _strengthOf(h);
  final color    = _nameColor(h);

  return "$color${h.name}$reset ($fullName) | "
         "${label('styrka')} $strength | "
         "${label('kön')} $gender";
}

// Full rad (för lokala hjälte-listningar)
String heroLine(HeroModel h) {
  final fullName   = _m(h.biography, 'full-name') ?? 'Okänt';
  final gender     = _m(h.appearance, 'gender')   ?? 'Okänt';
  final race       = _m(h.appearance, 'race')     ?? 'Okänt';
  final alignment  = _m(h.biography, 'alignment') ?? 'neutral';
  final special    = _m(h.work, 'occupation')     ?? 'ingen';
  final strength   = _strengthOf(h);
  final nameColor  = _nameColor(h);

  return "$nameColor${h.name}$reset ($fullName) | "
         "${label('styrka')} $strength | "
         "${label('kön')} $gender | "
         "${label('ursprung')} $race | "
         "${label('alignment')} $alignment | "
         "${label('special')} $special";
}

// filter-helpers
enum AlignmentFilter { all, heroes, villains, neutral }

enum SortOrder { strength, nameAZ, nameZA }

String _aln(HeroModel h) =>
    (h.biography?['alignment']?.toString().toLowerCase() ?? '').trim();

bool _isHero(HeroModel h)    => _aln(h).contains('good') && !_aln(h).contains('bad');
bool _isVillain(HeroModel h) => _aln(h).contains('bad')  || _aln(h).contains('evil');
bool _isNeutral(HeroModel h) {
  final a = _aln(h);
  if (a.isEmpty) return true;                 // räkna okänt som neutral
  return a == 'neutral' || a.contains('neutral');
}

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

// ============================================================
// HERO HANDLING — via HeroDataManager
// ============================================================

final manager = HeroDataManager();

Future<bool> _existsByNameOrId(String name, String id) async {
  final list = await manager.getHeroList();
  final norm = name.trim().toLowerCase();
  return list.any((h) =>
    h.id == id || h.name.trim().toLowerCase() == norm
  );
}

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
  stdout.write("Styrka (0–100): ");
  final str = int.tryParse(stdin.readLineSync() ?? '') ?? 50;
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
    powerstats: {'strength': str},
    appearance: {'gender': gender, 'race': race},
    biography: {'alignment': align},
    work: {'occupation': occ},
  );

  await manager.saveHero(newHero);
  printSuccess("✅ Hjälten '$name' har lagts till!");
}

Future<void> listHeroes() async {
  final heroes = await manager.getHeroList();
  if (heroes.isEmpty) {
    printWarn("Inga hjältar sparade ännu.");
    return;
  }

  // === 1. Filtrera efter alignment ===
  final filter = _askAlignmentFilter();

  Iterable<HeroModel> filtered = heroes;
  switch (filter) {
    case AlignmentFilter.heroes:
      filtered = heroes.where(_isHero);
      break;
    case AlignmentFilter.villains:
      filtered = heroes.where(_isVillain);
      break;
    case AlignmentFilter.neutral:
      filtered = heroes.where(_isNeutral);
      break;
    case AlignmentFilter.all:
      // lämna som det är
      break;
  }

  // === 2. Välj sorteringsordning ===
  final sortOrder = _askSortOrder();

  final sorted = [...filtered];
  switch (sortOrder) {
    case SortOrder.nameAZ:
      sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
    case SortOrder.nameZA:
      sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      break;
    case SortOrder.strength:
      sorted.sort((a, b) => _strengthOf(b).compareTo(_strengthOf(a)));
      break;
  }

  // === 3. Titel för visning ===
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

  // === 4. Utskrift ===
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

  await manager.deleteHeroById(hero.id);
  printSuccess("🗑️  Hjälten '${hero.name}' borttagen.");
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

    await manager.saveHero(selected);
    printSuccess("✅ '${selected.name}' sparad i lokal lista.");
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

  bool running = true;
  while (running) {
    printInfo("\n=== HeroDex 3000 ===");
    print("1. Lägg till hjälte");
    print("2. Visa hjältar");
    print("3. Sök online (SuperHero API)");
    print("4. Ta bort hjälte");
    print("5. Avsluta");
    stdout.write("Välj: ");

    switch (stdin.readLineSync()?.trim()) {
      case '1': await addHero(); break;
      case '2': await listHeroes(); break;
      case '3': await searchHeroesOnline(); break;
      case '4': await deleteHero(); break;
      case '5':
        printSuccess("💾 Avslutar HeroDex 3000...");
        running = false;
        break;
      default:
        printWarn("⚠️  Ogiltigt val, försök igen.");
    }
  }
}