import 'dart:async';

import 'package:remote_data_kit/src/domain/errors/async_state_error.dart';

enum PetitionStatus { notStarted, loading, complete, failed }

class AsyncState<T> {
  PetitionStatus status;
  T? data;

  /// Qué pasó. La app lo usa para decidir qué mostrar.
  AsyncStateError? error;

  /// Detalle opcional del error, por ejemplo el texto que devolvió el servidor
  /// o el mensaje de la excepción original. Útil para logs o depuración.
  String? errorMessage;

  AsyncState({
    this.status = PetitionStatus.loading,
    this.data,
    this.error,
    this.errorMessage,
  });

  AsyncState.notStarted() : status = PetitionStatus.notStarted;

  factory AsyncState.success({T? data}) {
    return AsyncState(status: PetitionStatus.complete, data: data);
  }

  factory AsyncState.loading() {
    return AsyncState(status: PetitionStatus.loading);
  }

  /// Convierte cualquier error en un [AsyncStateError].
  ///
  /// Si [error] ya es un [AsyncStateError] se usa tal cual. Los errores de red
  /// (`noInternet`) los asigna la capa data, que es la que conoce `http`.
  ///
  /// [message] se guarda en [errorMessage]. Si no se pasa y [error] no es un
  /// [AsyncStateError], se usa `error.toString()`.
  factory AsyncState.fromError(
    Object error, {
    AsyncStateError defaultError = AsyncStateError.unknown,
    String? message,
  }) {
    final AsyncStateError errorGetted = switch (error) {
      AsyncStateError() => error,
      TimeoutException() => AsyncStateError.timeout,
      FormatException() || TypeError() => AsyncStateError.invalidResponse,
      _ => defaultError,
    };
    return AsyncState(
      status: PetitionStatus.failed,
      error: errorGetted,
      errorMessage:
          message ?? (error is AsyncStateError ? null : error.toString()),
    );
  }

  bool get isSuccess => status == PetitionStatus.complete;
  bool get isError => status == PetitionStatus.failed;
  bool get isLoading => status == PetitionStatus.loading;
  bool get isNotStarted => status == PetitionStatus.notStarted;

  /// Vuelve al estado inicial: sin datos ni error.
  AsyncState<T> setNotStarted() {
    return AsyncState<T>(status: PetitionStatus.notStarted);
  }

  /// Pasa a cargando y borra los datos y el error anteriores.
  AsyncState<T> setLoading() {
    return AsyncState<T>(status: PetitionStatus.loading);
  }

  /// Pasa a completado con [data] y borra el error anterior.
  AsyncState<T> setSuccess(T? data) {
    return AsyncState<T>(status: PetitionStatus.complete, data: data);
  }

  /// Pasa a fallido con su propio [error] y [message] y borra los datos.
  AsyncState<T> setError(AsyncStateError error, {String? message}) {
    return AsyncState<T>(
      status: PetitionStatus.failed,
      error: error,
      errorMessage: message,
    );
  }

  @override
  String toString() {
    return 'AsyncState{status: $status, data: $data, error: $error, errorMessage: $errorMessage}';
  }

  AsyncState<T> copyWith({
    PetitionStatus? status,
    T? data,
    AsyncStateError? error,
    String? errorMessage,
  }) {
    return AsyncState<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  AsyncState<R> map<R>(R Function(T) transform) {
    if (isError) {
      return AsyncState<R>(
        status: status,
        error: error,
        errorMessage: errorMessage,
      );
    }
    return AsyncState<R>(
      status: status,
      data: data != null ? transform(data as T) : null,
      error: error,
      errorMessage: errorMessage,
    );
  }
}
