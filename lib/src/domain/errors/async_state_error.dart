/// Errores que puede devolver el paquete en [AsyncState.error].
///
/// El paquete solo indica qué pasó; la app decide qué mensaje mostrar.
enum AsyncStateError {
  /// La API respondió 401 o 403: falta autenticación o no hay permisos.
  unauthorized,

  /// No hay conexión a internet o no se pudo llegar al servidor.
  noInternet,

  /// La petición tardó más que el tiempo límite.
  timeout,

  /// La API respondió 404: el recurso no existe.
  notFound,

  /// La API respondió algo que no se puede usar: un error del servidor (5xx),
  /// un JSON mal formado o con una estructura distinta a la esperada.
  invalidResponse,

  /// Cualquier otro error no contemplado.
  unknown,
}
