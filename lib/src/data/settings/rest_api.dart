import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:remote_data_kit/src/domain/core/async_state.dart';
import 'package:remote_data_kit/src/domain/errors/async_state_error.dart';

class RestApi {
  final String hostUrl;
  final Duration timeout;
  final String? apiKey;
  final String apiKeyHeader;
  final http.Client _client;

  /// [client] permite inyectar un cliente propio (por ejemplo un `MockClient`
  /// en los tests). Si no se pasa, se usa uno normal de `http`.
  RestApi({
    required this.hostUrl,
    this.timeout = const Duration(seconds: 30),
    this.apiKey,
    this.apiKeyHeader = 'x-api-key',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, String>> headers() async {
    return {
      "Content-Type": "application/json; charset=utf-8",
      apiKeyHeader: ?apiKey,
    };
  }

  /// Devuelve el cuerpo de la respuesta en un [AsyncState] completado, o un
  /// [AsyncState] fallido con su [AsyncStateError]. No lanza excepciones.
  Future<AsyncState<String>> get(
    String relativeUrl, {
    Map<String, String>? query,
  }) async {
    final url = Uri.parse(
      hostUrl + relativeUrl,
    ).replace(queryParameters: query == null || query.isEmpty ? null : query);
    try {
      final response = await _client
          .get(url, headers: await headers())
          .timeout(timeout);
      final code = response.statusCode;
      final body = response.body.isEmpty ? null : response.body;
      if (code >= 200 && code <= 299) {
        return AsyncState.success(data: response.body);
      }
      final AsyncStateError error = switch (code) {
        401 => AsyncStateError.unauthorized,
        403 => AsyncStateError.invalidApiKey,
        404 => AsyncStateError.notFound,
        >= 500 => AsyncStateError.invalidResponse,
        _ => AsyncStateError.unknown,
      };
      return AsyncState.fromError(error, message: body ?? 'HTTP $code');
    } on TimeoutException catch (error) {
      return AsyncState.fromError(error);
    } on http.ClientException catch (error) {
      // `http` envuelve los SocketException en ClientException.
      return AsyncState.fromError(
        AsyncStateError.noInternet,
        message: error.message,
      );
    } catch (error) {
      return AsyncState.fromError(error);
    }
  }
}
