import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/services/quick_capture_parser.dart';

void main() {
  late QuickCaptureParser parser;

  /// 固定参考日期：2026-03-29（周日）
  final ref = DateTime(2026, 3, 29);

  setUp(() {
    parser = QuickCaptureParser();
  });

  // ──────────────────── 事件类型推断 ────────────────────

  group('detectedEventType inference', () {
    // ── interview ──
    test('"明天下午有面试" → interview', () {
      final result = parser.parse('明天下午有面试', [], now: ref);
      expect(result.detectedEventType, 'interview');
      expect(result.suggestedEventTitle, '面试');
    });

    test('"后天来了个面试" → interview', () {
      final result = parser.parse('后天来了个面试', [], now: ref);
      expect(result.detectedEventType, 'interview');
    });

    // ── meal ──
    test('"今天晚上聚餐" → meal', () {
      final result = parser.parse('今天晚上聚餐', [], now: ref);
      expect(result.detectedEventType, 'meal');
    });

    test('"明天中午吃饭" → meal', () {
      final result = parser.parse('明天中午吃饭', [], now: ref);
      expect(result.detectedEventType, 'meal');
    });

    test('"下周五饭局" → meal', () {
      final result = parser.parse('下周五饭局', [], now: ref);
      expect(result.detectedEventType, 'meal');
    });

    // ── meeting ──
    test('"明天下午开会" → meeting', () {
      final result = parser.parse('明天下午开会', [], now: ref);
      expect(result.detectedEventType, 'meeting');
    });

    test('"后天上午有会议" → meeting', () {
      final result = parser.parse('后天上午有会议', [], now: ref);
      expect(result.detectedEventType, 'meeting');
      // 同时验证 有 被剥离
      expect(result.suggestedEventTitle, '会议');
    });

    test('"下周三讨论方案" → meeting', () {
      final result = parser.parse('下周三讨论方案', [], now: ref);
      expect(result.detectedEventType, 'meeting');
    });

    test('"明天晚上站会" → meeting', () {
      final result = parser.parse('明天晚上站会', [], now: ref);
      expect(result.detectedEventType, 'meeting');
    });

    test('"明天做 code review" → meeting', () {
      final result = parser.parse('明天做 code review', [], now: ref);
      expect(result.detectedEventType, 'meeting');
    });

    // ── travel ──
    test('"明天出差北京" → travel', () {
      final result = parser.parse('明天出差北京', [], now: ref);
      expect(result.detectedEventType, 'travel');
    });

    test('"后天飞上海" → travel', () {
      final result = parser.parse('后天飞上海', [], now: ref);
      expect(result.detectedEventType, 'travel');
    });

    // ── deadline ──
    test('"4月15号截止" → deadline', () {
      final result = parser.parse('4月15号截止', [], now: ref);
      expect(result.detectedEventType, 'deadline');
    });

    test('"下周五提交代码" → deadline', () {
      final result = parser.parse('下周五提交代码', [], now: ref);
      expect(result.detectedEventType, 'deadline');
    });

    test('"本周五发版" → deadline', () {
      final result = parser.parse('本周五发版', [], now: ref);
      expect(result.detectedEventType, 'deadline');
    });

    // ── contract ──
    test('"下周五签合同" → contract', () {
      final result = parser.parse('下周五签合同', [], now: ref);
      expect(result.detectedEventType, 'contract');
    });

    // ── demo ──
    test('"明天要做demo" → demo', () {
      final result = parser.parse('明天要做demo', [], now: ref);
      expect(result.detectedEventType, 'demo');
    });

    test('"周五产品演示" → demo', () {
      final result = parser.parse('周五产品演示', [], now: ref);
      expect(result.detectedEventType, 'demo');
    });

    // ── training ──
    test('"明天有培训" → training', () {
      final result = parser.parse('明天有培训', [], now: ref);
      expect(result.detectedEventType, 'training');
      // 有 被剥离
      expect(result.suggestedEventTitle, '培训');
    });

    // ── release ──
    test('"下周五发布新版本" → release', () {
      final result = parser.parse('下周五发布新版本', [], now: ref);
      expect(result.detectedEventType, 'release');
    });

    // ── null cases ──
    test('无时间表达式 → detectedEventType is null', () {
      final result = parser.parse('买牛奶', [], now: ref);
      expect(result.detectedDate, isNull);
      expect(result.detectedEventType, isNull);
    });

    test('有时间但内容无关键词 → null', () {
      final result = parser.parse('明天确认一下', [], now: ref);
      expect(result.detectedEventType, isNull);
    });

    test('纯知识笔记 → null', () {
      final result = parser.parse('产品想法：离线优先', [], now: ref);
      expect(result.detectedEventType, isNull);
    });
  });
}
