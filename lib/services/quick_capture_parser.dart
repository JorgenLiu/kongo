import '../models/contact.dart';

/// Quick Capture 输入的解析结果。
enum QuickNoteType { structured, knowledge }

/// 解析出的用户意图（用于快速创建/更新/取消事件的候选动作）。
enum QuickCaptureIntent { create, updateTime, cancel }

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

  /// 启发式推断的事件类型标签（如 "meeting"/"interview"/"meal"/"travel"/"deadline"）。
  /// 未识别时为 null，供 UI 展示类型图标或未来 event_type 预填。
  final String? detectedEventType;

  /// 解析出的时间是否精确到小时（用户输入了"X点"或更具体的时刻）。
  /// false 表示只有日期或时段词（"下午"），时间为系统默认值，用户应可在 UI 中调整。
  final bool isTimeExact;
  /// 解析出的意图（创建/修改时间/取消）。
  final QuickCaptureIntent intent;

  const QuickCaptureParseResult({
    required this.noteContent,
    required this.noteType,
    required this.matchedContact,
    required this.matchConfidence,
    required this.candidateNewName,
    this.detectedDate,
    this.detectedTimeExpr,
    this.suggestedEventTitle,
    this.detectedEventType,
    this.isTimeExact = false,
    this.intent = QuickCaptureIntent.create,
  });
}

/// 时间解析中间结果。
class _TemporalMatch {
  final DateTime date;
  final String expression;
  final int start;
  final int end;
  /// true 表示解析出了精确的小时（至少），即用户输入了"X点"或更具体的时刻。
  final bool isExact;

  const _TemporalMatch({
    required this.date,
    required this.expression,
    required this.start,
    required this.end,
    this.isExact = false,
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
  static const double _fuzzyMatchConfidence = 0.8;
  static const double _confidenceThreshold = 0.8;
  static const double _diceThreshold = 0.6;

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
  /// [nerHints] 平台 NER 引擎提供的候选人名（如 NLTagger），优先于正则启发。
  QuickCaptureParseResult parse(
    String input,
    List<Contact> contacts, {
    DateTime? now,
    List<String>? nerHints,
    List<String>? dateHints,
  }) {
    final trimmed = input.trim();
    final referenceDate = now ?? DateTime.now();

    // Step 1: 时间表达式解析（始终运行，用于标题位置提取）
    final temporal = _tryParseTemporal(trimmed, referenceDate);

    // Step 2: 日期来源 — 合并 platform NSDataDetector hint 与 Dart regex 结果，取更精确的时分
    DateTime? hintDate;
    if (dateHints != null && dateHints.isNotEmpty) {
      hintDate = DateTime.tryParse(dateHints.first);
    }

    DateTime? resolvedDate;
    bool isTimeExact;
    if (hintDate != null && temporal?.date != null) {
      final hintHasTime = hintDate.hour != 0 || hintDate.minute != 0;
      final dartHasExactTime = temporal!.isExact;
      // Dart 解析出任何有意义的时段（如"下午"=14:00）时，优先使用 Dart 时间；
      // NSDataDetector 只用来补充年月日，避免它的默认时间覆盖用户表达的时段。
      final dartHasTimeOfDay = temporal.date.hour != 0 || temporal.date.minute != 0;

      if (dartHasExactTime || dartHasTimeOfDay) {
        // Dart 有时段/精确时间 → 用 hint 年月日 + Dart 时分
        resolvedDate = DateTime(
          hintDate.year, hintDate.month, hintDate.day,
          temporal.date.hour, temporal.date.minute,
        );
        isTimeExact = dartHasExactTime;
      } else if (hintHasTime) {
        // hint 有时分，Dart 只有日期 → 用 hint 完整时间
        resolvedDate = hintDate;
        isTimeExact = true;
      } else {
        resolvedDate = hintDate;
        isTimeExact = false;
      }
    } else {
      resolvedDate = hintDate ?? temporal?.date;
      isTimeExact = hintDate != null
          ? (hintDate.hour != 0 || hintDate.minute != 0)
          : (temporal?.isExact ?? false);
    }

    // Step 2b: 纯日期（无时分，且非 hint 路径）默认上午 08:00，避免凌晨 0 点
    if (resolvedDate != null &&
        hintDate == null &&
        resolvedDate.hour == 0 &&
        resolvedDate.minute == 0) {
      resolvedDate = DateTime(
        resolvedDate.year, resolvedDate.month, resolvedDate.day, 8, 0,
      );
    }
    // Step 3: 标题提取（仅当有时间意图时）
    final eventTitle = resolvedDate != null
        ? (temporal != null
            ? _extractEventTitle(trimmed, temporal)
            : _extractEventTitleFallback(trimmed))
        : null;
    final eventType = eventTitle != null ? _detectEventType(eventTitle) : null;

    // 意图检测（create / updateTime / cancel）
    final intent = _detectIntent(trimmed, temporal, resolvedDate);

    // Step 4: fuzzy match 已有联系人
    final matchResult = _tryFuzzyMatch(trimmed, contacts);
    if (matchResult != null) {
      // 仅当从文本提取的名字与匹配联系人不同时（真正 fuzzy 情形）才保留原始名字，
      // 供 UI 侧"新建联系人"使用正确姓名。精确匹配时 candidateNewName = null。
      final extractedFromText = extractCandidateName(trimmed);
      final matchedNorm = _normalizePersonName(matchResult.$1.name);
      final preservedName = (extractedFromText != null &&
              _normalizePersonName(extractedFromText) != matchedNorm)
          ? _normalizePersonName(extractedFromText)
          : null;
      return QuickCaptureParseResult(
        noteContent: trimmed,
        noteType: QuickNoteType.structured,
        matchedContact: matchResult.$1,
        matchConfidence: matchResult.$2,
        candidateNewName: preservedName,
        detectedDate: resolvedDate,
        detectedTimeExpr: temporal?.expression,
        suggestedEventTitle: eventTitle,
        detectedEventType: eventType,
        isTimeExact: isTimeExact,
        intent: intent,
      );
    }

    // Step 5: 启发式人名识别
    final candidateName = (nerHints != null && nerHints.isNotEmpty)
        ? nerHints.first
        : extractCandidateName(trimmed);
    return QuickCaptureParseResult(
      noteContent: trimmed,
      noteType: QuickNoteType.knowledge,
      matchedContact: null,
      matchConfidence: 0.0,
      candidateNewName: candidateName == null ? null : _normalizePersonName(candidateName),
      detectedDate: resolvedDate,
      detectedTimeExpr: temporal?.expression,
      suggestedEventTitle: eventTitle,
      detectedEventType: eventType,
      isTimeExact: isTimeExact,
      intent: intent,
    );
  }

  /// 将候选/输入中的人名做标准化：去掉常见称谓、前置词、末尾的 "的" 等噪音。
  static String _normalizePersonName(String s) {
    var t = s.trim();
    if (t.isEmpty) return t;
    // 常见中文/英文称谓
    const honorifics = ['先生', '小姐', '女士', '太太', '老师', '经理', '总', '主管', '部长', '小姐们', '先生们', '女士们'];
    for (final h in honorifics) {
      if (t.endsWith(h)) {
        t = t.substring(0, t.length - h.length).trim();
        break;
      }
    }
    // 去掉前置动词/介词如 "给/找/找了/约/和/跟/与" 开头
    t = t.replaceFirst(RegExp(r'^(?:给|找|找了|约|和|跟|与|给我|给你)\s*'), '');
    // 去掉结尾的 '的' 或 '的事情' 等
    t = t.replaceFirst(RegExp(r'的(?!\S)'), '').trim();
    // 去除多余标点
    t = t.replaceAll(RegExp(r'[，,、:\-–—._]'), '').trim();
    return t;
  }

  /// 简单意图检测器：优先识别取消词，其次识别修改时间的动词并且输入中包含时间信息。
  static QuickCaptureIntent _detectIntent(String input, _TemporalMatch? temporal, DateTime? resolvedDate) {
    final s = input;
    // 取消表达
    final cancelPat = RegExp(r'取消|不用了|不去了|别去了|别来|撤销|取消掉');
    if (cancelPat.hasMatch(s)) return QuickCaptureIntent.cancel;

    // 修改时间表达（若包含时间则视为 updateTime）
    final updatePat = RegExp(r'改(时间|期|到|为|成)?|推迟|延后|改到|改期|改为|调整到');
    if (updatePat.hasMatch(s) && (temporal != null || resolvedDate != null)) {
      return QuickCaptureIntent.updateTime;
    }

    return QuickCaptureIntent.create;
  }

  // ──────────────────── fuzzy match ────────────────────

  (Contact, double)? _tryFuzzyMatch(String input, List<Contact> contacts) {
    Contact? bestContact;
    double bestConfidence = 0.0;

    final normalizedInput = _normalizePersonName(input);

    for (final contact in contacts) {
      final name = contact.name.trim();
      if (name.isEmpty) continue;
      final normalizedName = _normalizePersonName(name);

      // 精确包含（使用标准化文本比较）
      if (normalizedInput.contains(normalizedName) || input.contains(name)) {
        if (_exactMatchConfidence > bestConfidence) {
          bestConfidence = _exactMatchConfidence;
          bestContact = contact;
        }
        continue;
      }

      // Bigram Dice 滑窗（窗口大小 = name.length ± 1）
      if (normalizedName.length >= 2) {
        if (normalizedName.length == 2) {
          // 2 字名特殊处理（基于标准化输入）
          for (var i = 0; i <= normalizedInput.length - 2; i++) {
            final w = normalizedInput.substring(i, i + 2);
            if (w == normalizedName) continue; // 精确匹配由上面处理
            final samePos = (w[0] == normalizedName[0] ? 1 : 0) + (w[1] == normalizedName[1] ? 1 : 0);
            // 2字名同姓不构成匹配（太宽松）：要求两字都相同，精确包含同名已由上方处理
            if (samePos >= 2 && _fuzzyMatchConfidence > bestConfidence) {
              bestConfidence = _fuzzyMatchConfidence;
              bestContact = contact;
              break;
            }
          }
        } else {
          final nameBigrams = _bigrams(normalizedName);
          for (var extra = 0; extra <= 1; extra++) {
            final windowSize = normalizedName.length + extra;
            if (windowSize > normalizedInput.length) continue;
            for (var i = 0; i <= normalizedInput.length - windowSize; i++) {
              final window = normalizedInput.substring(i, i + windowSize);
              final dice = _bigramDice(nameBigrams, _bigrams(window));
              if (dice >= _diceThreshold && dice > bestConfidence) {
                bestConfidence = _fuzzyMatchConfidence;
                bestContact = contact;
              }
            }
          }
        }
      }
    }

    if (bestContact != null && bestConfidence >= _confidenceThreshold) {
      return (bestContact, bestConfidence);
    }
    return null;
  }

  /// 提取字符串的 bigram（字符对）多重集合。
  static Map<String, int> _bigrams(String s) {
    final map = <String, int>{};
    for (var i = 0; i < s.length - 1; i++) {
      final pair = s.substring(i, i + 2);
      map[pair] = (map[pair] ?? 0) + 1;
    }
    return map;
  }

  /// Bigram Dice coefficient：2 * |intersection| / (|a| + |b|)。
  static double _bigramDice(Map<String, int> a, Map<String, int> b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    var intersection = 0;
    for (final entry in a.entries) {
      final bCount = b[entry.key];
      if (bCount != null) {
        intersection += entry.value < bCount ? entry.value : bCount;
      }
    }
    final totalA = a.values.fold(0, (s, v) => s + v);
    final totalB = b.values.fold(0, (s, v) => s + v);
    return 2 * intersection / (totalA + totalB);
  }

  // ──────────────────── 启发式人名提取 ────────────────────

  /// 常见复姓前缀。
  static const Set<String> _compoundSurnames = {
    '欧阳', '司马', '诸葛', '上官', '慕容', '令狐', '皇甫', '东方', '南宫',
    '长孙', '公孙', '尉迟', '端木',
  };

  /// 英文句首人名后常跟的动词（小写），用于逆向识别句首人名。
  static const List<String> _sentenceStartVerbs = [
    'called', 'met', 'emailed', 'asked', 'told', 'invited',
    'texted', 'messaged', 'joined', 'mentioned', 'suggested',
    'said', 'wants', 'needs', 'is', 'was', 'will',
  ];

  /// 启发式提取候选人名（中文上下文触发 + 英文 title-case 序列）。
  ///
  /// 此方法为 public static，供 [RegexFallbackNerService] 复用。
  static String? extractCandidateName(String input) {
    // 中文：基于上下文触发词的名称提取。
    // 在动词/介词后匹配 2–4 个汉字，4 字名须以复姓开头。
    // 复姓 4 字名 或 普通 2–3 字名（分开匹配，避免贪婪多取）
    final compoundSurnameStr = _compoundSurnames.join('|');
    final chineseContextPattern = RegExp(
      '(?:见了|见到|找了|找到|联系了|联系到|拜访了|认识了|约了|约到|拜见|碰了|碰到|遇到|遇见|聊到|告诉|通知|打电话给|发消息给|见|跟|和|与|给|叫|请)'
      '((?:$compoundSurnameStr)[\\u4e00-\\u9fff]{1,2}|[\\u4e00-\\u9fff]{2,3})',
    );
    final chineseMatch = chineseContextPattern.firstMatch(input);
    if (chineseMatch != null) {
      final candidate = chineseMatch.group(1)!;
      if (!_chineseStopwords.contains(candidate)) {
        return candidate;
      }
    }

    // 英文：首字母大写的单词序列，跳过句首单词（通常为动词）。
    // 特例：句首词后紧跟动词（called/met/emailed 等）则逆向提取句首词为人名。
    final wordPattern = RegExp(r'\b[A-Z][a-z]+\b');
    final allWords = wordPattern.allMatches(input).toList();

    // 句首人名检测：第一个词（或两词全名）后紧跟已知动词
    if (allWords.isNotEmpty && allWords.first.start == 0) {
      final firstWord = allWords.first;
      // 先尝试两词全名（如 "John Smith called"）
      if (allWords.length >= 2 && allWords[1].start == firstWord.end + 1) {
        final secondWord = allWords[1];
        final afterSecond = input.substring(secondWord.end).trimLeft();
        if (_sentenceStartVerbs.any((v) => afterSecond.startsWith(v))) {
          return '${firstWord.group(0)} ${secondWord.group(0)}';
        }
      }
      // 再尝试单词（如 "John called"）
      final after = input.substring(firstWord.end).trimLeft();
      if (_sentenceStartVerbs.any((v) => after.startsWith(v))) {
        return firstWord.group(0);
      }
    }

    // 先收集所有 title-case 词，再组合相邻双词人名。
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

    // 不带月份的 "X号"（如"30号开会"），推断为当月或次月
    final barePattern = RegExp(r'(?<!\d月)(?<!\d)(\d{1,2})号');
    for (final m in barePattern.allMatches(input)) {
      // 如果已被上面 X月X号 匹配覆盖，跳过
      final alreadyCovered = results.any(
        (r) => m.start >= r.start && m.end <= r.end,
      );
      if (alreadyCovered) continue;

      final day = int.tryParse(m.group(1)!);
      if (day == null || day < 1 || day > 31) continue;

      final today = DateTime(ref.year, ref.month, ref.day);
      var candidate = DateTime(ref.year, ref.month, day);
      // 如果当月该日已过，指向下个月
      if (candidate.isBefore(today)) {
        final nextMonth = ref.month == 12 ? 1 : ref.month + 1;
        final nextYear = ref.month == 12 ? ref.year + 1 : ref.year;
        candidate = DateTime(nextYear, nextMonth, day);
      }

      results.add(_TemporalMatch(
        date: candidate,
        expression: m.group(0)!,
        start: m.start,
        end: m.end,
      ));
    }

    // 中文数字日期 "X号"（如 "十七号"、"三号"、"二十号"）
    final cnDayPattern = RegExp(
      r'(三十一|三十|二十[一二三四五六七八九]|二十|十[一二三四五六七八九]|十|[一二三四五六七八九])号',
    );
    for (final m in cnDayPattern.allMatches(input)) {
      final alreadyCovered = results.any(
        (r) => m.start >= r.start && m.end <= r.end,
      );
      if (alreadyCovered) continue;

      final day = _parseCnDay(m.group(1)!);
      if (day == null || day < 1 || day > 31) continue;

      final today = DateTime(ref.year, ref.month, ref.day);
      var candidate = DateTime(ref.year, ref.month, day);
      if (candidate.isBefore(today)) {
        final nextMonth = ref.month == 12 ? 1 : ref.month + 1;
        final nextYear = ref.month == 12 ? ref.year + 1 : ref.year;
        candidate = DateTime(nextYear, nextMonth, day);
      }

      results.add(_TemporalMatch(
        date: candidate,
        expression: m.group(0)!,
        start: m.start,
        end: m.end,
      ));
    }

    return results;
  }

  /// 如果时间表达式前后紧邻时段修饰词（上午/下午/晚上），合并。
  /// 若时段词后还跟"X点[半/Y分]"，进一步提取精确时刻（如"下午两点半"→14:30）。
  _TemporalMatch _tryExtendWithTimeOfDay(
    String input,
    _TemporalMatch base,
    DateTime ref,
  ) {
    for (final entry in _timeOfDayHours.entries) {
      final tod = entry.key;
      var hour = entry.value;
      var minute = 0;

      // 时段在日期表达式之后（如"明天下午"）
      if (base.end <= input.length - tod.length &&
          input.substring(base.end, base.end + tod.length) == tod) {
        var extEnd = base.end + tod.length;

        // 尝试继续解析精确小时"X点[半/Y分]"（如"两点半"→14:30）
        final hourPat = RegExp(r'(十[一二]?|[一幺二两三四五六七八九]|\d{1,2})[点时]');
        final hm = hourPat.matchAsPrefix(input, extEnd);
        if (hm != null) {
          final parsedHour = _parseCnHour(hm.group(1)!);
          if (parsedHour != null) {
            // PM 时段（下午/傍晚/晚上）加 12；中午/AM 时段保原值
            hour = (entry.value >= 12 && parsedHour != 12)
                ? parsedHour + 12
                : parsedHour;
            extEnd = hm.end;
            // 解析分钟：半 = 30，或"X分"
            if (extEnd < input.length) {
              if (input[extEnd] == '半') {
                minute = 30;
                extEnd++;
              } else {
                final minPat = RegExp(
                  r'零?(三十|二十[一二三四五六七八九]|二十|十[一二三四五六七八九]|十|[零一二两三四五六七八九]|\d{1,2})分',
                );
                final mm = minPat.matchAsPrefix(input, extEnd);
                if (mm != null) {
                  final parsedMin = _parseCnMinute(mm.group(1)!);
                  if (parsedMin != null) {
                    minute = parsedMin;
                    extEnd = mm.end;
                  }
                }
              }
            }
          }
        }

        return _TemporalMatch(
          date: DateTime(base.date.year, base.date.month, base.date.day, hour, minute),
          expression: input.substring(base.start, extEnd),
          start: base.start,
          end: extEnd,
          // 精确小时：hourPat 命中时 isExact=true；仅时段词（如"下午"）时 isExact=false
          isExact: hm != null && _parseCnHour(hm.group(1)!) != null,
        );
      }

      // 时段在日期表达式之前（如"下午三点" — 只取时段小时，不深入解析）
      if (base.start >= tod.length &&
          input.substring(base.start - tod.length, base.start) == tod) {
        return _TemporalMatch(
          date: DateTime(base.date.year, base.date.month, base.date.day, hour),
          expression: input.substring(base.start - tod.length, base.end),
          start: base.start - tod.length,
          end: base.end,
          isExact: false,
        );
      }
    }

    return base;
  }

  /// 中文数字 → 日（1–31），支持 一 ~ 三十一。
  static int? _parseCnDay(String s) {
    const map = <String, int>{
      '一': 1, '二': 2, '三': 3, '四': 4, '五': 5,
      '六': 6, '七': 7, '八': 8, '九': 9, '十': 10,
      '十一': 11, '十二': 12, '十三': 13, '十四': 14, '十五': 15,
      '十六': 16, '十七': 17, '十八': 18, '十九': 19,
      '二十': 20, '二十一': 21, '二十二': 22, '二十三': 23, '二十四': 24,
      '二十五': 25, '二十六': 26, '二十七': 27, '二十八': 28, '二十九': 29,
      '三十': 30, '三十一': 31,
    };
    return map[s];
  }

  /// 中文十二小时制数字 → 整数（1–12），支持阿拉伯数字和中文数字词。
  static int? _parseCnHour(String s) {
    final n = int.tryParse(s);
    if (n != null) return n >= 1 && n <= 12 ? n : null;
    const map = <String, int>{
      '一': 1, '幺': 1, '二': 2, '两': 2, '三': 3, '四': 4,
      '五': 5, '六': 6, '七': 7, '八': 8, '九': 9,
      '十': 10, '十一': 11, '十二': 12,
    };
    return map[s];
  }

  /// 中文/阿拉伯分钟 → 整数（0–59）。
  static int? _parseCnMinute(String s) {
    final n = int.tryParse(s);
    if (n != null) return n >= 0 && n <= 59 ? n : null;
    const map = <String, int>{
      '零': 0, '一': 1, '二': 2, '两': 2, '三': 3, '四': 4,
      '五': 5, '六': 6, '七': 7, '八': 8, '九': 9, '十': 10,
      '十五': 15, '二十': 20, '二十五': 25, '三十': 30,
      '三十五': 35, '四十': 40, '四十五': 45, '五十': 50,
      '五十五': 55,
    };
    return map[s];
  }

  // ──────────────────── 事件标题提取 ────────────────────

  /// 中文前导填充词：去掉时间表达式后，标题开头常见的助动词/语气词/存在词。
  static final RegExp _leadingFillerPattern = RegExp(
    r'^[，,、\s]*'
    r'(?:别忘了|别忘记|记得要|不要忘了|不要忘记|一定要|'
    r'记得|需要|必须|应该|可以|要去|要来|正在|即将|要|得|去|来|给|把|将|有)',
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

  /// 无位置信息时的标题提取回退方法（当 NSDataDetector hint 存在但 Dart 正则未命中时）。
  /// 粗略删除常见时间词后应用前缀清理。
  String _extractEventTitleFallback(String input) {
    var title = input.trim();
    // 删除相对日期词
    title = title.replaceAll(RegExp(r'大后天|后天|明天|今天|昨天'), '').trim();
    // 删除周/星期表达
    title = title.replaceAll(
      RegExp(r'(?:下周|本周|这周)[一二三四五六日天]|周[一二三四五六日天]|星期[一二三四五六日天]'),
      '',
    ).trim();
    // 删除绝对日期词（如 "3月15号""15号"）
    title = title.replaceAll(RegExp(r'\d{1,2}月\d{1,2}[日号]|\d{1,2}号'), '').trim();
    // 删除时段词
    title = title.replaceAll(RegExp(r'上午|下午|晚上|中午|傍晚'), '').trim();
    // 应用前缀填充词清理
    title = title.replaceFirst(_leadingFillerPattern, '').trim();
    title = title.replaceFirst(RegExp(r'^[，,、\s]+'), '').trim();
    return title.isEmpty ? input.trim() : title;
  }

  // ──────────────────── 事件类型推断 ────────────────────

  /// 事件关键词 → 类型标签映射，按优先级从高到低排列。
  static const List<(String, String)> _eventTypeKeywords = [
    ('面试', 'interview'),
    ('聚餐', 'meal'), ('吃饭', 'meal'), ('饭局', 'meal'), ('喝酒', 'meal'), ('吃', 'meal'),
    ('开会', 'meeting'), ('会议', 'meeting'), ('碰头', 'meeting'),
    ('讨论', 'meeting'), ('站会', 'meeting'), ('评审', 'meeting'), ('review', 'meeting'),
    ('出差', 'travel'), ('飞', 'travel'), ('机场', 'travel'),
    ('截止', 'deadline'), ('交', 'deadline'), ('提交', 'deadline'), ('发版', 'deadline'),
    ('签', 'contract'), ('合同', 'contract'),
    ('培训', 'training'), ('有课', 'training'), ('学习', 'training'),
    ('demo', 'demo'), ('演示', 'demo'),
    ('发布', 'release'),
  ];

  /// 从清理后的事件标题文本推断事件类型标签。无匹配时返回 null。
  static String? _detectEventType(String title) {
    final lower = title.toLowerCase();
    for (final (keyword, type) in _eventTypeKeywords) {
      if (lower.contains(keyword.toLowerCase())) return type;
    }
    return null;
  }
}
