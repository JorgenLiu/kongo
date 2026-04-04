import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:kongo/ai/ai_service.dart';
import 'package:kongo/models/ai_job.dart';
import 'package:kongo/models/ai_output.dart';
import 'package:kongo/models/contact.dart';
import 'package:kongo/models/event.dart';
import 'package:kongo/services/quick_capture_router.dart';
import 'package:kongo/services/settings_preferences_store.dart';
import 'package:kongo/models/calendar_time_node_settings.dart';
import 'package:kongo/models/reminder_settings.dart';

class FakeSettingsStore implements SettingsPreferencesStore {
  bool _enabled;
  FakeSettingsStore(this._enabled);

  @override
  Future<bool> getQuickCaptureAiEnabled() async => _enabled;

  @override
  Future<void> setQuickCaptureAiEnabled(bool enabled) async => _enabled = enabled;

  // Minimal implementations for required methods
  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.system;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}

  @override
  Future<CalendarTimeNodeSettings> getCalendarTimeNodeSettings() async => const CalendarTimeNodeSettings();

  @override
  Future<void> setCalendarTimeNodeSettings(CalendarTimeNodeSettings settings) async {}

  @override
  Future<ReminderSettings> getReminderSettings() async => const ReminderSettings();

  @override
  Future<void> setReminderSettings(ReminderSettings settings) async {}

  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<void> setString(String key, String value) async {}

  @override
  Future<void> removeKey(String key) async {}
}

class FakeAiService implements AiService {
  final bool available;
  final AiResult? result;

  FakeAiService({required this.available, this.result});

  @override
  bool get isAvailable => available;

  @override
  Future<AiResult> execute(AiRequest request) async {
    if (result == null) throw Exception('no result');
    return result!;
  }

  @override
  Future<List<AiJob>> getJobHistory(String targetType, String targetId) async => [];

  @override
  Future<List<AiOutput>> getJobOutputs(String aiJobId) async => [];
}

void main() {
  test('uses AI when enabled and available, matches existing contact by name', () async {
    final settings = FakeSettingsStore(true);

    // AI returns contactName only (contactId field is ignored since the schema doesn't produce it)
    final aiOutput = AiOutput(
      id: Uuid().v4(),
      aiJobId: Uuid().v4(),
      outputType: 'quick_capture_parse_json',
      content: '{"contactName":"Alice","detectedDate":"2026-04-02T14:00:00Z","isTimeExact":true,"eventTitles":["Meeting"]}',
      createdAt: DateTime.now(),
    );
    final aiJob = AiJob(
      id: Uuid().v4(),
      feature: 'quick_capture_parse',
      provider: 'fake',
      targetType: 'quick_capture',
      targetId: 't1',
      createdAt: DateTime.now(),
    );

    final aiResult = AiResult(job: aiJob, output: aiOutput);
    final aiService = FakeAiService(available: true, result: aiResult);

    // Local contacts list contains Alice — router should fuzzy-match her
    final aliceContact = Contact(
      id: 'c-alice',
      name: 'Alice',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

    final resp = await routeQuickCaptureParse(
      text: '与 Alice 约在明天下午两点开会',
      settingsPreferencesStore: settings,
      aiService: aiService,
      fetchContacts: () async => [aliceContact],
      fetchEventsByDate: (d) async => <Event>[],
    );

    expect(resp['hasContact'], isTrue);
    expect(resp['contactType'], 'matched');
    expect(resp['contactId'], 'c-alice');
    expect(resp['hasEvent'], isTrue);
    expect(resp['eventTitle'], 'Meeting');
  });

  test('falls back to local parser when AI disabled', () async {
    final settings = FakeSettingsStore(false);
    final aiService = FakeAiService(available: true, result: null);

    final resp = await routeQuickCaptureParse(
      text: '明天下午三点和 Bob 吃饭',
      settingsPreferencesStore: settings,
      aiService: aiService,
      fetchContacts: () async => <Contact>[],
      fetchEventsByDate: (d) async => <Event>[],
    );

    // Local parser should detect event
    expect(resp.containsKey('hasEvent'), isTrue);
  });

  test('AI response wrapped in markdown code fence is parsed correctly', () async {
    final settings = FakeSettingsStore(true);

    // Simulate a model that wraps its JSON in ```json ... ```
    const fencedContent = '```json\n'
        '{\n'
        '  "contactName": null,\n'
        '  "contactId": null,\n'
        '  "detectedDate": "2026-09-15T09:15:00",\n'
        '  "isTimeExact": true,\n'
        '  "eventTitle": "党建",\n'
        '  "intent": "create"\n'
        '}\n'
        '```';

    final aiOutput = AiOutput(
      id: Uuid().v4(),
      aiJobId: Uuid().v4(),
      outputType: 'quick_capture_parse_json',
      content: fencedContent,
      createdAt: DateTime.now(),
    );
    final aiJob = AiJob(
      id: Uuid().v4(),
      feature: 'quick_capture_parse',
      provider: 'fake',
      targetType: 'quick_capture',
      targetId: 't1',
      createdAt: DateTime.now(),
    );

    final aiResult = AiResult(job: aiJob, output: aiOutput);
    final aiService = FakeAiService(available: true, result: aiResult);

    final resp = await routeQuickCaptureParse(
      text: '9.15党建',
      settingsPreferencesStore: settings,
      aiService: aiService,
      fetchContacts: () async => <Contact>[],
      fetchEventsByDate: (d) async => <Event>[],
    );

    // Should use AI result, not fall back to local parser
    expect(resp['hasEvent'], isTrue);
    expect(resp['eventTitle'], '党建');
    expect(resp['aiFallback'], isFalse);
  });

  test('AI response with eventTitles array produces array in response', () async {
    final settings = FakeSettingsStore(true);

    // Model returns multiple event titles for comma-separated input
    const jsonContent = '{"contactName":null,"contactId":null,'
        '"detectedDate":"2026-09-15T09:00:00",'
        '"isTimeExact":false,'
        '"eventTitles":["党建","老板ppt","人资名单","企划流程","行管采购"],'
        '"intent":"create"}';

    final aiOutput = AiOutput(
      id: Uuid().v4(),
      aiJobId: Uuid().v4(),
      outputType: 'quick_capture_parse_json',
      content: jsonContent,
      createdAt: DateTime.now(),
    );
    final aiJob = AiJob(
      id: Uuid().v4(),
      feature: 'quick_capture_parse',
      provider: 'fake',
      targetType: 'quick_capture',
      targetId: 't1',
      createdAt: DateTime.now(),
    );

    final aiResult = AiResult(job: aiJob, output: aiOutput);
    final aiService = FakeAiService(available: true, result: aiResult);

    final resp = await routeQuickCaptureParse(
      text: '9.15党建，老板ppt，人资名单，企划流程，行管采购',
      settingsPreferencesStore: settings,
      aiService: aiService,
      fetchContacts: () async => <Contact>[],
      fetchEventsByDate: (d) async => <Event>[],
    );

    expect(resp['hasEvent'], isTrue);
    expect(resp['eventTitle'], '党建'); // first item as backward-compat single title
    final titles = resp['eventTitles'] as List;
    expect(titles.length, 5);
    expect(titles, containsAll(['党建', '老板ppt', '人资名单', '企划流程', '行管采购']));
    expect(resp['aiFallback'], isFalse);
  });

  test('AI response with opening fence but missing closing fence is still parsed', () async {
    final settings = FakeSettingsStore(true);

    // Model response truncated — closing ``` is absent
    const truncatedFence = '```json\n'
        '{\n'
        '  "contactName": null,\n'
        '  "contactId": null,\n'
        '  "detectedDate": "2026-09-15T09:00:00",\n'
        '  "isTimeExact": false,\n'
        '  "eventTitles": ["党建"],\n'
        '  "intent": "create"\n'
        '}';
    // NOTE: no closing ``` here

    final aiOutput = AiOutput(
      id: Uuid().v4(),
      aiJobId: Uuid().v4(),
      outputType: 'quick_capture_parse_json',
      content: truncatedFence,
      createdAt: DateTime.now(),
    );
    final aiJob = AiJob(
      id: Uuid().v4(),
      feature: 'quick_capture_parse',
      provider: 'fake',
      targetType: 'quick_capture',
      targetId: 't1',
      createdAt: DateTime.now(),
    );

    final aiResult = AiResult(job: aiJob, output: aiOutput);
    final aiService = FakeAiService(available: true, result: aiResult);

    final resp = await routeQuickCaptureParse(
      text: '9.15党建',
      settingsPreferencesStore: settings,
      aiService: aiService,
      fetchContacts: () async => <Contact>[],
      fetchEventsByDate: (d) async => <Event>[],
    );

    expect(resp['hasEvent'], isTrue);
    expect(resp['eventTitle'], '党建');
    expect(resp['aiFallback'], isFalse);
  });

  test('AI correctly returns subject person as contactName, not secondary action reference', () async {
    // "张丽，33岁，右附件占位，需联系李主任科室"
    // 张丽 is the primary subject; 李主任 appears only in "需联系" — should NOT be contactName.
    final settings = FakeSettingsStore(true);

    const jsonContent = '{"contactName":"张丽","contactId":null,'
        '"detectedDate":null,"isTimeExact":false,'
        '"eventTitles":["右附件占位"],"intent":"create"}';

    final aiOutput = AiOutput(
      id: Uuid().v4(),
      aiJobId: Uuid().v4(),
      outputType: 'quick_capture_parse_json',
      content: jsonContent,
      createdAt: DateTime.now(),
    );
    final aiJob = AiJob(
      id: Uuid().v4(),
      feature: 'quick_capture_parse',
      provider: 'fake',
      targetType: 'quick_capture',
      targetId: 't1',
      createdAt: DateTime.now(),
    );

    final aiResult = AiResult(job: aiJob, output: aiOutput);
    final aiService = FakeAiService(available: true, result: aiResult);

    final resp = await routeQuickCaptureParse(
      text: '张丽，33岁，右附件占位，需联系李主任科室',
      settingsPreferencesStore: settings,
      aiService: aiService,
      fetchContacts: () async => <Contact>[],
      fetchEventsByDate: (d) async => <Event>[],
    );

    expect(resp['hasContact'], isTrue);
    expect(resp['contactName'], '张丽');
    expect(resp['contactType'], 'candidate');
    // eventTitles present without date — hasEvent should be true
    expect(resp['hasEvent'], isTrue);
    expect(resp['eventTitles'], ['右附件占位']);
    expect(resp.containsKey('eventDate'), isFalse);
  });

  test('AI response with eventTitles but no date still sets hasEvent true', () async {
    final settings = FakeSettingsStore(true);

    const jsonContent = '{"contactName":"方芳","detectedDate":null,'
        '"isTimeExact":false,'
        '"eventTitles":["联系广安门医院相关科室"],'
        '"contactInfoTags":[{"contact":"方芳","tags":["医疗","44岁","右附件占位"]}],"noteType":"structured"}';

    final aiOutput = AiOutput(
      id: Uuid().v4(),
      aiJobId: Uuid().v4(),
      outputType: 'quick_capture_parse_json',
      content: jsonContent,
      createdAt: DateTime.now(),
    );
    final aiJob = AiJob(
      id: Uuid().v4(),
      feature: 'quick_capture_parse',
      provider: 'fake',
      targetType: 'quick_capture',
      targetId: 't1',
      createdAt: DateTime.now(),
    );

    final aiResult = AiResult(job: aiJob, output: aiOutput);
    final aiService = FakeAiService(available: true, result: aiResult);

    final resp = await routeQuickCaptureParse(
      text: '方芳，44岁，右附件占位，需联系广安门医院相关科室',
      settingsPreferencesStore: settings,
      aiService: aiService,
      fetchContacts: () async => <Contact>[],
      fetchEventsByDate: (d) async => <Event>[],
    );

    expect(resp['hasContact'], isTrue);
    expect(resp['contactName'], '方芳');
    expect(resp['hasEvent'], isTrue);
    expect(resp['eventTitles'], ['联系广安门医院相关科室']);
    // No date was provided, so eventDate should not be set
    expect(resp.containsKey('eventDate'), isFalse);
    // Tags should include attributes
    final contactInfoTags = resp['contactInfoTags'] as List;
    final allTags = <String>[];
    for (final entry in contactInfoTags) {
      if (entry is Map) {
        final tags = entry['tags'] as List?;
        if (tags != null) allTags.addAll(tags.cast<String>());
      }
    }
    expect(allTags, containsAll(['医疗', '44岁', '右附件占位']));
  });

  test('AI response with tags array is passed through in response', () async {
    final settings = FakeSettingsStore(true);

    const jsonContent = '{"contactName":"张丽","detectedDate":null,'
        '"isTimeExact":false,"eventTitles":null,'
        '"contactInfoTags":[{"contact":"张丽","tags":["医疗","随访"]}],"noteType":"structured"}';

    final aiOutput = AiOutput(
      id: Uuid().v4(),
      aiJobId: Uuid().v4(),
      outputType: 'quick_capture_parse_json',
      content: jsonContent,
      createdAt: DateTime.now(),
    );
    final aiJob = AiJob(
      id: Uuid().v4(),
      feature: 'quick_capture_parse',
      provider: 'fake',
      targetType: 'quick_capture',
      targetId: 't1',
      createdAt: DateTime.now(),
    );

    final aiResult = AiResult(job: aiJob, output: aiOutput);
    final aiService = FakeAiService(available: true, result: aiResult);

    final resp = await routeQuickCaptureParse(
      text: '张丽，33岁，右附件占位',
      settingsPreferencesStore: settings,
      aiService: aiService,
      fetchContacts: () async => <Contact>[],
      fetchEventsByDate: (d) async => <Event>[],
    );

    expect(resp['hasContact'], isTrue);
    expect(resp['contactName'], '张丽');
    final contactInfoTags = resp['contactInfoTags'] as List;
    final entry = contactInfoTags.first as Map;
    expect(entry['tags'], containsAll(['医疗', '随访']));
  });

  // ── Task 4 新增测试 ──────────────────────────────────────────────────────────

  test('aiFallback is true when AI is available but throws an exception', () async {
    final settings = FakeSettingsStore(true);
    // FakeAiService with available=true but result=null → execute() throws
    final aiService = FakeAiService(available: true, result: null);

    final resp = await routeQuickCaptureParse(
      text: '明天下午开会',
      settingsPreferencesStore: settings,
      aiService: aiService,
      fetchContacts: () async => <Contact>[],
      fetchEventsByDate: (d) async => <Event>[],
    );

    expect(resp['aiFallback'], isTrue);
  });

  test('aiFallback is false when AI is disabled', () async {
    final settings = FakeSettingsStore(false);
    final aiService = FakeAiService(available: true, result: null);

    final resp = await routeQuickCaptureParse(
      text: '明天下午开会',
      settingsPreferencesStore: settings,
      aiService: aiService,
      fetchContacts: () async => <Contact>[],
      fetchEventsByDate: (d) async => <Event>[],
    );

    expect(resp['aiFallback'], isFalse);
  });

  test('AI contactName with no local match returns contactType candidate', () async {
    final settings = FakeSettingsStore(true);

    final aiOutput = AiOutput(
      id: Uuid().v4(),
      aiJobId: Uuid().v4(),
      outputType: 'quick_capture_parse_json',
      content: '{"contactName":"新人王五","detectedDate":null,"isTimeExact":false,"eventTitles":null}',
      createdAt: DateTime.now(),
    );
    final aiJob = AiJob(
      id: Uuid().v4(),
      feature: 'quick_capture_parse',
      provider: 'fake',
      targetType: 'quick_capture',
      targetId: 't1',
      createdAt: DateTime.now(),
    );
    final aiService = FakeAiService(available: true, result: AiResult(job: aiJob, output: aiOutput));

    final resp = await routeQuickCaptureParse(
      text: '新人王五今天入职了',
      settingsPreferencesStore: settings,
      aiService: aiService,
      fetchContacts: () async => <Contact>[],  // empty — no match
      fetchEventsByDate: (d) async => <Event>[],
    );

    expect(resp['contactType'], 'candidate');
    expect(resp.containsKey('contactId'), isFalse);
  });

  test('eventGroups with single entry returns normal response, not multiResult', () async {
    final settings = FakeSettingsStore(true);

    const jsonContent = '{"contactName":null,"detectedDate":null,"isTimeExact":false,'
        '"eventGroups":[{"date":"2026-04-05T09:00:00","isTimeExact":false,"titles":["周会"]}]}';

    final aiOutput = AiOutput(
      id: Uuid().v4(),
      aiJobId: Uuid().v4(),
      outputType: 'quick_capture_parse_json',
      content: jsonContent,
      createdAt: DateTime.now(),
    );
    final aiJob = AiJob(
      id: Uuid().v4(),
      feature: 'quick_capture_parse',
      provider: 'fake',
      targetType: 'quick_capture',
      targetId: 't1',
      createdAt: DateTime.now(),
    );
    final aiService = FakeAiService(available: true, result: AiResult(job: aiJob, output: aiOutput));

    final resp = await routeQuickCaptureParse(
      text: '周日上午开周会',
      settingsPreferencesStore: settings,
      aiService: aiService,
      fetchContacts: () async => <Contact>[],
      fetchEventsByDate: (d) async => <Event>[],
    );

    // Single eventGroup must NOT produce multiResult
    expect(resp.containsKey('multiResult'), isFalse);
    expect(resp['hasEvent'], isTrue);
    expect(resp['eventTitle'], '周会');
    expect(resp['eventDate'], isNotNull);
  });

  test('eventGroups with two entries returns multiResult with items', () async {
    final settings = FakeSettingsStore(true);

    const jsonContent = '{"contactName":"张三","detectedDate":null,"isTimeExact":false,'
        '"eventGroups":['
        '{"date":"2026-04-05T14:00:00","isTimeExact":false,"titles":["与张三开会"]},'
        '{"date":"2026-04-09T10:00:00","isTimeExact":false,"titles":["与张三面试候选人"]}'
        ']}';

    final aiOutput = AiOutput(
      id: Uuid().v4(),
      aiJobId: Uuid().v4(),
      outputType: 'quick_capture_parse_json',
      content: jsonContent,
      createdAt: DateTime.now(),
    );
    final aiJob = AiJob(
      id: Uuid().v4(),
      feature: 'quick_capture_parse',
      provider: 'fake',
      targetType: 'quick_capture',
      targetId: 't1',
      createdAt: DateTime.now(),
    );
    final aiService = FakeAiService(available: true, result: AiResult(job: aiJob, output: aiOutput));

    final resp = await routeQuickCaptureParse(
      text: '和张三周日下午开会，周四上午面试候选人',
      settingsPreferencesStore: settings,
      aiService: aiService,
      fetchContacts: () async => <Contact>[],
      fetchEventsByDate: (d) async => <Event>[],
    );

    expect(resp['multiResult'], isTrue);
    final items = resp['items'] as List;
    expect(items.length, 2);
    expect((items[0] as Map)['eventTitle'], '与张三开会');
    expect((items[1] as Map)['eventTitle'], '与张三面试候选人');
    // 批量中第一项 isFirstInBatch=true，后续项为 false
    expect((items[0] as Map)['isFirstInBatch'], isTrue);
    expect((items[1] as Map)['isFirstInBatch'], isFalse);
  });

  test('eventGroups per-group contacts are fuzzy-matched against local contacts', () async {
    final settings = FakeSettingsStore(true);
    final huaqiContact = Contact(
      id: 'c-huaqi',
      name: 'huaqi',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    const jsonContent = '{"contactName":null,"detectedDate":null,"isTimeExact":false,'
        '"eventGroups":['
        '{"date":"2026-04-07","isTimeExact":false,"titles":["过一下重构"],"contacts":["huaqi"]},'
        '{"date":"2026-04-09","isTimeExact":false,"titles":["改刷数据脚本"],"contacts":null}'
        ']}';

    final aiOutput = AiOutput(
      id: Uuid().v4(),
      aiJobId: Uuid().v4(),
      outputType: 'quick_capture_parse_json',
      content: jsonContent,
      createdAt: DateTime.now(),
    );
    final aiJob = AiJob(
      id: Uuid().v4(),
      feature: 'quick_capture_parse',
      provider: 'fake',
      targetType: 'quick_capture',
      targetId: 't1',
      createdAt: DateTime.now(),
    );
    final aiService = FakeAiService(available: true, result: AiResult(job: aiJob, output: aiOutput));

    final resp = await routeQuickCaptureParse(
      text: '下周二和huaqi过一下重构，周四正式开始改刷数据脚本',
      settingsPreferencesStore: settings,
      aiService: aiService,
      fetchContacts: () async => [huaqiContact],
      fetchEventsByDate: (d) async => <Event>[],
    );

    expect(resp['multiResult'], isTrue);
    final items = resp['items'] as List;
    expect(items.length, 2);
    // 第一组有 contacts=["huaqi"]，应匹配到本地联系人
    final item0 = items[0] as Map;
    expect(item0['hasContact'], isTrue);
    expect(item0['contactType'], 'matched');
    expect(item0['contactId'], 'c-huaqi');
    // 第二组 contacts=null，不应强制绑定联系人
    final item1 = items[1] as Map;
    expect(item1['hasContact'], isFalse);
  });
}
