// lib/app_store.dart
import 'package:meta/meta.dart';
import 'package:v03/managers/hero_data_manager.dart';
import 'package:v03/managers/hero_data_managing.dart';

/// Globalt datalager (produktion: filen heroes.json via HeroDataManager()).
HeroDataManaging _store = HeroDataManager();

/// Huvudåtkomst för appen.
HeroDataManaging get store => _store;

/// Initiera lagret beroende på läge/fil.
/// - Om [dataFile] anges används separat instans mot den filen
///   (perfekt för --mock eller --data=...).
/// - Annars används singletonen (produktion).
void initStore({String? dataFile}) {
  _store = (dataFile == null || dataFile.isEmpty)
      ? HeroDataManager()
      : HeroDataManager.internalForTesting(dataFile);
}

/// Endast för tester: ersätt lagret med valfri mock/fake.
@visibleForTesting
set storeForTesting(HeroDataManaging s) => _store = s;
