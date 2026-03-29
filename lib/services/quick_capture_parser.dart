import '../models/contact.dart';

/// Quick Capture 输入的解析结果。
enum QuickNoteType { structured, knowledge }

class QuickCaptureParseResult {
  /// 原始输入（trim 后）。
  final String noteContent;

  /// 解析类型：命中联系人为 structured，否则为 knowledge。
  final QuickNoteType noteType;

  /// fuzzy match 命中的已有联系人（仅 noteType==structured 时非 null）。
  final Contact? matchedContact;

  /// fuzzy match 置信度，0.0–1.0。
  final double matchConfidence;

  /// 启发式规则识别到的候选人名（未命中已有联系人时可能非 null）。
  final String? candidateNewName;

  /// 解析出的事件日期（仅当检测到时间表达式时非 null）。
  final DateTime? detectedDate;

  /// 原始时间表达式，如"明天下午"。
  final String? detectedTimeExpr;

  /// 去掉时间表达式并智能清理后的建议事件标题。
  final String? suggestedEventTitle;

  const QuickCaptureParseResult({
    required this.noteContent,
    required this.noteType,
    required this.matchedContact,
    required this.matchConfidence,
    required this.candidateNewName,
    this.detectedDate,
    this.detectedTimeExpr,
    this.suggestedEventTitle,
  });
}

/// 时间解析中间结果。
class _TemporalMatch {
  final DateTime date;
  final String expression;
  final int start;
  final int end;

  const _TemporalMatch({
    required this.date,
    required this.expression,
    required this.start,
    required this.end,
  });
}

/// 离线解析 Quick Capture 输入文本，识别联系人或候选人名，以及时间意图。
///
/// 解析管道（均为同步、离线操作，无 DB 访问）:
///   1. 时间表达式解析（独立运行，不影响后续步骤）
///   2. fuzzy match 已有联系人（精确包含 confidence=1.0，编辑距离1 confidence=0.8）
///   3. 若无匹配，启发式提取候选人名（中文2–4字 + 英文首字母大写序列）
class QuickCaptureParser {
  static const double _exactMatchConfidence = 1.0;
  static const double _editDistance1Confidence = 0.8;
  static const double _confidenceThreshold = 0.8;

  /// 中文停用词，不作为候选人名。
  static const Set<String> _chineseStopwords = {
    '今天', '明天', '昨天', '后天', '前天', '上午', '下午', '晚上', '中午',
    '会议', '时间', '我们', '可能', '已经', '如果', '需要', '然后', '继续',
    '开始', '结束', '完成', '确认', '问题', '方案', '项目', '计划', '工作',
    '内容', '相关', '情况', '关系', '联系', '沟通', '讨论', '合作', '合同',
    '价格', '数据', '系统', '功能', '产品', '服务', '技术', '平台', '更新',
    '修改', '删除', '添加', '查看', '检查', '同意', '不同', '知道', '觉得',
    '想到', '应该', '可以', '那个', '这个', '什么', '怎么', '为什么', '没有',
    '有个', '有一', '周一', '周二', '周三', '周四', '周五', '周六', '周日',
    '月份', '季度', '年底', '年初', '下周', '上周', '下月', '上月', '下季',
    '预算', '目标', '进展', '进度', '反馈', '建议', '意见', '结论', '报告',
    '测试', '部署', '发布', '版本', '文档', '需求', '接口', '代码', '设计',
  };

  /// 解析输入文本。
  ///
  /// [input] 用户原始输入。
  /// [contacts] 当前联系人库（用于 fuzzy match）。
  /// [now] 当前时间（用于相对日期计算，测试时可注入）。
  QuickCaptureParseResult parse(
    String input,
    List<Contact> contacts, {
    DateTime? now,
  }) {
    final trimmed = input.trim();
    final referenceDate = now ?? DateTime.now();

    // Step 1: 时间表达式解析（独立于联系人匹配）
    final temporal = _tryParseTemporal(trimmed, referenceDate);

    // Step 2: fuzzy match 已有联系人
    final matchResult = _tryFuzzyMatch(trimmed, contacts);
    if (matchResult != null) {
      return QuickCaptureParseResult(
        noteContent: trimmed,
        noteType: QuickNoteType.structured,
        matchedContact: matchResult.$1,
        matchConfidence: matchResult.$2,
        candidateNewName: null,
        detectedDate: temporal?.date,
        detectedTimeExpr: temporal?.expression,
        suggestedEventTitle:
            temporal != null ? _extractEventTitle(trimmed, temporal) : null,
      );
    }

    // Step 3: 启发式人名识别
    final candidateName = _tryExtractName(trimmed);
    return QuickCaptureParseResult(
      noteContent: trimmed,
      noteType: QuickNoteType.knowledge,
      matchedContact: null,
      matchConfidence: 0.0,
      candidateNewName: candidateName,
      detectedDate: temporal?.date,
      detectedTimeExpr: temporal?.expression,
      suggestedEventTitle:
          temporal != null ? _extractEventTitle(trimmed, temporal) : null,
    );
  }

  // ──────────────────── fuzzy match ────────────────────

  (Contact, double)? _tryFuzzyMatch(String input, List<Contact> contacts) {
    Contact? bestContact;
    double bestConfidence = 0.0;

    for (final contact in contacts) {
      final name = contact.name.trim();
      if (name.isEmpty) continue;

      // 精确包含
      if (input.contains(name)) {
        if (_exactMatchConfidence > bestConfidence) {
          bestConfidence = _exactMatchConfidence;
          bestContact = contact;
        }
        continue;
      }

      // 编辑距离 1（滑窗，窗口大小 = name.length）
      if (name.length >= 2) {
        final windowSize = name.length;
        for (var i = 0; i <= input.length - windowSize; i++) {
          final window = input.substring(i, i + windowSize);
          if (_levenshtein(window, name) == 1) {
            if (_editDistance1Confidence > bestConfidence) {
              bestConfidence = _editDistance1Confidence;
              bestContact = contact;
            }
            break;
          }
        }
      }
    }

    if (bestContact != null && bestConfidence >= _confidenceThreshold) {
      return (bestContact, bestConfidence);
    }
    return null;
  }

  /// 计算两个字符串的 Levenshtein 编辑距离（不含递归，DP 实现）。
  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final aLen = a.length;
    final bLen = b.length;

    // dp[i][j] = 前 i 个 a 字符和前 j 个 b 字符的编辑距离
    final dp = List.generate(aLen + 1, (_) => List.filled(bLen + 1, 0));
    for (var i = 0; i <= aLen; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= bLen; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i <= aLen; i++) {
      for (var j = 1; j <= bLen; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost]
            .reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[aLen][bLen];
  }

  // ──────────────────── 启发式人名提取 ────────────────────

  String? _tryExtractName(String input) {
    // 中文：基于上下文触发词的名称提取。
    // 在"见了/和/与"等动词/介词后匹配 2–3 个汉字，避免误命中普通短语。
    final chineseContextPattern = RegExp(
      r'(?:见了|见到|找了|找到|联系了|联系到|拜访了|认识了|约了|见|跟|和|与|给|叫|请)'
      r'([\u4e00-\u9fff]{2,3})',
    );
    final chineseMatch = chineseContextPattern.firstMatch(input);
    if (chineseMatch != null) {
      final candidate = chineseMatch.group(1)!;
      if (!_chineseStopwords.contains(candidate)) {
        return candidate;
      }
    }

    // 英文：首字母大写的单词序列，跳过句首单词（通常为动词）。
    // 先收集所有 title-case 词，再组合相邻双词人名。
    final wordPattern = RegExp(r'\b[A-Z][a-z]+\b');
    final allWords = wordPattern.allMatches(input).toList();
    // 跳过句首第一个词
    final candidateWords = allWords.where((m) => m.start > 0).toList();

    if (candidateWords.isNotEmpty) {
      // 检查相邻两词是否紧挨着（中间只有一个空格）→ 视为姓名全称
      for (var i = 0; i < candidateWords.length - 1; i++) {
        final curr = candidateWords[i];
        final next = candidateWords[i + 1];
        if (next.start == curr.end + 1) {
          return '${curr.group(0)} ${next.group(0)}';
        }
      }
      return candidateWords.first.group(0);
    }

    return null;
  }

  // ──────────────────── 时间表达式解析 ────────────────────

  /// 中文时段到小时的映射。
  static const Map<String, int> _timeOfDayHours = {
    '早上': 8,
    '上午': 9,
    '中午': 12,
    '下午': 14,
    '傍晚': 17,
    '晚上': 19,
  };

  /// 中文周几到 [DateTime.monday] .. [DateTime.sunday] 的映射。
  static const Map<String, int> _weekdayMap = {
    '一': DateTime.monday,
    '二': DateTime.tuesday,
    '三': DateTime.wednesday,
    '四': DateTime.thursday,
    '五': DateTime.friday,
    '六': DateTime.saturday,
    '日': DateTime.sunday,
    '天': DateTime.sunday,
  };

  _TemporalMatch? _tryParseTemporal(String input, DateTime ref) {
    // 尝试各规则，取最早出现的匹配
    final candidates = <_TemporalMatch>[
      ..._matchRelativeDays(input, ref),
      ..._matchWeekdays(input, ref),
      ..._matchAbsoluteDates(input, ref),
    ];

    if (candidates.isEmpty) return null;

    // 取最早出现（start 最小）的匹配
    candidates.sort((a, b) => a.start.compareTo(b.start));
    final best = candidates.first;

    // 检查紧邻的时段修饰词，合并到结果中
    return _tryExtendWithTimeOfDay(input, best, ref);
  }

  List<_TemporalMatch> _matchRelativeDays(String input, DateTime ref) {
    final results = <_TemporalMatch>[];
    final pattern = RegExp(r'大后天|后天|明天|今天');
    for (final m in pattern.allMatches(input)) {
      final expr = m.group(0)!;
      final offset = switch (expr) {
        '今天' => 0,
        '明天' => 1,
        '后天' => 2,
        '大后天' => 3,
        _ => 0,
      };
      final date = DateTime(ref.year, ref.month, ref.day + offset);
      results.add(_TemporalMatch(
        date: date,
        expression: expr,
        start: m.start,
        end: m.end,
      ));
    }
    return results;
  }

  List<_TemporalMatch> _matchWeekdays(String input, DateTime ref) {
    final results = <_TemporalMatch>[];
    // 匹配 "下周X"、"这周X"、"本周X"、"周X"、"星期X"
    final pattern = RegExp(r'(下周|这周|本周|周|星期)([一二三四五六日天])');
    for (final m in pattern.allMatches(input)) {
      final prefix = m.group(1)!;
      final dayCh = m.group(2)!;
      final targetWeekday = _weekdayMap[dayCh];
      if (targetWeekday == null) continue;

      final today = DateTime(ref.year, ref.month, ref.day);
      final currentWeekday = today.weekday;

      int daysToAdd;
      if (prefix == '下周') {
        // 下周X = 从下周一开始算的那个X
        daysToAdd =
            (DateTime.monday - currentWeekday + 7) + (targetWeekday - DateTime.monday);
      } else {
        // 本周/这周/周/星期 → 本周的那一天
        daysToAdd = targetWeekday - currentWeekday;
        // 如果已经过了，指向下周
        if (daysToAdd <= 0) daysToAdd += 7;
      }

      results.add(_TemporalMatch(
        date: today.add(Duration(days: daysToAdd)),
        expression: m.group(0)!,
        start: m.start,
        end: m.end,
      ));
    }
    return results;
  }

  List<_TemporalMatch> _matchAbsoluteDates(String input, DateTime ref) {
    final results = <_TemporalMatch>[];
    // "3月30日"、"3月30号"、"03月30日"
    final pattern = RegExp(r'(\d{1,2})月(\d{1,2})[日号]');
    for (final m in pattern.allMatches(input)) {
      final month = int.tryParse(m.group(1)!);
      final day = int.tryParse(m.group(2)!);
      if (month == null || day == null) continue;
      if (month < 1 || month > 12 || day < 1 || day > 31) continue;

      // 默认当前年；如果已过，指向明年
      var year = ref.year;
      final candidate = DateTime(year, month, day);
      final today = DateTime(ref.year, ref.month, ref.day);
      if (candidate.isBefore(today)) {
        year += 1;
      }

      results.add(_TemporalMatch(
        date: DateTime(year, month, day),
        expression: m.group(0)!,
        start: m.start,
        end: m.end,
      ));
    }
    return results;
  }

  /// 如果时间表达式前后紧邻时段修饰词（上午/下午/晚上），合并。
  _TemporalMatch _tryExtendWithTimeOfDay(
    String input,
    _TemporalMatch base,
    DateTime ref,
  ) {
    for (final entry in _timeOfDayHours.entries) {
      final tod = entry.key;
      final hour = entry.value;

      // 时段在日期表达式之后（如"明天下午"）
      if (base.end <= input.length - tod.length &&
          input.substring(base.end, base.end + tod.length) == tod) {
        return _TemporalMatch(
          date: DateTime(base.date.year, base.date.month, base.date.day, hour),
          expression: input.substring(base.start, base.end + tod.length),
          start: base.start,
          end: base.end + tod.length,
        );
      }

      // 时段在日期表达式之前（如"下午三点" — V1 只取时段不取具体小时）
      if (base.start >= tod.length &&
          input.substring(base.start - tod.length, base.start) == tod) {
        return _TemporalMatch(
          date: DateTime(base.date.year, base.date.month, base.date.day, hour),
          expression: input.substring(base.start - tod.length, base.end),
          start: base.start - tod.length,
          end: base.end,
        );
      }
    }

    return base;
  }

  // ──────────────────── 事件标题提取 ────────────────────

  /// 中文前导填充词：去掉时间表达式后，标题开头常见的助动词/语气词。
  static final RegExp _leadingFillerPattern = RegExp(
    r'^[，,、\s]*'
    r'(?:别忘了|别忘记|记得要|不要忘了|不要忘记|一定要|'
    r'记得|需要|必须|应该|可以|要去|要来|要|得|去|来|给|把)',
  );

  /// 去掉时间表达式，智能清理剩余文本为事件标题。
  String _extractEventTitle(String input, _TemporalMatch temporal) {
    // 移除时间表达式
    final before = input.substring(0, temporal.start);
    final after = input.substring(temporal.end);
    var title = '$before$after'.trim();

    // 去掉前导填充词
    title = title.replaceFirst(_leadingFillerPattern, '').trim();

    // 去掉开头的标点
    title = title.replaceFirst(RegExp(r'^[，,、\s]+'), '').trim();

    return title.isEmpty ? input.trim() : title;
  }
}
