import 'package:remote_data_kit/src/domain/core/async_state.dart';
import 'package:remote_data_kit/src/domain/core/search_result.dart';
import 'package:remote_data_kit/src/domain/entities/character_entity.dart';

/// Los métodos no lanzan: si fallan devuelven un [AsyncState] con
/// `status == PetitionStatus.failed` y un [AsyncStateError] en `error`.
abstract class CharacterRepository {
  Future<AsyncState<SearchResult<CharacterEntity>>> searchCharacters({
    required int page,
    String? query,
  });

  Future<AsyncState<CharacterEntity>> getCharacterById(int id);
}
