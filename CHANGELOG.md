# Changelog

Todos los cambios relevantes de este paquete se documentan aquí.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto usa [Semantic Versioning](https://semver.org/lang/es/):

- **PATCH** (`x.y.Z`): corrección de errores sin cambiar cómo se usa el paquete.
- **MINOR** (`x.Y.0`): funcionalidad nueva compatible con la anterior.
- **MAJOR** (`X.0.0`): cambios que obligan a modificar el código de quien usa el paquete.

## [1.0.0] - 2026-11-21

Primera versión estable, extraída de la capa de datos de la app de la Fase 2.

### Agregado

- `RemoteDataKit`: punto de entrada que arma internamente el cliente HTTP y los repositorios.
- `RemoteDataKitConfig`: configuración con `environment`, `baseUrl`, `timeout` y `client`.
- `RemoteDataKitEnvironment`: `prod` (API real, por defecto) y `mock` (datos de prueba sin red).
- `kit.characters` con `searchCharacters` (paginado, con búsqueda por nombre) y `getCharacterById`.
- `CharacterEntity` con los enums `CharacterStatus` y `CharacterGender`.
- `SearchResult<T>` para resultados paginados.
- `AsyncState<T>` con `status`, `data`, `error`, `errorMessage` y los métodos `setNotStarted`, `setLoading`, `setSuccess` y `setError`.
- `AsyncStateError`: `unauthorized` (401 o 403), `notFound` (404), `invalidResponse` (5xx o JSON inválido), `noInternet`, `timeout` y `unknown`.
- Caché en memoria de los personajes ya consultados.
- Tests unitarios sin necesidad de internet.
