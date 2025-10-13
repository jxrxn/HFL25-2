import 'dart:io';
import 'package:test/test.dart';
import 'package:v03/models/hero_model.dart';
import 'package:v03/managers/hero_data_manager.dart';

void main() {
  group('HeroDataManager', () {
    late HeroDataManager manager;
    late String tempFile;

    setUp(() async {
      // Skapa temporär testfil
      final dir = Directory.systemTemp.createTempSync();
      tempFile = '${dir.path}/heroes_test.json';

      // Skapa ny instans med separat fil
      manager = HeroDataManager();
      // ⚠️ Byt ut filnamnet dynamiskt
      manager = HeroDataManager.internalForTesting(tempFile);

      // Starta med tom lista
      await File(tempFile).writeAsString('[]');
    });

    tearDown(() {
      File(tempFile).deleteSync(recursive: true);
    });

    test('kan spara och hämta hjälte', () async {
      final hero = HeroModel(
        id: '1',
        name: 'Testman',
        powerstats: {'strength': 42},
      );
      await manager.saveHero(hero);

      final list = await manager.getHeroList();
      expect(list, isNotEmpty);
      expect(list.first.name, equals('Testman'));
    });

    test('kan söka hjälte', () async {
      await manager.saveHero(
        HeroModel(id: '2', name: 'Wonder', powerstats: {'strength': 10}),
      );
      final results = await manager.searchHero('won');
      expect(results.first.name, contains('Wonder'));
    });

    test('kan ta bort hjälte', () async {
      await manager.saveHero(
        HeroModel(id: '3', name: 'DeleteMe', powerstats: {'strength': 99}),
      );
      final before = await manager.getHeroList();
      expect(before.length, 1);

      final removed = await manager.deleteHeroById('3');
      expect(removed, isTrue);

      final after = await manager.getHeroList();
      expect(after, isEmpty);
    });
  });
}
