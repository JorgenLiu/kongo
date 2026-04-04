import 'ner_service.dart';
import 'quick_capture_parser.dart';

/// 基于 Dart 正则启发式的 NER 降级实现。
///
/// 直接复用 [QuickCaptureParser.extractCandidateName] 的逻辑。
/// 用于无原生 NER 能力的平台（如 Windows）。
class RegexFallbackNerService implements NerService {
  @override
  Future<List<String>> extractPersonNames(String text) async {
    final name = QuickCaptureParser.extractCandidateName(text);
    return name != null ? [name] : [];
  }
}
