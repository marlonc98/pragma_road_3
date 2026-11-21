import 'dart:convert';

import 'package:remote_data_kit/src/data/dtos/character_dto.dart';
import 'package:remote_data_kit/src/data/settings/rest_api.dart';
import 'package:remote_data_kit/src/domain/core/async_state.dart';
import 'package:remote_data_kit/src/domain/core/search_result.dart';
import 'package:remote_data_kit/src/domain/entities/character_entity.dart';
import 'package:remote_data_kit/src/domain/errors/async_state_error.dart';

Future<AsyncState<SearchResult<CharacterEntity>>> searchCharactersApiImpl(
  RestApi api, {
  required int page,
  required int itemsPerPage,
  String? query,
}) async {
  final response = await api.get(
    '/character',
    query: {
      'page': '$page',
      if (query != null && query.isNotEmpty) 'name': query,
    },
  );
  if (response.isError) {
    // La API responde 404 cuando la búsqueda no tiene resultados.
    if (response.error == AsyncStateError.notFound) {
      return AsyncState.success(
        data: SearchResult.empty(currentPage: page, itemsPerPage: itemsPerPage),
      );
    }
    return AsyncState.fromError(
      response.error!,
      message: response.errorMessage,
    );
  }
  try {
    final Map<String, dynamic> json = jsonDecode(response.data!);
    final List<dynamic> results = json['results'] ?? [];
    return AsyncState.success(
      data: SearchResult(
        currentPage: page,
        totalItems: json['info']?['count'] ?? results.length,
        data: results.map((item) => CharacterDto.fromJSON(item)).toList(),
        itemsPerPage: itemsPerPage,
        lastpage: json['info']?['pages'] ?? page,
      ),
    );
  } catch (error) {
    return AsyncState.fromError(error);
  }
}
