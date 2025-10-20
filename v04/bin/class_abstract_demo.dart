import 'package:v04/v04.dart';

Future<void> main() async {
  final realService = HeroService(RealApiManager());
  await realService.printHero();

  final mockService = HeroService(MockApiManager('Spider-Man'));
  await mockService.printHero();
}
