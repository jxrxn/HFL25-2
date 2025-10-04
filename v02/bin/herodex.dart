import 'dart:io';

List<Map<String, dynamic>> heroes = [];

void main() {
  bool running = true;

  while (running) {
    printMenu();
    String? choice = stdin.readLineSync();

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
  String? name = stdin.readLineSync();

  stdout.write("Ange styrka (heltal): ");
  String? strengthStr = stdin.readLineSync();
  int strength = int.tryParse(strengthStr ?? '') ?? 0;

  stdout.write("Ange specialkraft: ");
  String? power = stdin.readLineSync();

  Map<String, dynamic> hero = {
    "name": name ?? "Okänd",
    "powerstats": {"strength": strength},
    "appearance": {
      "gender": "Unknown",
      "race": "Unknown",
    },
    "biography": {"alignment": "neutral"},
    "special": power ?? "ingen",
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
  heroes.forEach((hero) {
    print(
        "${hero['name']} (styrka: ${hero['powerstats']['strength']}, kraft: ${hero['special']})");
  });
}

void searchHeroes() {
  stdout.write("Ange namn eller bokstav att söka efter: ");
  String? query = stdin.readLineSync();
  if (query == null || query.isEmpty) {
    print("Ingen söksträng angavs.");
    return;
  }

  var results = heroes.where((hero) =>
      (hero['name'] as String).toLowerCase().contains(query.toLowerCase()));

  if (results.isEmpty) {
    print("Inga matchande hjältar.");
  } else {
    print("\n--- Sökresultat ---");
    results.forEach((hero) {
      print(
          "${hero['name']} (styrka: ${hero['powerstats']['strength']}, kraft: ${hero['special']})");
    });
  }
}