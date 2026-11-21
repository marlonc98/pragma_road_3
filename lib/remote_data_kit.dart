/// Kit para consumir datos remotos.
///
/// Se usa a través de [RemoteDataKit], que se configura con
/// [RemoteDataKitConfig] y arma internamente el cliente HTTP y los
/// repositorios.
library;

// Punto de entrada
export 'src/remote_data_kit.dart';
export 'src/remote_data_kit_config.dart';

// domain/core
export 'src/domain/core/async_state.dart';
export 'src/domain/core/search_result.dart';

// domain/entities
export 'src/domain/entities/character_entity.dart';

// domain/errors
export 'src/domain/errors/async_state_error.dart';

// domain/repositories
export 'src/domain/repositories/character_repository.dart';
