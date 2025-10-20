import 'package:v04/services/api_manager.dart';

class MockApiManager implements ApiManager {
  final String mockName;
  MockApiManager(this.mockName);

  @override
  Future<String> fetchHeroName() async => mockName;
}
