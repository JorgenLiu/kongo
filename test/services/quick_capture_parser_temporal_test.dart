import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/contact.dart';
import 'package:kongo/services/quick_capture_parser.dart';

void main() {
  late QuickCaptureParser parser;

  /// 固定参考日期：2026-03-29（周日）
  final ref = DateTime(2026, 3, 29);

  setUp(() {
    parser = QuickCaptureParser();
  });

  // ──────────────────── 相对日期 ────────────────────

  group('relative day expressions', () {
    test('"明天要做demo" detects tomorrow and extracts title', () {
      final result = parser.parse('明天要做demo', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 30));
      expect(result.detectedTimeExpr, '明天');
      expect(result.suggestedEventTitle, '做demo');
    });

    test('"今天开会" detects today', () {
      final result = parser.parse('今天开会', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 29));
      expect(result.detectedTimeExpr, '今天');
      expect(result.suggestedEventTitle, '开会');
    });

    test('"后天交报告" detects day after tomorrow', () {
      final result = parser.parse('后天交报告', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 31));
      expect(result.detectedTimeExpr, '后天');
      expect(result.suggestedEventTitle, '交报告');
    });

    test('"大后天出差" detects 3 days from now', () {
      final result = parser.parse('大后天出差', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 4, 1));
      expect(result.detectedTimeExpr, '大后天');
      expect(result.suggestedEventTitle, '出差');
    });
  });

  // ──────────────────── 时段组合 ────────────────────

  group('relative day + time of day', () {
    test('"明天下午开会" detects tomorrow 14:00', () {
      final result = parser.parse('明天下午开会', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 30, 14));
      expect(result.detectedTimeExpr, '明天下午');
      expect(result.suggestedEventTitle, '开会');
    });

    test('"后天上午review代码" detects day-after-tomorrow 09:00', () {
      final result = parser.parse('后天上午review代码', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 31, 9));
      expect(result.detectedTimeExpr, '后天上午');
      expect(result.suggestedEventTitle, 'review代码');
    });

    test('"明天晚上聚餐" detects tomorrow 19:00', () {
      final result = parser.parse('明天晚上聚餐', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 30, 19));
      expect(result.detectedTimeExpr, '明天晚上');
      expect(result.suggestedEventTitle, '聚餐');
    });
  });

  // ──────────────────── 周几 ────────────────────

  group('weekday expressions', () {
    // ref = 2026-03-29 周日
    test('"周一开会" detects next Monday (03-30)', () {
      final result = parser.parse('周一开会', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 30));
      expect(result.detectedTimeExpr, '周一');
      expect(result.suggestedEventTitle, '开会');
    });

    test('"下周三讨论方案" detects next Wednesday (04-01)', () {
      // ref is Sunday 03-29; 下周一 = 03-30; 下周三 = 04-01
      final result = parser.parse('下周三讨论方案', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 4, 1));
      expect(result.detectedTimeExpr, '下周三');
      expect(result.suggestedEventTitle, '讨论方案');
    });

    test('"星期五发版本" detects this Friday', () {
      final result = parser.parse('星期五发版本', [], now: ref);

      // ref = 周日 03-29, 星期五 = 04-03
      expect(result.detectedDate, DateTime(2026, 4, 3));
      expect(result.detectedTimeExpr, '星期五');
      expect(result.suggestedEventTitle, '发版本');
    });
  });

  // ──────────────────── 绝对日期 ────────────────────

  group('absolute date expressions', () {
    test('"3月30日提交代码" detects March 30', () {
      final result = parser.parse('3月30日提交代码', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 30));
      expect(result.detectedTimeExpr, '3月30日');
      expect(result.suggestedEventTitle, '提交代码');
    });

    test('"4月15号见客户" detects April 15', () {
      final result = parser.parse('4月15号见客户', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 4, 15));
      expect(result.detectedTimeExpr, '4月15号');
      expect(result.suggestedEventTitle, '见客户');
    });

    test('past date rolls to next year', () {
      final result = parser.parse('1月1日元旦', [], now: ref);

      expect(result.detectedDate, DateTime(2027, 1, 1));
      expect(result.detectedTimeExpr, '1月1日');
    });
  });

  // ──────────────────── 标题智能清理 ────────────────────

  group('smart title extraction', () {
    test('removes leading filler "要"', () {
      final result = parser.parse('明天要做demo', [], now: ref);
      expect(result.suggestedEventTitle, '做demo');
    });

    test('removes leading filler "需要"', () {
      final result = parser.parse('明天需要开会', [], now: ref);
      expect(result.suggestedEventTitle, '开会');
    });

    test('removes leading filler "记得"', () {
      final result = parser.parse('后天记得交报告', [], now: ref);
      expect(result.suggestedEventTitle, '交报告');
    });

    test('removes leading filler "别忘了"', () {
      final result = parser.parse('明天别忘了发邮件', [], now: ref);
      expect(result.suggestedEventTitle, '发邮件');
    });

    test('removes leading filler "得"', () {
      final result = parser.parse('后天得交报告', [], now: ref);
      expect(result.suggestedEventTitle, '交报告');
    });

    test('keeps meaningful content when time is in the middle', () {
      final result = parser.parse('和张三明天开会', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 30));
      expect(result.suggestedEventTitle, '和张三开会');
    });

    test('preserves entire input if removal leaves empty string', () {
      final result = parser.parse('明天', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 30));
      expect(result.suggestedEventTitle, '明天');
    });
  });

  // ──────────────────── 无时间意图 ────────────────────

  group('no temporal intent', () {
    test('pure content without time expression returns null fields', () {
      final result = parser.parse('CloudKit 单条记录上限 10MB', [], now: ref);

      expect(result.detectedDate, isNull);
      expect(result.detectedTimeExpr, isNull);
      expect(result.suggestedEventTitle, isNull);
    });

    test('all-lowercase English has no temporal detection', () {
      final result = parser.parse('flutter build macos done', [], now: ref);

      expect(result.detectedDate, isNull);
    });
  });

  // ──────────────────── 时间 + 联系人同时识别 ────────────────────

  group('combined temporal and contact detection', () {
    test('time + existing contact both detected', () {
      final contacts = [
        _makeContact('张三'),
      ];
      final result = parser.parse('明天和张三开会', contacts, now: ref);

      expect(result.matchedContact?.name, '张三');
      expect(result.detectedDate, DateTime(2026, 3, 30));
      expect(result.suggestedEventTitle, '和张三开会');
    });

    test('time + candidate name both detected', () {
      final result = parser.parse('明天跟王伟sync一下', [], now: ref);

      expect(result.candidateNewName, '王伟');
      expect(result.detectedDate, DateTime(2026, 3, 30));
      expect(result.suggestedEventTitle, '跟王伟sync一下');
    });
  });
}

// ──────────────────── 辅助 ────────────────────

Contact _makeContact(String name) => Contact(
      id: 'id-$name',
      name: name,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
