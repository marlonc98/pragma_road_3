import 'package:remote_data_kit/src/data/repositories/character/api/get_character_by_id_api_impl.dart';
import 'package:remote_data_kit/src/data/repositories/character/api/search_characters_api_impl.dart';
import 'package:remote_data_kit/src/data/settings/rest_api.dart';
import 'package:remote_data_kit/src/domain/core/async_state.dart';
import 'package:remote_data_kit/src/domain/core/search_result.dart';
import 'package:remote_data_kit/src/domain/entities/character_entity.dart';
import 'package:remote_data_kit/src/domain/repositories/character_repository.dart';

class CharacterRepositoryImpl extends CharacterRepository {
  static const int itemsPerPage = 20;

  final RestApi api;
  final Map<int, CharacterEntity> _cache = {};

  CharacterRepositoryImpl(this.api);

  @override
  Future<AsyncState<SearchResult<CharacterEntity>>> searchCharacters({
    required int page,
    String? query,
  }) async {
    final result = await searchCharactersApiImpl(
      api,
      page: page,
      itemsPerPage: itemsPerPage,
      query: query,
    );
    if (result.isSuccess) {
      for (final character in result.data!.data) {
        _cache[character.id] = character;
      }
    }
    return result;
  }

  @override
  Future<AsyncState<CharacterEntity>> getCharacterById(int id) async {
    final cached = _cache[id];
    if (cached != null) return AsyncState.success(data: cached);
    final result = await getCharacterByIdApiImpl(api, id);
    if (result.isSuccess) _cache[id] = result.data!;
    return result;
  }
}
