import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/services/quick_capture_parser.dart';

void main() {
  late QuickCaptureParser parser;

  /// 固定参考日期：2026-03-29（周日）
  final ref = DateTime(2026, 3, 29);

  setUp(() {
    parser = QuickCaptureParser();
  });

  // ──────────────────── dateHints 优先级 ────────────────────

  group('dateHints 优先级', () {
    test('dateHint 提供日期时，解析结果使用 hint 日期', () {
      // "买牛奶"中没有 Dart 正则能识别的时间词
      // 但平台 NSDataDetector 提供了 hint → 应采用 hint
      final result = parser.parse(
        '买牛奶',
        [],
        now: ref,
        dateHints: ['2026-04-02T00:00:00Z'],
      );
      expect(result.detectedDate, DateTime.utc(2026, 4, 2));
    });

    test('dateHints 为空时，仍走 Dart 正则', () {
      final result = parser.parse('明天开会', [], now: ref, dateHints: []);
      expect(result.detectedDate, isNotNull);
      // 2026-03-29（周日）的明天 = 2026-03-30，无时分 → 默认 08:00
      expect(result.detectedDate, DateTime(2026, 3, 30, 8, 0));
    });

    test('dateHints null 时与空数组行为一致', () {
      final r1 = parser.parse('明天开会', [], now: ref, dateHints: null);
      final r2 = parser.parse('明天开会', [], now: ref, dateHints: []);
      expect(r1.detectedDate, r2.detectedDate);
    });

    test('dateHint 精确时刻（含时分）保留 hour/minute', () {
      final result = parser.parse(
        '明天面试',
        [],
        now: ref,
        dateHints: ['2026-04-02T14:30:00Z'],
      );
      expect(result.detectedDate?.hour, 14);
      expect(result.detectedDate?.minute, 30);
    });

    test('hint 路径仍推断事件类型', () {
      final result = parser.parse(
        '明天有面试',
        [],
        now: ref,
        dateHints: ['2026-04-02T00:00:00Z'],
      );
      expect(result.detectedEventType, 'interview');
    });

    test('hint 路径 suggestedEventTitle 剥离前缀噪音', () {
      final result = parser.parse(
        '明天有面试',
        [],
        now: ref,
        dateHints: ['2026-04-02T00:00:00Z'],
      );
      expect(result.suggestedEventTitle, '面试');
    });

    test('hint 日期覆盖 Dart 正则日期（两者不同时，hint 优先）', () {
      // Dart 正则识别"明天" = 2026-03-30；hint 提供 2026-04-05
      // 应使用 hint 的 2026-04-05
      final result = parser.parse(
        '明天开会',
        [],
        now: ref,
        dateHints: ['2026-04-05T00:00:00Z'],
      );
      expect(result.detectedDate, DateTime.utc(2026, 4, 5));
    });

    test('无时间词 + 无 hint → detectedDate 为 null', () {
      final result = parser.parse('买牛奶', [], now: ref, dateHints: []);
      expect(result.detectedDate, isNull);
    });

    test('纯 hint 路径 + 无关键词 → eventType 为 null', () {
      final result = parser.parse(
        '买牛奶',
        [],
        now: ref,
        dateHints: ['2026-04-02T00:00:00Z'],
      );
      // title = "买牛奶"，无关键词匹配
      expect(result.detectedEventType, isNull);
    });

    // ── 时段优先级回归测试（NSDataDetector 默认时刻不应覆盖 Dart 语义时段）──

    test('hint 含默认时刻（07:00）时，Dart 解析的"下午"（14:00）优先', () {
      // 复现场景：用户说"明天下午去医院看牙"
      // NSDataDetector 返回明天 07:00，但 Dart 明确解析出"下午"=14:00
      // 期望：使用 hint 的日期 + Dart 的 14:00，而非 hint 的 07:00
      final result = parser.parse(
        '明天下午去医院看牙',
        [],
        now: ref,
        dateHints: ['2026-03-30T07:00:00Z'],
      );
      expect(result.detectedDate?.hour, 14,
          reason: '下午应解析为 14 点，不应被 hint 的 07:00 覆盖');
      expect(result.detectedDate?.year, 2026);
      expect(result.detectedDate?.month, 3);
      expect(result.detectedDate?.day, 30);
      expect(result.isTimeExact, false);
    });

    test('hint 含零点日期时，Dart 解析的"下午三点"（15:00）保留', () {
      final result = parser.parse(
        '明天下午三点看牙',
        [],
        now: ref,
        dateHints: ['2026-03-30T00:00:00Z'],
      );
      expect(result.detectedDate?.hour, 15);
      expect(result.isTimeExact, true);
    });

    test('Dart 无时间信息时，hint 的非零时刻被采用', () {
      // 纯日期文本 "买牛奶"，hint 提供精确时刻 09:30
      final result = parser.parse(
        '买牛奶',
        [],
        now: ref,
        dateHints: ['2026-04-02T09:30:00Z'],
      );
      expect(result.detectedDate?.hour, 9);
      expect(result.detectedDate?.minute, 30);
      expect(result.isTimeExact, true);
    });
  });
}
