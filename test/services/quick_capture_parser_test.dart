import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/contact.dart';
import 'package:kongo/services/quick_capture_parser.dart';

void main() {
  late QuickCaptureParser parser;

  setUp(() {
    parser = QuickCaptureParser();
  });

  // ──────────────────── 辅助方法 ────────────────────

  Contact makeContact(String name) => Contact(
        id: 'id-$name',
        name: name,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

  // ──────────────────── fuzzy match（已有联系人）────────────────────

  group('exact match against existing contacts', () {
    test('input contains contact name, direct hit, noteType = structured', () {
      final contacts = [makeContact('张三'), makeContact('李四')];
      final result = parser.parse('今天见了张三，聊了Q2预算', contacts);

      expect(result.noteType, QuickNoteType.structured);
      expect(result.matchedContact?.name, '张三');
      expect(result.matchConfidence, 1.0);
      expect(result.candidateNewName, isNull);
    });

    test('input exactly equal to contact name also matches', () {
      final contacts = [makeContact('张三')];
      final result = parser.parse('张三', contacts);

      expect(result.noteType, QuickNoteType.structured);
      expect(result.matchedContact?.name, '张三');
    });

    test('multiple contacts in input, returns first found exact match', () {
      final contacts = [makeContact('张三'), makeContact('李四')];
      final result = parser.parse('张三和李四都到了', contacts);

      // 两者都精确命中，取其中一个即可（不测试顺序）
      expect(result.noteType, QuickNoteType.structured);
      expect(result.matchConfidence, 1.0);
    });

    test('English contact name exact match', () {
      final contacts = [makeContact('Alice Chen')];
      final result = parser.parse('Met Alice Chen today for lunch', contacts);

      expect(result.noteType, QuickNoteType.structured);
      expect(result.matchedContact?.name, 'Alice Chen');
    });
  });

  group('edit distance 1 fuzzy match', () {
    test('input with one differing character fuzzy-matches at 0.8 score', () {
      final contacts = [makeContact('张伟')];
      // "张为" → 编辑距离1 与 "张伟" 相同
      final result = parser.parse('今天见了张为，讨论了合同条款', contacts);

      expect(result.noteType, QuickNoteType.structured);
      expect(result.matchedContact?.name, '张伟');
      expect(result.matchConfidence, 0.8);
    });
  });

  // ──────────────────── 无联系人命中 → 启发式提取 ────────────────────

  group('heuristic extraction of Chinese names when contact list is empty', () {
    test('two-character Chinese name in input returns candidateNewName', () {
      final result = parser.parse('今天见了张伟，聊了Q2预算', []);

      expect(result.noteType, QuickNoteType.knowledge);
      expect(result.matchedContact, isNull);
      expect(result.candidateNewName, '张伟');
    });

    test('three-character Chinese name is also recognized', () {
      final result = parser.parse('刚开完和陈小明的会', []);
      expect(result.candidateNewName, '陈小明');
    });

    test('stopwords like "今天" are not treated as candidate names', () {
      final result = parser.parse('今天很忙，完成了很多工作，继续努力', []);

      expect(result.noteType, QuickNoteType.knowledge);
      expect(result.candidateNewName, isNull);
    });

    test('stopwords like "会议" are not treated as candidate names', () {
      final result = parser.parse('会议结束了', []);
      expect(result.candidateNewName, isNull);
    });
  });

  group('heuristic extraction of English names', () {
    test('title-case word sequence is recognized as candidate name', () {
      final result = parser.parse('Met David Chen today for catch-up', []);

      expect(result.noteType, QuickNoteType.knowledge);
      expect(result.candidateNewName, 'David Chen');
    });

    test('single title-case word is also recognized', () {
      final result = parser.parse('Talked with Sarah about Q3 roadmap', []);
      expect(result.candidateNewName, 'Sarah');
    });
  });

  group('pure content with no person name', () {
    test('pure technical content, candidateNewName is null', () {
      final result = parser.parse('CloudKit 单条记录上限 10MB', []);

      expect(result.noteType, QuickNoteType.knowledge);
      expect(result.candidateNewName, isNull);
      expect(result.matchedContact, isNull);
    });

    test('all-lowercase English phrase is not recognized as a name', () {
      final result = parser.parse('flutter build macos done', []);
      expect(result.candidateNewName, isNull);
    });
  });

  group('contact list non-empty but input contains no matching contact', () {
    test('unknown name in input falls back to candidateNewName', () {
      final contacts = [makeContact('张三'), makeContact('李四')];
      final result = parser.parse('今天见了王伟，讨论了新合同', contacts);

      expect(result.noteType, QuickNoteType.knowledge);
      expect(result.matchedContact, isNull);
      expect(result.candidateNewName, '王伟');
    });
  });

  group('noteContent is always the trimmed raw input', () {
    test('noteContent matches trimmed input', () {
      final result = parser.parse('  今天见了张三  ', [makeContact('张三')]);
      expect(result.noteContent, '今天见了张三');
    });
  });
}
