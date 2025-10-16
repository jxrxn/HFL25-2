import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:v03/managers/hero_data_manager.dart';
import 'package:v03/managers/hero_data_managing.dart';

final GetIt _getIt = GetIt.instance;

/// Anropa detta en gång i `main()`
/// - Om [dataFile] sätts: använd test-konstruktorn (bra för --mock / --data)
/// - Om [dataFile] är null: använd produktions-singletonen
void initStore({String? dataFile}) {
  // Avregistrera ev. tidigare registration (t.ex. om du startar om med annan fil)
  if (_getIt.isRegistered<HeroDataManaging>()) {
    _getIt.unregister<HeroDataManaging>();
  }

  final manager = (dataFile == null)
      ? HeroDataManager() // prod-singleton som läser/skriv­er heroes.json
      : HeroDataManager.internalForTesting(dataFile); // frikopplad, egen fil

  _getIt.registerSingleton<HeroDataManaging>(manager);
}

/// Global åtkomstpunkt som du använder i appen
HeroDataManaging get store => _getIt<HeroDataManaging>();

/// Test-hook om du vill byta implementation i tester
@visibleForTesting
set storeForTesting(HeroDataManaging s) {
  if (_getIt.isRegistered<HeroDataManaging>()) {
    _getIt.unregister<HeroDataManaging>();
  }
  _getIt.registerSingleton<HeroDataManaging>(s);
}