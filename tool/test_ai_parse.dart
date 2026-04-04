/// 独立测试脚本：验证硅基流动 AI 对 Quick Capture 输入的解析能力。
///
/// 用法（需要先 export API_KEY=your_key）：
///   dart run tool/test_ai_parse.dart
///
/// 输出每条输入的解析结果，并统计 token 用量和延迟。

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _baseUrl = 'https://api.siliconflow.cn/v1';
const _model = 'deepseek-ai/DeepSeek-V3';

/// 20 条测试数据，涵盖：
///   - 多事件（逗号并列）
///   - 不规范时间格式（9.15, 14:30, "两个小时后"）
///   - 多联系人
///   - 中英文混合
///   - 无时间纯联系人
///   - 无联系人纯时间
///   - 复杂上下文
const List<String> _testInputs = [
  // 多事件 + 不规范时间
  '周日上午9.15党建，老板ppt，人资名单，企划流程，行管采购',
  '下午2.30和李总开会，3.45做市场汇报，5点和供应商结账',

  // 多联系人
  '明天约张三和王五一起去面试，下午三点',
  '今天下午跟 Sarah、Amy、刘明 三人 sync 了项目进展',

  // 多联系人 + 多事件混合
  '周三上午跟CTO和PM讨论Q2路线图，周四下午给BD团队做demo',

  // 不规范时间格式
  '两个小时后和客户打电话',
  '今晚8.30和老婆一起看电影',
  '明天早9.00要交季度报告',

  // 联系人 + 事件 + 标签语义
  '约前同事赵磊吃午饭，他现在在字节跳动做增长',
  '联系猎头Emma，推了个字节的Sr. PM机会',
  '王总（老客户）说合同下周签，跟进一下',

  // 纯多事件，同一时间
  '明天上午：站会、code review、写周报',
  '周一要做的事：更新简历，练习面试，整理Github',

  // 跨天多事件
  '周三去北京出差，跟客户吃饭；周五回来要做总结汇报',

  // 复杂上下文，隐含关系
  '和陈工讨论了一下，问题在底层网络层，明天他来修',
  '林总说Q3预算审批下来了，让我们下周五去签MOU',

  // 英文/数字混合
  '跟 Victor 在 3pm 敲定了 Series A term sheet 细节',
  'Amy tomorrow 9am onboarding call, send her the doc before that',

  // 无时间纯联系人
  '认识了一个投资人叫朱峰，做早期消费，在红杉',

  // 无联系人纯时间事件
  '后天下午四点半要去体检',
];

const _systemPrompt = '''
你是一个专业的信息提取助手。请从用户输入中提取所有结构化信息。

返回严格的 JSON 格式，结构如下：
{
  "events": [
    {
      "title": "事件标题（简洁，2-10字）",
      "datetime": "ISO 8601格式，无法确定则null",
      "datetime_confidence": "exact|inferred|date_only|none",
      "is_recurring": false
    }
  ],
  "contacts": [
    {
      "name": "姓名",
      "relation_hint": "可推断的关系/职位（如：同事、客户、猎头），无则null",
      "org_hint": "可推断的公司/组织，无则null",
      "role_hint": "可推断的职位，无则null"
    }
  ],
  "tags": ["可以标注在联系人或事件上的标签，如：字节跳动、投资、出差"],
  "raw_note": "无法结构化的剩余内容，无则null"
}

规则：
- 同一时间点的多个并列事项，每项单独一条 event
- 时间格式如 9.15、9:15、14:30、下午两点 都要识别
- "两个小时后" 这类相对时间记录 datetime_confidence 为 "inferred"，datetime 留 null
- 人名要准确，不要将公司名、地名当人名
- 严格返回 JSON，不要有任何解释文字
''';

Future<void> main() async {
  final apiKey = Platform.environment['API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('❌ 请先设置环境变量：export API_KEY=your_key');
    exit(1);
  }

  final client = http.Client();
  var totalPromptTokens = 0;
  var totalCompletionTokens = 0;
  var successCount = 0;
  var failCount = 0;

  print('═' * 60);
  print('AI 解析能力测试  模型：$_model');
  print('共 ${_testInputs.length} 条测试数据');
  print('═' * 60);

  for (var i = 0; i < _testInputs.length; i++) {
    final input = _testInputs[i];
    print('\n[${i + 1}/${_testInputs.length}] 输入：「$input」');

    final stopwatch = Stopwatch()..start();
    try {
      final response = await client
          .post(
            Uri.parse('$_baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {'role': 'user', 'content': input},
              ],
              'temperature': 0.1,
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(const Duration(seconds: 30));

      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;

      if (response.statusCode != 200) {
        print('  ❌ HTTP ${response.statusCode}: ${response.body}');
        failCount++;
        continue;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = payload['choices'] as List;
      final content = choices.first['message']['content'] as String;
      final usage = payload['usage'] as Map<String, dynamic>?;
      final promptTok = usage?['prompt_tokens'] as int? ?? 0;
      final completionTok = usage?['completion_tokens'] as int? ?? 0;
      totalPromptTokens += promptTok;
      totalCompletionTokens += completionTok;

      // 格式化输出
      try {
        final parsed = jsonDecode(content) as Map<String, dynamic>;
        final events = (parsed['events'] as List? ?? []);
        final contacts = (parsed['contacts'] as List? ?? []);
        final tags = (parsed['tags'] as List? ?? []);

        print('  ✅ ${ms}ms  prompt:$promptTok  completion:$completionTok');
        if (events.isNotEmpty) {
          print('  📅 事件（${events.length}条）：');
          for (final e in events) {
            final dt = e['datetime'] ?? '无时间';
            final conf = e['datetime_confidence'] ?? '';
            print('     • ${e['title']}  [$dt] ($conf)');
          }
        }
        if (contacts.isNotEmpty) {
          print('  👤 联系人（${contacts.length}条）：');
          for (final c in contacts) {
            final rel = c['relation_hint'] ?? '';
            final org = c['org_hint'] ?? '';
            final role = c['role_hint'] ?? '';
            final hint = [rel, org, role].where((s) => s.isNotEmpty).join(' / ');
            print('     • ${c['name']}${hint.isNotEmpty ? '  [$hint]' : ''}');
          }
        }
        if (tags.isNotEmpty) {
          print('  🏷️  标签：${tags.join('、')}');
        }
        successCount++;
      } catch (_) {
        print('  ⚠️  JSON 解析失败，原始内容：');
        print('  $content');
        failCount++;
      }
    } catch (e) {
      stopwatch.stop();
      print('  ❌ 请求异常：$e');
      failCount++;
    }
  }

  print('\n${'═' * 60}');
  print('测试完成：成功 $successCount / 失败 $failCount');
  print('累计 tokens：prompt=$totalPromptTokens  completion=$totalCompletionTokens');
  final totalTok = totalPromptTokens + totalCompletionTokens;
  // 硅基流动 DeepSeek-V3 价格（2026年参考）：¥2 / M tokens
  final estimatedCost = totalTok / 1_000_000 * 2.0;
  print('估算费用（¥2/M tokens）：¥${estimatedCost.toStringAsFixed(4)}');
  print('═' * 60);

  client.close();
}
