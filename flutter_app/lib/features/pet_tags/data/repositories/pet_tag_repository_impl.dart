import '../../domain/entities/pet_tag.dart';
import '../../domain/repositories/pet_tag_repository.dart';
import '../datasources/pet_tag_remote_datasource.dart';

class PetTagRepositoryImpl implements PetTagRepository {
  PetTagRepositoryImpl(this._dataSource, this._tokenAccessor);

  final PetTagRemoteDataSource _dataSource;
  final String Function() _tokenAccessor;

  String get _token => _tokenAccessor();

  @override
  Future<List<PetTag>> listTags() async {
    final models = await _dataSource.listTags(_token);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<PetTag> createTag(String name) async {
    final model = await _dataSource.createTag(_token, name);
    return model.toEntity();
  }

  @override
  Future<PetTag> renameTag(String tagId, String name) async {
    final model = await _dataSource.renameTag(_token, tagId, name);
    return model.toEntity();
  }

  @override
  Future<void> deleteTag(String tagId) async {
    await _dataSource.deleteTag(_token, tagId);
  }

  @override
  Future<void> assignTag(String petId, String tagId) async {
    await _dataSource.assignTag(_token, petId, tagId);
  }

  @override
  Future<void> unassignTag(String petId, String tagId) async {
    await _dataSource.unassignTag(_token, petId, tagId);
  }
}
