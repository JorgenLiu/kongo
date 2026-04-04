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

      expect(result.detectedDate, DateTime(2026, 3, 30, 8, 0));
      expect(result.detectedTimeExpr, '明天');
      expect(result.suggestedEventTitle, '做demo');
    });

    test('"今天开会" detects today', () {
      final result = parser.parse('今天开会', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 29, 8, 0));
      expect(result.detectedTimeExpr, '今天');
      expect(result.suggestedEventTitle, '开会');
    });

    test('"后天交报告" detects day after tomorrow', () {
      final result = parser.parse('后天交报告', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 31, 8, 0));
      expect(result.detectedTimeExpr, '后天');
      expect(result.suggestedEventTitle, '交报告');
    });

    test('"大后天出差" detects 3 days from now', () {
      final result = parser.parse('大后天出差', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 4, 1, 8, 0));
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

    test('"明天下午两点半有面试" detects tomorrow 14:30', () {
      final result = parser.parse('明天下午两点半有面试', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 30, 14, 30));
      expect(result.detectedTimeExpr, '明天下午两点半');
      expect(result.suggestedEventTitle, '面试');
    });

    test('"后天有会议" strips leading 有', () {
      final result = parser.parse('后天有会议', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 31, 8, 0));
      expect(result.suggestedEventTitle, '会议');
    });

    test('"下周三有场面试" strips 有 but keeps 量词 场', () {
      final result = parser.parse('下周三有场面试', [], now: ref);

      expect(result.suggestedEventTitle, '场面试');
    });

    test('"明天下午三点会议" detects tomorrow 15:00', () {
      final result = parser.parse('明天下午三点会议', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 30, 15));
      expect(result.detectedTimeExpr, '明天下午三点');
      expect(result.suggestedEventTitle, '会议');
    });

    test('"明天晚上八点半吃饭" detects tomorrow 20:30', () {
      final result = parser.parse('明天晚上八点半吃饭', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 30, 20, 30));
      expect(result.detectedTimeExpr, '明天晚上八点半');
      expect(result.suggestedEventTitle, '吃饭');
    });

    test('"明天上午十点开会" detects tomorrow 10:00 (AM stays AM)', () {
      final result = parser.parse('明天上午十点开会', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 30, 10));
      expect(result.detectedTimeExpr, '明天上午十点');
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

      expect(result.detectedDate, DateTime(2026, 3, 30, 8, 0));
      expect(result.detectedTimeExpr, '周一');
      expect(result.suggestedEventTitle, '开会');
    });

    test('"下周三讨论方案" detects next Wednesday (04-01)', () {
      // ref is Sunday 03-29; 下周一 = 03-30; 下周三 = 04-01
      final result = parser.parse('下周三讨论方案', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 4, 1, 8, 0));
      expect(result.detectedTimeExpr, '下周三');
      expect(result.suggestedEventTitle, '讨论方案');
    });

    test('"星期五发版本" detects this Friday', () {
      final result = parser.parse('星期五发版本', [], now: ref);

      // ref = 周日 03-29, 星期五 = 04-03
      expect(result.detectedDate, DateTime(2026, 4, 3, 8, 0));
      expect(result.detectedTimeExpr, '星期五');
      expect(result.suggestedEventTitle, '发版本');
    });
  });

  // ──────────────────── 绝对日期 ────────────────────

  group('absolute date expressions', () {
    test('"3月30日提交代码" detects March 30', () {
      final result = parser.parse('3月30日提交代码', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 30, 8, 0));
      expect(result.detectedTimeExpr, '3月30日');
      expect(result.suggestedEventTitle, '提交代码');
    });

    test('"4月15号见客户" detects April 15', () {
      final result = parser.parse('4月15号见客户', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 4, 15, 8, 0));
      expect(result.detectedTimeExpr, '4月15号');
      expect(result.suggestedEventTitle, '见客户');
    });

    test('past date rolls to next year', () {
      final result = parser.parse('1月1日元旦', [], now: ref);

      expect(result.detectedDate, DateTime(2027, 1, 1, 8, 0));
      expect(result.detectedTimeExpr, '1月1日');
    });
  });

  // ──────────────────── 不带月份的 X号 ────────────────────

  group('bare day-of-month expressions', () {
    test('"30号开会" detects 30th of current month', () {
      final result = parser.parse('30号开会', [], now: ref);

      // ref = 3-29, 30号 is after today → 3月30日
      expect(result.detectedDate, DateTime(2026, 3, 30, 8, 0));
      expect(result.detectedTimeExpr, '30号');
      expect(result.suggestedEventTitle, '开会');
    });

    test('"15号交报告" with past day rolls to next month', () {
      final result = parser.parse('15号交报告', [], now: ref);

      // ref = 3-29, 15号 is before today → 4月15日
      expect(result.detectedDate, DateTime(2026, 4, 15, 8, 0));
      expect(result.detectedTimeExpr, '15号');
      expect(result.suggestedEventTitle, '交报告');
    });

    test('"4月15号" uses full pattern, not bare pattern', () {
      final result = parser.parse('4月15号见客户', [], now: ref);

      // Should match the full X月X号 pattern, not bare
      expect(result.detectedDate, DateTime(2026, 4, 15, 8, 0));
      expect(result.detectedTimeExpr, '4月15号');
    });
  });

  // ──────────────────── 中文数字日期 X号 ────────────────────

  group('Chinese numeral bare day-of-month (X号)', () {
    // ref = 2026-03-29

    test('"十七号去看房" → past → next month (April 17)', () {
      final result = parser.parse('十七号去看房', [], now: ref);
      expect(result.detectedDate, DateTime(2026, 4, 17, 8, 0));
      expect(result.detectedTimeExpr, '十七号');
      // 去 是前导填充词，被剥离后剩余 "看房"
      expect(result.suggestedEventTitle, '看房');
    });

    test('"三十一号发版" → future same month (March 31)', () {
      final result = parser.parse('三十一号发版', [], now: ref);
      expect(result.detectedDate, DateTime(2026, 3, 31, 8, 0));
      expect(result.detectedTimeExpr, '三十一号');
      expect(result.suggestedEventTitle, '发版');
    });

    test('"三号开会" → past → next month (April 3)', () {
      final result = parser.parse('三号开会', [], now: ref);
      expect(result.detectedDate, DateTime(2026, 4, 3, 8, 0));
      expect(result.detectedTimeExpr, '三号');
      expect(result.suggestedEventTitle, '开会');
    });

    test('"二十号截止" → past → next month (April 20)', () {
      final result = parser.parse('二十号截止', [], now: ref);
      expect(result.detectedDate, DateTime(2026, 4, 20, 8, 0));
      expect(result.detectedTimeExpr, '二十号');
      expect(result.suggestedEventTitle, '截止');
    });

    test('"二十五号聚餐" → past → next month (April 25)', () {
      final result = parser.parse('二十五号聚餐', [], now: ref);
      expect(result.detectedDate, DateTime(2026, 4, 25, 8, 0));
      expect(result.detectedTimeExpr, '二十五号');
    });

    test('"十号飞北京" → past → next month (April 10)', () {
      final result = parser.parse('十号飞北京', [], now: ref);
      expect(result.detectedDate, DateTime(2026, 4, 10, 8, 0));
      expect(result.detectedTimeExpr, '十号');
    });

    test('"一号元旦" → past → next month (April 1)', () {
      final result = parser.parse('一号元旦', [], now: ref);
      expect(result.detectedDate, DateTime(2026, 4, 1, 8, 0));
      expect(result.detectedTimeExpr, '一号');
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

      expect(result.detectedDate, DateTime(2026, 3, 30, 8, 0));
      expect(result.suggestedEventTitle, '和张三开会');
    });

    test('preserves entire input if removal leaves empty string', () {
      final result = parser.parse('明天', [], now: ref);

      expect(result.detectedDate, DateTime(2026, 3, 30, 8, 0));
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
      expect(result.detectedDate, DateTime(2026, 3, 30, 8, 0));
      expect(result.suggestedEventTitle, '和张三开会');
    });

    test('time + candidate name both detected', () {
      final result = parser.parse('明天跟王伟sync一下', [], now: ref);

      expect(result.candidateNewName, '王伟');
      expect(result.detectedDate, DateTime(2026, 3, 30, 8, 0));
      expect(result.suggestedEventTitle, '跟王伟sync一下');
    });
  });

  // ──────────────────── isTimeExact 标志 ────────────────────

  group('isTimeExact flag', () {
    test('"明天开会" → isTimeExact false, hour 8', () {
      final r = parser.parse('明天开会', [], now: ref);
      expect(r.isTimeExact, false);
      expect(r.detectedDate?.hour, 8);
    });

    test('"明天下午开会" → isTimeExact false, hour 14', () {
      final r = parser.parse('明天下午开会', [], now: ref);
      expect(r.isTimeExact, false);
      expect(r.detectedDate?.hour, 14);
    });

    test('"明天下午三点开会" → isTimeExact true, hour 15', () {
      final r = parser.parse('明天下午三点开会', [], now: ref);
      expect(r.isTimeExact, true);
      expect(r.detectedDate?.hour, 15);
    });

    test('"明天下午两点半有面试" → isTimeExact true, 14:30', () {
      final r = parser.parse('明天下午两点半有面试', [], now: ref);
      expect(r.isTimeExact, true);
      expect(r.detectedDate?.hour, 14);
      expect(r.detectedDate?.minute, 30);
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
