# remote_data_kit

Paquete Flutter para consultar la [API de Rick and Morty](https://rickandmortyapi.com) sin escribir código HTTP ni parsear JSON.

Se configura una sola vez y devuelve modelos listos para usar, con un manejo de errores simple y tipado.

## Características

- **Cliente HTTP listo**: URL, headers, API key y timeout se configuran en un solo objeto.
- **Modelos tipados**: `CharacterEntity` con enums para estado y género, y `SearchResult<T>` para paginación.
- **Errores como enum**: `AsyncStateError` indica qué pasó y la app decide qué mensaje mostrar.
- **No lanza excepciones**: todos los métodos devuelven un `AsyncState<T>`.
- **Modo `mock`**: datos de prueba internos para trabajar sin internet.
- **Sin dependencias de estado**: no obliga a usar Riverpod, Bloc ni Provider. La única dependencia es `http`.
- **Caché en memoria**: un personaje ya cargado no se vuelve a pedir.

## Instalación

Agrega el paquete en el `pubspec.yaml` de tu app, apuntando a una versión (tag):

```yaml
dependencies:
  remote_data_kit:
    git:
      url: https://github.com/marlonc98/pragma_road_3.git
      ref: v1.0.0
```

> El repositorio se llama `pragma_road_3`, pero el paquete se llama `remote_data_kit`: ese es el nombre que va en `dependencies` y en los `import`.

Luego ejecuta:

```bash
flutter pub get
```

## Uso rápido

```dart
import 'package:remote_data_kit/remote_data_kit.dart';

final kit = RemoteDataKit();

final state = await kit.characters.searchCharacters(page: 1, query: 'rick');

if (state.isSuccess) {
  for (final character in state.data!.data) {
    print('${character.name} - ${character.status}');
  }
} else if (state.isError) {
  print('Falló: ${state.error}');
}
```

## Configuración

Toda la configuración va en `RemoteDataKitConfig`. Todos los valores son opcionales:

```dart
final kit = RemoteDataKit(
  config: RemoteDataKitConfig(
    environment: RemoteDataKitEnvironment.prod,
    apiKey: 'mi-api-key',
    apiKeyHeader: 'Authorization',
    timeout: Duration(seconds: 10),
  ),
);
```

| Parámetro | Por defecto | Descripción |
|---|---|---|
| `environment` | `prod` | `prod` consulta la API real; `mock` usa datos de prueba internos, sin red. |
| `baseUrl` | `https://rickandmortyapi.com/api` | URL base de la API (solo en `prod`). |
| `apiKey` | `null` | Se envía en cada petición. Si es `null`, no se envía ningún header. |
| `apiKeyHeader` | `x-api-key` | Nombre del header en el que viaja la `apiKey`. |
| `timeout` | `30 s` | Tiempo máximo de espera por petición. |
| `client` | `null` | Cliente `http` propio, pensado para tests (por ejemplo, `MockClient`). |

> **No escribas la API key en el código.** Pásala al compilar con `--dart-define=API_KEY=...` y léela con `const String.fromEnvironment('API_KEY')`.

## Consultas disponibles

Todas están en `kit.characters`, que implementa el contrato `CharacterRepository`:

| Método | Devuelve | Descripción |
|---|---|---|
| `searchCharacters({required int page, String? query})` | `AsyncState<SearchResult<CharacterEntity>>` | Lista paginada (20 por página). Si `query` no tiene resultados, devuelve un `SearchResult` vacío, no un error. |
| `getCharacterById(int id)` | `AsyncState<CharacterEntity>` | Un personaje por id. Si no existe, devuelve el error `notFound`. |

### `CharacterEntity`

| Campo | Tipo |
|---|---|
| `id` | `int` |
| `name` | `String` |
| `status` | `CharacterStatus` (`alive`, `dead`, `unknown`) |
| `species` | `String` |
| `type` | `String?` (`hasType` indica si tiene un valor) |
| `gender` | `CharacterGender` (`female`, `male`, `genderless`, `unknown`) |
| `image` | `String` (URL) |
| `originName` | `String?` |
| `locationName` | `String?` |
| `episodesCount` | `int` |

### `SearchResult<T>`

`currentPage`, `totalItems`, `data` (`List<T>`), `itemsPerPage`, `lastpage` e `isEmpty`.

## Manejo de estados y errores

Cada consulta devuelve un `AsyncState<T>`:

| Propiedad | Descripción |
|---|---|
| `status` | `PetitionStatus`: `notStarted`, `loading`, `complete` o `failed`. |
| `data` | El resultado, si la petición salió bien. |
| `error` | Un `AsyncStateError` que indica qué pasó. |
| `errorMessage` | Detalle opcional (texto del servidor o de la excepción). Úsalo para logs, no para mostrarlo al usuario. |
| `isSuccess`, `isError`, `isLoading`, `isNotStarted` | Atajos para revisar `status`. |

Para cambiar de estado en tu vista, usa `setNotStarted()`, `setLoading()`, `setSuccess(data)` y `setError(error, message:)`. Cada uno devuelve un estado nuevo y limpio, sin arrastrar datos ni errores del anterior.

> `copyWith` no permite borrar `error` ni `errorMessage`. Para cambiar de estado, usa los métodos `set...`.

### Errores posibles

| `AsyncStateError` | Cuándo ocurre |
|---|---|
| `unauthorized` | La API respondió **401**. |
| `invalidApiKey` | La API respondió **403**: la API key no existe, expiró o no tiene permisos. |
| `notFound` | La API respondió **404**. |
| `invalidResponse` | La API respondió **5xx**, o el JSON no tiene el formato esperado. |
| `noInternet` | No hay conexión o no se pudo llegar al servidor. |
| `timeout` | La petición superó el `timeout`. |
| `unknown` | Cualquier otro caso. |

El paquete no traduce ni muestra textos. La app decide el mensaje:

```dart
String messageFor(AsyncStateError error) => switch (error) {
  AsyncStateError.noInternet => 'Revisa tu conexión a internet',
  AsyncStateError.timeout => 'El servidor tardó demasiado',
  AsyncStateError.notFound => 'No encontramos lo que buscabas',
  AsyncStateError.unauthorized ||
  AsyncStateError.invalidApiKey => 'No tienes acceso',
  AsyncStateError.invalidResponse ||
  AsyncStateError.unknown => 'Algo salió mal, intenta de nuevo',
};
```

Como el `switch` es exhaustivo, si una versión futura agrega un error nuevo, tu app no compila hasta que lo manejes.

## Uso con Riverpod

Crea el kit una sola vez en un provider. El resto de la app no necesita conocer la API key:

```dart
final remoteDataKitProvider = Provider<RemoteDataKit>(
  (ref) => RemoteDataKit(
    config: RemoteDataKitConfig(
      environment: RemoteDataKitEnvironment.prod,
      apiKey: const String.fromEnvironment('API_KEY'),
    ),
  ),
);

final characterRepositoryProvider = Provider<CharacterRepository>(
  (ref) => ref.watch(remoteDataKitProvider).characters,
);
```

En tests, reemplaza el provider con `RemoteDataKitEnvironment.mock` usando `overrides`.

## Desarrollo y pruebas

Requisitos: Flutter con Dart `^3.13.5` (probado con Flutter 3.47.7).

```bash
git clone https://github.com/marlonc98/pragma_road_3.git
```

```bash
cd pragma_road_3
```

```bash
flutter pub get
```

```bash
flutter analyze
```

```bash
flutter test
```

Los tests no necesitan internet: usan un `MockClient` de `http` y el modo `mock`.

### Estructura

```
lib/
  remote_data_kit.dart          ← API pública (lo único que se importa)
  src/
    remote_data_kit.dart        ← RemoteDataKit: arma todo a partir del config
    remote_data_kit_config.dart ← RemoteDataKitConfig y RemoteDataKitEnvironment
    domain/                     ← QUÉ ofrece el paquete (sin HTTP ni JSON)
      core/                     ← AsyncState, SearchResult
      entities/                 ← CharacterEntity
      errors/                   ← AsyncStateError
      repositories/             ← contrato CharacterRepository
    data/                       ← CÓMO obtiene los datos
      settings/                 ← RestApi (cliente HTTP)
      dtos/                     ← JSON → entidad
      repositories/             ← implementación real y mock
```

Todo lo que está en `src/` es interno. Importa siempre desde `package:remote_data_kit/remote_data_kit.dart`.

## Versionamiento

El paquete sigue [Semantic Versioning](https://semver.org/lang/es/) con el formato `MAJOR.MINOR.PATCH`:

| Tipo | Ejemplo | Cuándo se usa |
|---|---|---|
| **PATCH** | `1.0.0` → `1.0.1` | Se corrige un error sin cambiar cómo se usa el paquete. |
| **MINOR** | `1.0.1` → `1.1.0` | Se agrega algo nuevo y lo anterior sigue funcionando igual. |
| **MAJOR** | `1.1.0` → `2.0.0` | Hay un cambio que obliga a modificar el código de quien lo usa. Incluye agregar un valor a `AsyncStateError`, porque rompe los `switch` exhaustivos. |

Cada versión:

1. Actualiza `version` en `pubspec.yaml`.
2. Se documenta en [`CHANGELOG.md`](CHANGELOG.md).
3. Se marca con un tag de git (`v1.0.1`), que es lo que se usa como `ref` al instalar.

## Licencia

MIT. Ver [LICENSE](LICENSE).
