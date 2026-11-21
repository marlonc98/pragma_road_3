import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:remote_data_kit/remote_data_kit.dart';
import 'package:remote_data_kit/src/data/repositories/character/character_repository_mock.dart';
import 'package:remote_data_kit/src/data/settings/rest_api.dart';

Map<String, dynamic> _characterJson(int id) => {
  'id': id,
  'name': 'Rick Sanchez',
  'status': 'Alive',
  'species': 'Human',
  'type': '',
  'gender': 'Male',
  'image': 'https://rickandmortyapi.com/api/character/avatar/$id.jpeg',
  'origin': {'name': 'Earth (C-137)'},
  'location': {'name': 'unknown'},
  'episode': ['e1', 'e2'],
};

MockClient _client(int statusCode, String body, {List<http.Request>? calls}) {
  return MockClient((request) async {
    calls?.add(request);
    return http.Response(body, statusCode);
  });
}

RestApi _api(int statusCode, String body) =>
    RestApi(hostUrl: 'https://test.api', client: _client(statusCode, body));

CharacterRepository _characters(
  int statusCode,
  String body, {
  List<http.Request>? calls,
}) {
  return RemoteDataKit(
    config: RemoteDataKitConfig(
      client: _client(statusCode, body, calls: calls),
    ),
  ).characters;
}

void main() {
  group('RestApi', () {
    Future<AsyncStateError?> errorFor(int code) async =>
        (await _api(code, 'detalle').get('/x')).error;

    test('2xx devuelve el cuerpo', () async {
      final state = await _api(200, 'ok').get('/x');
      expect(state.isSuccess, true);
      expect(state.data, 'ok');
    });

    test('asigna cada código HTTP a su error', () async {
      expect(await errorFor(401), AsyncStateError.unauthorized);
      expect(await errorFor(403), AsyncStateError.invalidApiKey);
      expect(await errorFor(404), AsyncStateError.notFound);
      expect(await errorFor(500), AsyncStateError.invalidResponse);
      expect(await errorFor(418), AsyncStateError.unknown);
    });

    test('guarda el cuerpo del error en errorMessage', () async {
      final state = await _api(500, 'Server down').get('/x');
      expect(state.errorMessage, 'Server down');
    });

    test('ClientException se convierte en noInternet', () async {
      final api = RestApi(
        hostUrl: 'https://test.api',
        client: MockClient((_) => throw http.ClientException('sin red')),
      );
      final state = await api.get('/x');
      expect(state.error, AsyncStateError.noInternet);
    });

    test('un timeout se convierte en timeout', () async {
      final api = RestApi(
        hostUrl: 'https://test.api',
        timeout: const Duration(milliseconds: 10),
        client: MockClient((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return http.Response('tarde', 200);
        }),
      );
      final state = await api.get('/x');
      expect(state.error, AsyncStateError.timeout);
    });
  });

  group('CharacterRepositoryImpl (vía RemoteDataKit)', () {
    test('searchCharacters convierte la respuesta', () async {
      final calls = <http.Request>[];
      final repository = _characters(
        200,
        jsonEncode({
          'info': {'count': 1, 'pages': 1},
          'results': [_characterJson(1)],
        }),
        calls: calls,
      );
      final state = await repository.searchCharacters(page: 1, query: 'rick');
      expect(state.isSuccess, true);
      expect(state.data!.totalItems, 1);
      final character = state.data!.data.first;
      expect(character.name, 'Rick Sanchez');
      expect(character.status, CharacterStatus.alive);
      expect(character.locationName, isNull);
      expect(character.episodesCount, 2);
      expect(calls.single.url.queryParameters, {'page': '1', 'name': 'rick'});
    });

    test('searchCharacters con 404 devuelve un resultado vacío', () async {
      final state = await _characters(
        404,
        '',
      ).searchCharacters(page: 1, query: 'zzz');
      expect(state.isSuccess, true);
      expect(state.data!.isEmpty, true);
    });

    test('getCharacterById con 404 devuelve notFound', () async {
      final state = await _characters(404, '').getCharacterById(999);
      expect(state.error, AsyncStateError.notFound);
    });

    test('un JSON roto devuelve invalidResponse', () async {
      final state = await _characters(200, '{no es json').getCharacterById(1);
      expect(state.error, AsyncStateError.invalidResponse);
    });

    test('getCharacterById usa la caché', () async {
      final calls = <http.Request>[];
      final repository = _characters(
        200,
        jsonEncode(_characterJson(1)),
        calls: calls,
      );
      await repository.getCharacterById(1);
      final state = await repository.getCharacterById(1);
      expect(state.data!.id, 1);
      expect(calls, hasLength(1));
    });
  });

  group('RemoteDataKitConfig', () {
    test('por defecto usa prod y la URL de Rick and Morty', () async {
      const config = RemoteDataKitConfig();
      expect(config.environment, RemoteDataKitEnvironment.prod);
      final calls = <http.Request>[];
      await _characters(
        200,
        jsonEncode(_characterJson(1)),
        calls: calls,
      ).getCharacterById(1);
      expect(
        calls.single.url.toString(),
        'https://rickandmortyapi.com/api/character/1',
      );
    });

    test('envía la apiKey en el header configurado', () async {
      final calls = <http.Request>[];
      final kit = RemoteDataKit(
        config: RemoteDataKitConfig(
          apiKey: 'secreta',
          apiKeyHeader: 'Authorization',
          client: _client(200, jsonEncode(_characterJson(1)), calls: calls),
        ),
      );
      await kit.characters.getCharacterById(1);
      expect(calls.single.headers['Authorization'], 'secreta');
    });

    test('sin apiKey no envía el header', () async {
      final calls = <http.Request>[];
      await _characters(
        200,
        jsonEncode(_characterJson(1)),
        calls: calls,
      ).getCharacterById(1);
      expect(calls.single.headers.containsKey('x-api-key'), false);
    });

    test('environment mock usa datos de prueba sin llamar a la red', () async {
      final calls = <http.Request>[];
      final kit = RemoteDataKit(
        config: RemoteDataKitConfig(
          environment: RemoteDataKitEnvironment.mock,
          client: _client(500, '', calls: calls),
        ),
      );
      final state = await kit.characters.getCharacterById(1);
      expect(state.data!.name, 'Rick Sanchez');
      expect(calls, isEmpty);
    });
  });

  group('CharacterRepositoryMock', () {
    test('filtra por nombre', () async {
      final state = await CharacterRepositoryMock().searchCharacters(
        page: 1,
        query: 'meeseeks',
      );
      expect(state.data!.data.single.name, 'Mr. Meeseeks');
    });

    test('id inexistente devuelve notFound', () async {
      final state = await CharacterRepositoryMock().getCharacterById(-1);
      expect(state.error, AsyncStateError.notFound);
    });
  });
}
