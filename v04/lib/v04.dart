// Barrel file för v04 så att tester och demos kan importera ett enda paket.
// Exportera bara publika API:n (inga interna helpers här).

export 'app_store.dart';

// Managers / datalager
export 'managers/hero_data_manager.dart';
export 'managers/hero_data_managing.dart';

// Modeller
export 'models/hero_model.dart';

// Tjänstelager (API-abstraktioner och implementationer)
export 'services/api_manager.dart';
export 'services/hero_service.dart';
export 'services/mock_api_manager.dart';
export 'services/real_api_manager.dart';
export 'services/superhero_api_service.dart';
