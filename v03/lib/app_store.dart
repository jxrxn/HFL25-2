import 'package:meta/meta.dart';
import 'package:v03/managers/hero_data_manager.dart';
import 'package:v03/managers/hero_data_managing.dart';

/// Globalt datalager för appen (kan ersättas i tester)
HeroDataManaging _store = HeroDataManager();

/// Getter som används i produktionskod
HeroDataManaging get store => _store;

/// Setter som bara används i tester
@visibleForTesting
set storeForTesting(HeroDataManaging s) => _store = s;
