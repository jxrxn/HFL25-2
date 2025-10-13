import 'package:v03/v03.dart';

Future<void> main() async {
  final realService = HeroService(RealApiManager());
  await realService.printHero();

  final mockService = HeroService(MockApiManager('Spider-Man'));
  await mockService.printHero();
}
