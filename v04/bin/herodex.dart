import 'dart:io';

import 'package:uuid/uuid.dart';

import 'package:v04/app_store.dart';
import 'package:v04/env.dart';
import 'package:v04/models/hero_model.dart';
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

/// ====== Start & argument ======
/// - `dart run bin/herodex.dart`                → skarpt läge (standardstore → heroes.json)
/// - `dart run bin/herodex.dart --mock`         → mock-läge   (test/mock_heroes.json)
/// - `dart run bin/herodex.dart --data=PATH`    → använd valfri fil (vinner över --mock)
Future<void> main(List<String> args) async {
  Env.load();

  final token = Env.superheroToken;
  if (token == null || token.isEmpty || token == 'DIN_TOKEN_HÄR') {
    printError('⚠️  Ingen giltig SUPERHERO_TOKEN – lägg in din riktiga token i .env');
  } else {
    final hidden = token.length > 6
    ? '${token.substring(0, 3)}•••${token.substring(token.length - 3)}'
    : '•••';
    printInfo('🔑 Token laddad: $hidden');
  }

  final isMock = args.contains('--mock');
  final dataArg = args.firstWhere(
    (a) => a.startsWith('--data='),
    orElse: () => '',
  );

  // Prioritet: --data=... vinner → annars --mock → annars standard (null ⇒ heroes.json)
  final String? dataFile = () {
    if (dataArg.isNotEmpty) return dataArg.split('=').last;
    if (isMock) {
      final src = File('test/mock_heroes.json');
      final dst = File('mock_runtime.json'); // denna ska inte versionshanteras
      if (src.existsSync()) {
        if (!dst.existsSync()) {
          dst.writeAsStringSync(src.readAsStringSync());
        }
      } else {
        if (!dst.existsSync()) dst.writeAsStringSync('[]');
      }
      return 'mock_runtime.json';
    }
    // standard -> heroes.json via din manager
    return null;
  }();

  // ✅ Registrera rätt store i GetIt (via app_store.dart)
  initStore(dataFile: dataFile);

  print("\x1B[36m🗂  Använder datafil: ${dataFile ?? 'heroes.json (standard)'}\x1B[0m");

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

/// ====== Spara utan dubletter ======

Future<void> saveUnique(HeroModel hero) async {
  final list = await store.getHeroList();

  // Dubblettkoll: id ELLER namn (case-insensitive)
  final alreadyById = list.any((h) => h.id == hero.id);
  final norm = hero.name.trim().toLowerCase();
  final alreadyByName =
      list.any((h) => h.name.trim().toLowerCase() == norm);

  if (alreadyById || alreadyByName) {
    printWarn("⚠️  '${hero.name}' finns redan (match på ${alreadyById ? 'id' : 'namn'}).");
    return;
  }

  await store.saveHero(hero);
  printSuccess("✅ '${hero.name}' sparad i lokal lista.");
}

String _norm(String s) => s.trim().toLowerCase();

/// Frågar efter ett alias som inte redan finns.
/// Returnerar `null` om användaren avbryter.
Future<String?> askUniqueAlias({String prompt = "Ange hjältenamn (alias)"}) async {
  final existing = (await store.getHeroList()).map((h) => _norm(h.name)).toSet();

  while (true) {
    stdout.write("$prompt (tomt = avbryt): ");
    final raw = stdin.readLineSync()?.trim() ?? '';

    if (raw.isEmpty) {
      printWarn("Avbrutet.");
      return null;
    }

    final norm = _norm(raw);
    if (existing.contains(norm)) {
      printError("⚠️  Namnet '$raw' är redan upptaget. Välj ett annat.");
      continue;
    }

    return raw;
  }
}

/// ====== Sökfiltrering ======
enum AlignmentFilter { all, heroes, villains }

String _alignmentOf(HeroModel h) =>
    (h.biography?['alignment']?.toString().toLowerCase() ?? '').trim();

bool _isHero(HeroModel h) {
  final a = _alignmentOf(h);
  // Träffar 'good', 'neutral good', etc.
  return a.contains('good') && !a.contains('bad');
}

bool _isVillain(HeroModel h) {
  final a = _alignmentOf(h);
  // Träffar 'bad', 'evil', etc. (API brukar ha 'bad')
  return a.contains('bad') || a.contains('evil');
}

/// ====== Sök-/listfiltrering (1–3) ======
/// 1 = Alla, 2 = Heroes (good), 3 = Villains (bad)
AlignmentFilter _askAlignmentFilter() {
  printInfo("\nVälj filter för visning:");
  print("1. Alla");
  print("2. Heroes (good)");
  print("3. Villains (bad)");
  stdout.write("Val (1–3, tomt = 1): ");

  final v = stdin.readLineSync()?.trim();
  switch (v) {
    case '2':
      return AlignmentFilter.heroes;   // alignment innehåller 'good'
    case '3':
      return AlignmentFilter.villains; // alignment innehåller 'bad' eller 'evil'
    default:
      return AlignmentFilter.all;
  }
}

/// ====== Hjälpfunktioner för alignment ======
String askAlignment() {
  printInfo("\nVälj alignment:");
  print("1. God (good)");
  print("2. Neutral");
  print("3. Ond (bad)");
  stdout.write("Val (1–3, tomt = 2): ");
  final v = stdin.readLineSync()?.trim();
  switch (v) {
    case '1':
      return 'good';
    case '3':
      return 'bad';
    default:
      return 'neutral';
  }
}

/// ====== Funktion för att lägga till hjälte ======
Future<void> addHero() async {
  final name = await askUniqueAlias();
  if (name == null) return; // användaren avbröt

  final realName = askString("Ange riktigt namn (valfritt)", defaultValue: "");
  final strength = askStrength();
  final special = askString("Ange specialkraft", defaultValue: "ingen");
  final gender = askString("Ange kön", defaultValue: "Okänt");
  final origin = askString("Ange ursprung/ras", defaultValue: "Okänt");
  final align = askAlignment();

  final hero = HeroModel(
    id: _uuid.v4(),
    name: name,
    powerstats: {"strength": strength},
    appearance: {"gender": gender, "race": origin},
    biography: {
      "alignment": align,
      if (realName.isNotEmpty) "full-name": realName,
    },
    work: {"occupation": special},
  );

  // Direkt spara, utan ny dublettkoll (den gjordes redan i askUniqueAlias)
  await store.saveHero(hero);
  printSuccess("✅ '${hero.name}' tillagd!");
}

Future<void> showHeroes() async {
  final heroes = await store.getHeroList();
  if (heroes.isEmpty) {
    printWarn("Inga hjältar tillagda ännu.");
    return;
  }

  final filter = _askAlignmentFilter();

  Iterable<HeroModel> filtered = heroes;
  switch (filter) {
    case AlignmentFilter.heroes:
      filtered = heroes.where(_isHero);
      break;
    case AlignmentFilter.villains:
      filtered = heroes.where(_isVillain);
      break;
    case AlignmentFilter.all:
      // lämna som är
      break;
  }

  final sorted = [...filtered]..sort((a, b) {
    final as = int.tryParse('${a.powerstats?['strength'] ?? 0}') ?? 0;
    final bs = int.tryParse('${b.powerstats?['strength'] ?? 0}') ?? 0;
    return bs.compareTo(as);
  });

  final title = switch (filter) {
    AlignmentFilter.heroes => "Hjältar (good)",
    AlignmentFilter.villains => "Skurkar (bad)",
    AlignmentFilter.all => "Alla (starkast först)",
  };

  if (sorted.isEmpty) {
    printWarn("Inga poster matchade filtret.");
    return;
  }

  printInfo("\n=== $title ===");
  for (final h in sorted) {
    print(h.toString());
  }
}

Future<void> searchHeroes() async {
  // 1) Läs sökterm
  stdout.write("Ange sökterm (namn): ");
  final query = stdin.readLineSync()?.trim() ?? '';
  if (query.isEmpty) {
    printWarn("Tom sökterm.");
    return;
  }

  // 2) Försök online-sök om vi har giltig token
  List<HeroModel> online = [];
  final token = Env.superheroToken;
  final hasValidToken = token != null && token.isNotEmpty && token != 'DIN_TOKEN_HÄR';

  if (hasValidToken) {
    final api = SuperheroApiService(token);
    try {
      online = await api.searchByName(query);
    } finally {
      api.close();
    }
  } else {
    printWarn("🔒 Ingen giltig SUPERHERO_TOKEN — hoppar över onlinesökning.");
  }

  // 3) Skriv ut onlineträffar (om några)
  if (online.isNotEmpty) {
    printInfo("\n=== Online-sökresultat (SuperHero API) ===");
    for (var i = 0; i < online.length; i++) {
      final h = online[i];
      // gör det kompakt men informativt
      print("${i + 1}. ${h.toShortString()}");
    }

    // 3b) Fråga om du vill spara någon av onlineresultaten
    stdout.write("Spara en av dessa? Ange nummer (tomt = nej): ");
    final choice = stdin.readLineSync()?.trim();
    if (choice != null && choice.isNotEmpty) {
      final idx = int.tryParse(choice);
      if (idx != null && idx >= 1 && idx <= online.length) {
        final selected = online[idx - 1];
        await saveUnique(selected); // använder din helper som kollar dubletter
      } else {
        printWarn("Ogiltigt nummer, sparar inget.");
      }
    }
  } else if (hasValidToken) {
    printWarn("❌ Inga online-träffar hittades.");
  }

  // 4) Lokalt sök (alltid): så du ser vad som redan finns
  final localList = await store.searchHero(query);
  if (localList.isEmpty) {
    printWarn("\n(Inga lokala matchningar.)");
  } else {
    printInfo("\n=== Lokala matchningar ===");
    for (final h in localList) {
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
