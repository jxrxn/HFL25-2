import 'package:v03/services/api_manager.dart';

class HeroService {
  final ApiManager api;
  HeroService(this.api);

  Future<void> printHero() async {
    final name = await api.fetchHeroName();
    print('Din hjälte är: $name');
  }
}
