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
    test('2-char names with only 1 char matching do NOT fuzzy-match (prevents false surname matches)', () {
      final contacts = [makeContact('张伟')];
      // "张为" shares only the surname with "张伟" — too risky for 2-char names,
      // so we require both chars to match (samePos >= 2). No structured hit.
      final result = parser.parse('今天见了张为，讨论了合同条款', contacts);

      expect(result.matchedContact, isNull);
      expect(result.noteType, QuickNoteType.knowledge);
    });

    test('bigram dice does not false-match unrelated 2-char substring', () {
      final contacts = [makeContact('张伟')];
      // "项目" 与 "张伟" bigram dice = 0，不应命中
      final result = parser.parse('今天讨论了项目进展', contacts);

      expect(result.matchedContact, isNull);
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

    test('four-character compound surname name is recognized', () {
      final result = parser.parse('昨天见了欧阳明华', []);
      expect(result.candidateNewName, '欧阳明华');
    });

    test('four-character non-compound-surname truncated to 3 chars', () {
      final result = parser.parse('今天见了陈大明哥', []);
      expect(result.candidateNewName, '陈大明');
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

  group('expanded trigger words', () {
    test('打电话给 triggers name extraction', () {
      final result = parser.parse('打电话给李明，问一下进度', []);
      expect(result.candidateNewName, '李明');
    });

    test('发消息给 triggers name extraction', () {
      final result = parser.parse('发消息给王磊，确认时间', []);
      expect(result.candidateNewName, '王磊');
    });

    test('聊到 triggers name extraction', () {
      final result = parser.parse('开会时聊到赵刚', []);
      expect(result.candidateNewName, '赵刚');
    });

    test('遇到 triggers name extraction', () {
      final result = parser.parse('路上遇到张华，聊了几句', []);
      expect(result.candidateNewName, '张华');
    });

    test('碰到 triggers name extraction', () {
      final result = parser.parse('下楼碰到林涛', []);
      expect(result.candidateNewName, '林涛');
    });

    test('告诉 triggers name extraction', () {
      final result = parser.parse('告诉刘洋，明天开会', []);
      expect(result.candidateNewName, '刘洋');
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

    test('sentence-start name followed by verb is extracted', () {
      final result = parser.parse('John called me about the project', []);
      expect(result.candidateNewName, 'John');
    });

    test('sentence-start full name followed by verb is extracted', () {
      final result = parser.parse('John Smith called me about the project', []);
      expect(result.candidateNewName, 'John Smith');
    });

    test('sentence-start word not followed by verb is skipped', () {
      final result = parser.parse('Meeting with the team went well', []);
      // "Meeting" is at start but "with" is not in verb list
      expect(result.candidateNewName, isNull);
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

  // ──────────────────── nerHints 支持 ────────────────────

  group('nerHints from platform NER', () {
    test('nerHints overrides regex extraction when no fuzzy match', () {
      final result = parser.parse(
        '刚才跟Alice聊了项目',
        [],
        nerHints: ['Alice'],
      );

      expect(result.noteType, QuickNoteType.knowledge);
      expect(result.candidateNewName, 'Alice');
    });

    test('nerHints is ignored when fuzzy match succeeds', () {
      final contacts = [makeContact('张三')];
      final result = parser.parse(
        '今天见了张三',
        contacts,
        nerHints: ['李四'],
      );

      expect(result.noteType, QuickNoteType.structured);
      expect(result.matchedContact?.name, '张三');
      expect(result.candidateNewName, isNull);
    });

    test('empty nerHints falls back to regex extraction', () {
      final result = parser.parse(
        '今天见了王伟，讨论了新方案',
        [],
        nerHints: [],
      );

      expect(result.candidateNewName, '王伟');
    });

    test('null nerHints falls back to regex extraction', () {
      final result = parser.parse(
        '今天见了王伟，讨论了新方案',
        [],
      );

      expect(result.candidateNewName, '王伟');
    });
  });
}
