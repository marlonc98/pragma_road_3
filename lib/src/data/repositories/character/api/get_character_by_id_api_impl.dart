import 'dart:convert';

import 'package:remote_data_kit/src/data/dtos/character_dto.dart';
import 'package:remote_data_kit/src/data/settings/rest_api.dart';
import 'package:remote_data_kit/src/domain/core/async_state.dart';
import 'package:remote_data_kit/src/domain/entities/character_entity.dart';

Future<AsyncState<CharacterEntity>> getCharacterByIdApiImpl(
  RestApi api,
  int id,
) async {
  final response = await api.get('/character/$id');
  if (response.isError) {
    return AsyncState.fromError(
      response.error!,
      message: response.errorMessage,
    );
  }
  try {
    return AsyncState.success(
      data: CharacterDto.fromJSON(jsonDecode(response.data!)),
    );
  } catch (error) {
    return AsyncState.fromError(error);
  }
}
