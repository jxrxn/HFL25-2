import 'dart:io';
import 'package:test/test.dart';
import 'package:v04/v04.dart';

void main() {
  group('HeroDataManager med mockade filosofer', () {
    late String tempFilePath;
    late HeroDataManager manager;

    setUp(() async {
      // Kopiera in mockade hjältar till en temporär fil
      final tmpDir = await Directory.systemTemp.createTemp('herodex_mock_');
      tempFilePath = '${tmpDir.path}/heroes.json';
      await File('test/mock_heroes.json').copy(tempFilePath);

      manager = HeroDataManager.internalForTesting(tempFilePath);

      final list = await manager.getHeroList();
      expect(list.length, 3);
    });

    test('getHeroList returnerar 3 filosofer', () async {
      final list = await manager.getHeroList();
      expect(
        list.map((h) => h.name),
        containsAll(['Platon', 'Aristoteles', 'Epictetus']),
      );
    });

    test(
      'searchHero hittar rätt filosof (delsträng, case-insensitiv)',
      () async {
        final plato = await manager.searchHero('plato');
        expect(plato.first.name, 'Platon');

        final ari = await manager.searchHero('aristo');
        expect(ari.first.name, 'Aristoteles');

        final epi = await manager.searchHero('epic');
        expect(epi.first.name, 'Epictetus');
      },
    );

    test('deleteHeroById tar bort Platon och sparar korrekt', () async {
      final ok = await manager.deleteHeroById('P01');
      expect(ok, isTrue);

      final list = await manager.getHeroList();
      expect(list.length, 2);
      expect(list.any((h) => h.id == 'P01'), isFalse);
    });
  });
}
