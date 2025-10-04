import 'package:test/test.dart';
import '../bin/herodex.dart' as herodex;

void main() {
  test('Lägger till hjälte i listan', () {
    // Se till att listan är tom innan vi testar
    herodex.heroes.clear();

    // Simulera en hjälte
    var hero = {
      "name": "Testman",
      "powerstats": {"strength": 99},
      "appearance": {"gender": "Male", "race": "Human"},
      "biography": {"alignment": "good"},
      "special": "Testkraft",
    };

    herodex.heroes.add(hero);

    expect(herodex.heroes.length, 1);
    expect(herodex.heroes.first['name'], equals("Testman"));
  });
}