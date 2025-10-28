import 'package:test/test.dart';
import 'package:v04/models/models.dart'; // <- Barrel som ska exportera allt

void main() {
  group('models barrel', () {
    test('exporter finns och fungerar ihop', () {
      // Powerstats
      final ps = Powerstats(strength: 10, intelligence: 90);
      expect(ps.toJson()['strength'], 10);

      // Appearance
      final ap = Appearance(gender: 'Male', race: 'Human');
      expect(ap.gender, 'Male');

      // Biography
      final bi = Biography(fullName: 'Bruce Wayne', alignment: 'good');
      expect(bi.fullName, 'Bruce Wayne');
      expect(bi.alignment, 'good');

      // Work
      final wo = Work(occupation: 'Detective');
      expect(wo.occupation, 'Detective');

      // HeroModel (alla typer ihop)
      final hero = HeroModel(
        id: '1',
        name: 'Batman',
        powerstats: ps,
        appearance: ap,
        biography: bi,
        work: wo,
      );

      expect(hero.name, 'Batman');
      expect(hero.powerstats?.strength, 10);
      expect(hero.appearance?.race, 'Human');
      expect(hero.biography?.alignment, 'good');
      expect(hero.work?.occupation, 'Detective');

      // toJson ska vara stabil och JSON-kompatibel
      final json = hero.toJson();
      expect(json['name'], 'Batman');
      expect(json['powerstats'], isA<Map<String, dynamic>>());
      expect(json['appearance'], isA<Map<String, dynamic>>());
      expect(json['biography'], isA<Map<String, dynamic>>());
      expect(json['work'], isA<Map<String, dynamic>>());
    });
  });
}