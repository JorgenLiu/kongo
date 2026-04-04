import '../repositories/info_tag_repository.dart';

abstract class InfoTagService {
  /// 遍历 names，对每个 name findOrCreate 并关联到 contactId。
  /// 空列表或空字符串直接跳过。
  Future<void> applyTagsToContact(String contactId, List<String> names);
}

class DefaultInfoTagService implements InfoTagService {
  final InfoTagRepository _infoTagRepository;

  DefaultInfoTagService(this._infoTagRepository);

  @override
  Future<void> applyTagsToContact(String contactId, List<String> names) async {
    final trimmed = names.map((n) => n.trim()).where((n) => n.isNotEmpty).toSet();
    if (trimmed.isEmpty) return;
    for (final name in trimmed) {
      final tag = await _infoTagRepository.findOrCreate(name);
      await _infoTagRepository.addToContact(contactId, tag.id, source: 'ai');
    }
  }
}
