import 'package:v04/services/api_manager.dart';

class RealApiManager implements ApiManager {
  @override
  Future<String> fetchHeroName() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'Batman';
  }
}
