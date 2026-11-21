import 'package:http/http.dart' as http;

/// Entorno en el que trabaja [RemoteDataKit].
enum RemoteDataKitEnvironment {
  /// Consulta la API real en [RemoteDataKitConfig.baseUrl].
  prod,

  /// Usa datos de prueba internos (mock), sin llamar a la red.
  mock,
}

/// Configuración de [RemoteDataKit].
///
/// Todos los valores son opcionales: con `const RemoteDataKitConfig()` el kit
/// consulta en producción la API pública de Rick and Morty.
class RemoteDataKitConfig {
  /// Entorno a usar. Por defecto [RemoteDataKitEnvironment.prod].
  final RemoteDataKitEnvironment environment;

  /// URL base de la API (solo en [RemoteDataKitEnvironment.prod]).
  final String baseUrl;

  /// Tiempo máximo de espera de cada petición.
  final Duration timeout;

  /// Cliente HTTP propio. Pensado para tests (por ejemplo un `MockClient`).
  final http.Client? client;

  const RemoteDataKitConfig({
    this.environment = RemoteDataKitEnvironment.prod,
    this.baseUrl = 'https://rickandmortyapi.com/api',
    this.timeout = const Duration(seconds: 30),
    this.client,
  });
}
