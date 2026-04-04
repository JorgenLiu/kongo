/// 命名实体识别（NER）服务抽象接口。
///
/// 实现层级：
///   - macOS/iOS：通过 MethodChannel 调用原生 NLTagger（PlatformNerService）
///   - Windows/其他：Dart 正则启发式提取（RegexFallbackNerService）
abstract class NerService {
  /// 从文本中提取候选人名列表。
  ///
  /// 返回结果按置信度降序排列。空列表表示未识别到人名。
  Future<List<String>> extractPersonNames(String text);
}
