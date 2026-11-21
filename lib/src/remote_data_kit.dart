import 'package:remote_data_kit/src/data/repositories/character/character_repository_impl.dart';
import 'package:remote_data_kit/src/data/repositories/character/character_repository_mock.dart';
import 'package:remote_data_kit/src/data/settings/rest_api.dart';
import 'package:remote_data_kit/src/domain/repositories/character_repository.dart';
import 'package:remote_data_kit/src/remote_data_kit_config.dart';

/// Punto de entrada del paquete.
///
/// Recibe una [RemoteDataKitConfig] y arma internamente el cliente HTTP y los
/// repositorios:
///
/// ```dart
/// final kit = RemoteDataKit(
///   config: RemoteDataKitConfig(
///     environment: RemoteDataKitEnvironment.prod, // o .mock
///   ),
/// );
/// final state = await kit.characters.searchCharacters(page: 1);
/// ```
class RemoteDataKit {
  final RemoteDataKitConfig config;

  /// Consultas de personajes.
  final CharacterRepository characters;

  RemoteDataKit._(this.config, this.characters);

  factory RemoteDataKit({
    RemoteDataKitConfig config = const RemoteDataKitConfig(),
  }) {
    switch (config.environment) {
      case RemoteDataKitEnvironment.mock:
        return RemoteDataKit._(config, CharacterRepositoryMock());
      case RemoteDataKitEnvironment.prod:
        final api = RestApi(
          hostUrl: config.baseUrl,
          timeout: config.timeout,
          client: config.client,
        );
        return RemoteDataKit._(config, CharacterRepositoryImpl(api));
    }
  }
}
