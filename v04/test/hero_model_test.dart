import 'dart:convert';
import 'package:test/test.dart';
import 'package:v04/models/hero_model.dart';

void main() {
  group('HeroModel', () {
    test('fromJson + toJson rundresa', () {
      final jsonMap = <String, dynamic>{
        "id": "70",
        "name": "Batman",
        "powerstats": {"strength": "26", "intelligence": "100"},
        "biography": {"full-name": "Bruce Wayne"},
        "appearance": {"gender": "Male"},
        "work": {"occupation": "Businessman"},
        "connections": {"group-affiliation": "Justice League"},
        "image": {"url": "https://example.com/batman.jpg"},
      };

      final hero = HeroModel.fromJson(jsonMap);

      expect(hero.id, '70');
      expect(hero.name, 'Batman');
      expect(hero.powerstats?['strength'], '26');
      expect(hero.biography?['full-name'], 'Bruce Wayne');
      expect(hero.appearance?['gender'], 'Male');

      final back = hero.toJson();
      // Räkna med att toJson kan sakna null-fält men här hade vi allt
      expect(back['name'], 'Batman');
      expect(back['powerstats']['intelligence'], '100');

      // Bonus: säkerställ att JSON-serialisering fungerar
      expect(() => jsonEncode(back), returnsNormally);
    });

    test('tål ofullständig JSON (nullable-fält)', () {
      final partial = {"id": 1, "name": "Mystery"};
      final hero = HeroModel.fromJson(partial);
      expect(hero.id, '1'); // coerce till sträng
      expect(hero.name, 'Mystery'); // finns
      expect(hero.biography, isNull);
      expect(hero.powerstats, isNull);
      // toString ska inte krascha trots null
      expect(hero.toString(), contains('Mystery'));
    });
  });
}
