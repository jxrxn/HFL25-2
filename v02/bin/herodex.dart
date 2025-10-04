import 'dart:io';

List<Map<String, dynamic>> heroes = [];

void main() {
  bool running = true;

  while (running) {
    printMenu();
    final choice = stdin.readLineSync();

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
        print("Avslutar HeroDex 3000...");
        running = false;
        break;
      default:
        print("Ogiltigt val, försök igen.");
    }
  }
}

void printMenu() {
  print('''\n=== HeroDex 3000 ===
1. Lägg till hjälte
2. Visa hjältar
3. Sök hjälte
4. Avsluta
Välj: ''');
}

void addHero() {
  stdout.write("Ange namn: ");
  final name = stdin.readLineSync()?.trim();
  stdout.write("Ange styrka (heltal): ");
  final s = int.tryParse(stdin.readLineSync()?.trim() ?? '') ?? 0;
  stdout.write("Ange specialkraft: ");
  final power = stdin.readLineSync()?.trim();

  final hero = {
    "name": name?.isNotEmpty == true ? name : "Okänd",
    "powerstats": {"strength": s},
    "appearance": {"gender": "Unknown", "race": "Unknown"},
    "biography": {"alignment": "neutral"},
    "special": power?.isNotEmpty == true ? power : "ingen",
  };

  heroes.add(hero);
  print("${hero['name']} tillagd!");
}

void showHeroes() {
  if (heroes.isEmpty) {
    print("Inga hjältar tillagda ännu.");
    return;
  }
  heroes.sort((a, b) =>
      (b["powerstats"]["strength"] as int).compareTo(a["powerstats"]["strength"] as int));

  print("\n--- Hjältar ---");
  heroes.forEach((h) {
    print("${h['name']} (styrka: ${h['powerstats']['strength']}, kraft: ${h['special']})");
  });
}

void searchHeroes() {
  stdout.write("Ange namn eller bokstav att söka efter: ");
  final q = stdin.readLineSync()?.trim() ?? '';
  if (q.isEmpty) {
    print("Ingen söksträng angavs.");
    return;
  }
  final results = heroes.where((h) => (h['name'] as String).toLowerCase().contains(q.toLowerCase()));
  if (results.isEmpty) {
    print("Inga matchande hjältar.");
  } else {
    print("\n--- Sökresultat ---");
    results.forEach((h) {
      print("${h['name']} (styrka: ${h['powerstats']['strength']}, kraft: ${h['special']})");
    });
  }
}