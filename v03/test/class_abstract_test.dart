import 'package:test/test.dart';
import 'package:v03/services/hero_service.dart';
import 'package:v03/services/mock_api_manager.dart';

void main() {
  test('HeroService använder ApiManager och returnerar mockat namn', () async {
    final service = HeroService(MockApiManager('Wonder Woman'));

    // I ett riktigt test hade vi fångat outputen eller låtit
    // service exponera ett resultat i stället för att printa.
    // Här verifierar vi "indirekt" genom att bara anropa och
    // säkerställa att det inte kastar fel.
    await service.printHero();

    // Om du vill göra det verifierbart utan print:
    // Skapa en metod i HeroService som returnerar strängen i stället:
    // final result = await service.getHeroName();
    // expect(result, 'Wonder Woman');
  });
}
