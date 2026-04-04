import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/services/regex_fallback_ner_service.dart';

void main() {
  late RegexFallbackNerService service;

  setUp(() {
    service = RegexFallbackNerService();
  });

  group('RegexFallbackNerService', () {
    test('extracts Chinese name from trigger context', () async {
      final names = await service.extractPersonNames('今天见了张伟，聊了预算');
      expect(names, ['张伟']);
    });

    test('extracts English name from mid-sentence', () async {
      final names = await service.extractPersonNames('Met David Chen today');
      expect(names, ['David Chen']);
    });

    test('returns empty list when no name detected', () async {
      final names = await service.extractPersonNames('flutter build done');
      expect(names, isEmpty);
    });

    test('extracts compound surname name', () async {
      final names = await service.extractPersonNames('昨天见了欧阳明华');
      expect(names, ['欧阳明华']);
    });
  });
}
