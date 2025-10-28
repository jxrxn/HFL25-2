import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:v04/managers/hero_data_manager.dart';
import 'package:v04/models/hero_model.dart';

void main() {
  group('HeroDataManager – inläsning & persistens', () {
    late Directory tmpDir;
    late String dbPath;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('herodex_test_');
      dbPath = '${tmpDir.path}/heroes.json';
    });

    tearDown(() {
      if (tmpDir.existsSync()) {
        tmpDir.deleteSync(recursive: true);
      }
    });

    test('Sparar och hämtar rundresa', () async {
      final mgr = HeroDataManager.internalForTesting(dbPath);

      final batman = HeroModel(
        id: '70',
        name: 'Batman',
        powerstats: const Powerstats(strength: 26, intelligence: 100),
        appearance: const Appearance(gender: 'Male', race: 'Human'),
        biography: const Biography(fullName: 'Bruce Wayne', alignment: 'good'),
        work: const Work(occupation: 'Businessman'),
      );

      await mgr.saveHero(batman);

      final list = await mgr.getHeroList();
      expect(list.length, 1);
      expect(list.first.name, 'Batman');
      expect(list.first.powerstats?.strength, 26);

      // Kontrollera att filen skrevs och är giltig JSON
      final raw = File(dbPath).readAsStringSync();
      expect(() => jsonDecode(raw), returnsNormally);
    });

    test('saveUnique skyddar mot dubbletter (id eller namn)', () async {
      final mgr = HeroDataManager.internalForTesting(dbPath);

      final h1 = HeroModel(id: '1', name: 'Flash');
      final h2 = HeroModel(id: '1', name: 'Flashy'); // samma id → blockeras
      final h3 = HeroModel(id: '2', name: 'flash');  // samma namn (case-insens) → blockeras
      final h4 = HeroModel(id: '3', name: 'Green Lantern');

      expect(await mgr.saveUnique(h1), isTrue);
      expect(await mgr.saveUnique(h2), isFalse);
      expect(await mgr.saveUnique(h3), isFalse);
      expect(await mgr.saveUnique(h4), isTrue);

      final list = await mgr.getHeroList();
      final names = list.map((e) => e.name).toList()..sort();
      expect(names, ['Flash', 'Green Lantern']);
    });

    test('existsByName är case-insensitivt', () async {
      final mgr = HeroDataManager.internalForTesting(dbPath);
      await mgr.saveUnique(HeroModel(id: '10', name: 'Wonder Woman'));

      expect(await mgr.existsByName('wonder woman'), isTrue);
      expect(await mgr.existsByName('WONDER WOMAN'), isTrue);
      expect(await mgr.existsByName('Wonder'), isFalse);
    });

    test('searchHero hittar delsträngar (case-insensitivt)', () async {
      final mgr = HeroDataManager.internalForTesting(dbPath);
      await mgr.saveUnique(HeroModel(id: '20', name: 'Spider-Man'));
      await mgr.saveUnique(HeroModel(id: '21', name: 'Man-Thing'));
      await mgr.saveUnique(HeroModel(id: '22', name: 'Storm'));

      final res1 = await mgr.searchHero('man');
      final found1 = res1.map((e) => e.name).toList()..sort();
      expect(found1, ['Man-Thing', 'Spider-Man']);

      final res2 = await mgr.searchHero('ST');
      final found2 = res2.map((e) => e.name).toList()..sort();
      expect(found2, ['Storm']);
    });

    test('deleteHeroById tar bort korrekt hjälte', () async {
      final mgr = HeroDataManager.internalForTesting(dbPath);
      final a = HeroModel(id: 'a', name: 'A');
      final b = HeroModel(id: 'b', name: 'B');
      await mgr.saveUnique(a);
      await mgr.saveUnique(b);

      expect((await mgr.getHeroList()).length, 2);
      expect(await mgr.deleteHeroById('b'), isTrue);
      final left = await mgr.getHeroList();
      expect(left.length, 1);
      expect(left.first.id, 'a');
      expect(await mgr.deleteHeroById('missing'), isFalse);
    });

    test('Läser ÄLDRE/lös JSON och hoppar över trasiga + deduplar', () async {
      // Skapa “lös”/äldre JSON med strängsiffror, tomma id:n, rena mappar etc.
      final rawList = [
        {
          "id": "70",
          "name": "Batman",
          "powerstats": {"strength": "26"}
        },
        {
          "id": "70", // dubblett-id → ska hoppas över
          "name": "batman"
        },
        {
          "id": "71",
          "name": "  BATMAN  " // dubblett-namn efter normalisering → hoppas över
        },
        {
          "id": "", // ogiltigt id → hoppas över
          "name": "Unknown"
        },
        {
          // trasig post (saknar namn/id) → hoppas över
          "powerstats": {"strength": "50"}
        },
        {
          "id": "72",
          "name": "Robin"
        }
      ];
      File(dbPath).writeAsStringSync(jsonEncode(rawList));

      final mgr = HeroDataManager.internalForTesting(dbPath);
      final list = await mgr.getHeroList();

      // Förväntan: deduplad & filtrerad → Batman (70), Robin (72) = 2 st
      expect(list.length, 2);
      final names = list.map((h) => h.name.toLowerCase()).toList()..sort();
      expect(names, ['batman', 'robin']);
    });
  });
}