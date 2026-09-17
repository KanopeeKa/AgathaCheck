import '../entities/pet_tag.dart';

abstract class PetTagRepository {
  Future<List<PetTag>> listTags();
  Future<PetTag> createTag(String name);
  Future<PetTag> renameTag(String tagId, String name);
  Future<void> deleteTag(String tagId);
  Future<void> assignTag(String petId, String tagId);
  Future<void> unassignTag(String petId, String tagId);
}
