import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:remote_data_kit/remote_data_kit.dart';

void main() {
  group('AsyncState', () {
    test('success guarda los datos', () {
      final state = AsyncState<int>.success(data: 5);
      expect(state.isSuccess, true);
      expect(state.data, 5);
    });

    test('fromError respeta un AsyncStateError', () {
      final state = AsyncState<int>.fromError(AsyncStateError.notFound);
      expect(state.isError, true);
      expect(state.error, AsyncStateError.notFound);
    });

    test('fromError convierte TimeoutException en timeout', () {
      final state = AsyncState<int>.fromError(TimeoutException('lento'));
      expect(state.error, AsyncStateError.timeout);
    });

    test('fromError convierte FormatException en invalidResponse', () {
      final state = AsyncState<int>.fromError(const FormatException('json'));
      expect(state.error, AsyncStateError.invalidResponse);
    });

    test('fromError usa defaultError con errores desconocidos', () {
      expect(
        AsyncState<int>.fromError(Exception('x')).error,
        AsyncStateError.unknown,
      );
      expect(
        AsyncState<int>.fromError(
          Exception('x'),
          defaultError: AsyncStateError.invalidResponse,
        ).error,
        AsyncStateError.invalidResponse,
      );
    });

    test('fromError guarda el mensaje que se le pasa', () {
      final state = AsyncState<int>.fromError(
        AsyncStateError.unauthorized,
        message: 'El usuario está bloqueado',
      );
      expect(state.error, AsyncStateError.unauthorized);
      expect(state.errorMessage, 'El usuario está bloqueado');
    });

    test('fromError sin mensaje usa el texto de la excepción', () {
      expect(
        AsyncState<int>.fromError(AsyncStateError.notFound).errorMessage,
        isNull,
      );
      expect(
        AsyncState<int>.fromError(const FormatException('json roto'))
            .errorMessage,
        contains('json roto'),
      );
    });

    test('map conserva error y errorMessage', () {
      final state = AsyncState<int>.fromError(
        AsyncStateError.timeout,
        message: 'detalle',
      ).map((value) => '$value');
      expect(state.error, AsyncStateError.timeout);
      expect(state.errorMessage, 'detalle');
    });

    test('setLoading borra datos y error', () {
      final AsyncState<int> state = AsyncState<int>(data: 1)
          .setError(AsyncStateError.timeout, message: 'lento')
          .setLoading();
      expect(state.isLoading, true);
      expect(state.data, isNull);
      expect(state.error, isNull);
      expect(state.errorMessage, isNull);
    });

    test('setSuccess reemplaza los datos y borra el error', () {
      final state = AsyncState<int>.fromError(AsyncStateError.notFound)
          .setSuccess(7);
      expect(state.isSuccess, true);
      expect(state.data, 7);
      expect(state.error, isNull);
    });

    test('setError reemplaza el error anterior', () {
      final state = AsyncState<int>.fromError(
        AsyncStateError.timeout,
        message: 'viejo',
      ).setError(AsyncStateError.noInternet);
      expect(state.isError, true);
      expect(state.error, AsyncStateError.noInternet);
      expect(state.errorMessage, isNull);
    });

    test('setError borra los datos', () {
      final state = AsyncState<int>.success(data: 9)
          .setError(AsyncStateError.timeout);
      expect(state.isError, true);
      expect(state.data, isNull);
    });

    test('setNotStarted limpia todo', () {
      final state = AsyncState<int>.success(data: 3).setNotStarted();
      expect(state.isNotStarted, true);
      expect(state.data, isNull);
      expect(state.error, isNull);
    });
  });

  group('CharacterEntity', () {
    test('usa valores por defecto', () {
      final character = CharacterEntity(id: 1, name: 'Rick', image: '');
      expect(character.status, CharacterStatus.unknown);
      expect(character.gender, CharacterGender.unknown);
      expect(character.episodesCount, 0);
    });

    test('hasType ignora espacios en blanco', () {
      expect(
        CharacterEntity(id: 1, name: 'a', image: '', type: '  ').hasType,
        false,
      );
      expect(
        CharacterEntity(id: 1, name: 'a', image: '', type: 'Meeseeks').hasType,
        true,
      );
    });
  });

  group('SearchResult', () {
    test('empty no tiene datos', () {
      final result = SearchResult<int>.empty(currentPage: 1);
      expect(result.isEmpty, true);
      expect(result.currentPage, 1);
    });
  });
}
