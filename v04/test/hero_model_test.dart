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

      // ---- Kontroll av parsing ----
      expect(hero.id, '70');
      expect(hero.name, 'Batman');
      expect(hero.powerstats?.strength, 26);
      expect(hero.powerstats?.intelligence, 100);
      expect(hero.biography?.fullName, 'Bruce Wayne');
      expect(hero.appearance?.gender, 'Male');

      // ---- Kontroll av rundresa via toJson ----
      final back = hero.toJson();

      expect(back['id'], '70');
      expect(back['name'], 'Batman');
      expect(back['powerstats']['strength'], 26);
      expect(back['powerstats']['intelligence'], 100);
      expect(back['biography']['full-name'], 'Bruce Wayne');
      expect(back['appearance']['gender'], 'Male');

      // ---- Bonus: JSON-serialisering ska inte krascha ----
      expect(() => jsonEncode(back), returnsNormally);
    });

    test('tål ofullständig JSON (nullable-fält)', () {
      final partial = {"id": 1, "name": "Mystery"};

      final hero = HeroModel.fromJson(partial);

      // id konverteras alltid till sträng
      expect(hero.id, '1');
      expect(hero.name, 'Mystery');
      expect(hero.biography, isNull);
      expect(hero.powerstats, isNull);

      // toString ska fungera trots null
      expect(hero.toString(), contains('Mystery'));
    });
  });
}