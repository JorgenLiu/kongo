import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../ai/ai_provider.dart';
import '../ai/ai_service.dart';
import '../models/event.dart';
import '../models/contact.dart';
import 'quick_capture_parser.dart';

import '../services/settings_preferences_store.dart';

/// Route quick-capture parsing: decide AI vs local parser and return response map.
Future<Map<String, dynamic>> routeQuickCaptureParse({
  required String text,
  List<String> nerHints = const [],
  List<String> dateHints = const [],
  required SettingsPreferencesStore settingsPreferencesStore,
  required AiService aiService,
  required Future<List<Contact>> Function() fetchContacts,
  required Future<List<Event>> Function(DateTime) fetchEventsByDate,
}) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return {'hasContact': false, 'hasEvent': false};

  final contacts = await fetchContacts();

  final useAi = await settingsPreferencesStore.getQuickCaptureAiEnabled();
  var attemptedAi = false;
  if (useAi && aiService.isAvailable) {
    attemptedAi = true;
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final systemPrompt = '''Today is $today.
You are a quick-capture note parser for a personal CRM. Given the user's free-text input, extract structured information and return a single JSON object.

## Output schema

{
  "contactName": string | null,
  "detectedDate": string | null,
  "isTimeExact": boolean,
  "eventTitles": string[] | null,
  "eventGroups": [{"date": string, "isTimeExact": boolean, "titles": string[], "contacts": string[] | null}] | null,
  "contactInfoTags": [{"contact": string, "tags": string[]}] | null,
  "noteType": "structured" | "knowledge"
}

## Field rules

**contactName** — The primary person being described (the grammatical subject of the note). If no person is the main topic, null. Names mentioned only as secondary references in action phrases（如"需联系XX"、"告诉XX"、"转交XX"）are NOT the primary contact.

**detectedDate** — ISO 8601 date or datetime. Resolve relative expressions against today ($today): "明天" = tomorrow, "周日" = nearest upcoming Sunday, "9.15" = $today's year-09-15. Include time when stated (e.g. "下午三点" → T15:00:00). Null when no temporal expression exists.

**isTimeExact** — true only when a specific clock time is present (e.g. "三点半", "14:00", "9:15"). False for date-only or vague periods ("下午", "晚上").

**eventTitles** — Array of distinct event/task titles extracted from the input. Split comma / 、-separated items into individual entries. Null if the input describes no event or task. Only use this field when all events share the same date (or there is no date).
**Do NOT use the entire input sentence as a title.** If no clear, short event or task phrase can be extracted, set `eventTitles` to null. Prefer concise action-oriented phrases (aim for under 20 characters per title).

**eventGroups** — When events span multiple distinct dates, group them here instead of using `eventTitles`. Each entry: {"date": "ISO 8601 date or datetime", "isTimeExact": boolean, "titles": ["...", ...], "contacts": ["name1", ...] | null}. The "contacts" field lists all people directly involved in that specific event, by their exact names as written in the input. Resolve dates the same way as `detectedDate`. Omit this field when all events share one date.
`eventGroups` MAY contain only one entry. Use it whenever the input contains explicit per-date grouping, even for a single date, to preserve the date-to-titles association.

**contactInfoTags** — Per-contact attribute tags. For each person mentioned in the input, extract any observable facts about them: age, health conditions, roles, titles, traits, preferences, or any other noteworthy attributes. Return as an array of {"contact": "<name>", "tags": ["attr1", "attr2"]}. Cover all named persons, not just the primary contact. Null if no attributes can be inferred. Max 5 tags per person.
The `contact` field MUST exactly match the name as it appears in the input. Do not infer or merge attributes from one person onto another. Each entry must only contain facts clearly attributable to that specific named person.

**noteType** — "structured" if a contact or event was identified; "knowledge" if the input is pure information with no person or event.

## Guidelines
- Only output the JSON object. No markdown fences, no commentary.
- Prefer precision over recall: leave a field null rather than guess.
- Do not invent information not present in the input.''';

      final aiRequest = AiRequest(
        feature: 'quick_capture_parse',
        targetType: 'quick_capture',
        targetId: 'quick_capture_${DateTime.now().millisecondsSinceEpoch}',
        outputType: 'quick_capture_parse_json',
        messages: [
          AiMessage.system(systemPrompt),
          AiMessage.user(trimmed),
        ],
      );

      final aiResult = await aiService.execute(aiRequest);
      final content = aiResult.output.content.trim();
      if (kDebugMode) {
        debugPrint('[QuickCapture] AI raw response: $content');
      }
      try {
        // Strip markdown code fence if model wrapped the JSON in ```json ... ```
        final jsonStr = _stripCodeFence(content);
        final parsed = jsonStr != null ? Map<String, dynamic>.from(jsonDecode(jsonStr)) : null;
        if (kDebugMode) {
          debugPrint('[QuickCapture] AI parsed JSON: $parsed');
        }
        if (parsed != null) {
          final response = <String, dynamic>{};
          final contactName = parsed['contactName'] as String?;
          if (contactName != null && contactName.isNotEmpty) {
            response['hasContact'] = true;
            response['contactName'] = contactName;
            // 尝试对本地联系人库做 fuzzy match：第一优先精确一致，其次包含关系
            final matched = contacts.where((c) =>
                c.name == contactName ||
                c.name.contains(contactName) ||
                contactName.contains(c.name)
            ).firstOrNull;
            if (matched != null) {
              response['contactType'] = 'matched';
              response['contactId'] = matched.id;
            } else {
              response['contactType'] = 'candidate';
            }
          } else {
            response['hasContact'] = false;
          }

          // Extract eventTitles independently of date
          final rawTitles = parsed['eventTitles'];
          final List<String> eventTitles;
          if (rawTitles is List && rawTitles.isNotEmpty) {
            eventTitles = rawTitles.map((t) => t.toString().trim()).where((t) => t.isNotEmpty).toList();
          } else {
            final single = (parsed['eventTitle'] as String?)?.trim();
            eventTitles = (single != null && single.isNotEmpty) ? [single] : [];
          }

          // Parse date if present
          final detectedDateStr = parsed['detectedDate'] as String?;
          DateTime? d;
          if (detectedDateStr != null) {
            try {
              d = DateTime.parse(detectedDateStr);
            } catch (_) {}
          }

          // Extract per-contact info tags early (needed by both single and multi-date paths)
          final rawContactInfoTags = parsed['contactInfoTags'];

          // Multi-date event groups: return as multiResult queue items
          final rawEventGroups = parsed['eventGroups'];
          if (rawEventGroups is List && rawEventGroups.isNotEmpty) {
            // 并发预取所有不重复日期的已有事件，避免循环内串行查询
            final uniqueDateStrs = rawEventGroups
                .whereType<Map>()
                .map((g) => g['date'] as String?)
                .whereType<String>()
                .toSet();
            final dateEventsMap = Map.fromEntries(
              await Future.wait(uniqueDateStrs.map((ds) async {
                final d = DateTime.tryParse(ds);
                if (d == null) return MapEntry(ds, <Event>[]);
                return MapEntry(ds, await fetchEventsByDate(d));
              })),
            );

            final items = <Map<String, dynamic>>[];
            for (final rawGroup in rawEventGroups) {
              if (rawGroup is! Map) continue;
              final groupDateStr = rawGroup['date'] as String?;
              final groupIsTimeExact = rawGroup['isTimeExact'] == true;
              final rawGroupTitles = rawGroup['titles'];
              final List<String> groupTitles;
              if (rawGroupTitles is List && rawGroupTitles.isNotEmpty) {
                groupTitles = rawGroupTitles.map((t) => t.toString().trim()).where((t) => t.isNotEmpty).toList();
              } else {
                groupTitles = [];
              }
              if (groupTitles.isEmpty) continue;
              final item = Map<String, dynamic>.from(response);
              item['hasEvent'] = true;
              item['eventTitles'] = groupTitles;
              item['eventTitle'] = groupTitles.first;
              item['isTimeExact'] = groupIsTimeExact;
              if (groupDateStr != null) {
                try {
                  final groupDate = DateTime.parse(groupDateStr);
                  item['eventDate'] = groupDate.toIso8601String();
                  final existingEvents = dateEventsMap[groupDateStr] ?? [];
                  if (existingEvents.isNotEmpty) {
                    item['existingEvents'] = existingEvents
                        .map((e) => {'id': e.id, 'title': e.title, 'startAt': e.startAt?.toIso8601String()})
                        .toList();
                  }
                } catch (_) {}
              }
              if (rawContactInfoTags is List && rawContactInfoTags.isNotEmpty) {
                item['contactInfoTags'] = rawContactInfoTags;
              }
              // 每组可独立指定参与人：若 AI 给了 contacts 字段则覆盖顶层联系人
              final rawGroupContacts = rawGroup['contacts'];
              if (rawGroupContacts is List && rawGroupContacts.isNotEmpty) {
                final primaryName = rawGroupContacts.first.toString().trim();
                if (primaryName.isNotEmpty) {
                  final matched = contacts.where((c) =>
                      c.name == primaryName ||
                      c.name.contains(primaryName) ||
                      primaryName.contains(c.name)
                  ).firstOrNull;
                  if (matched != null) {
                    item['hasContact'] = true;
                    item['contactType'] = 'matched';
                    item['contactId'] = matched.id;
                    item['contactName'] = matched.name;
                  } else {
                    item['hasContact'] = true;
                    item['contactType'] = 'candidate';
                    item['contactName'] = primaryName;
                    item.remove('contactId');
                  }
                }
              }
              item['aiFallback'] = false;
              items.add(item);
            }
            if (items.isNotEmpty) {
              if (kDebugMode) debugPrint('[QuickCapture] Multi-date groups: ${items.length} items');
              if (items.length == 1) return items.first;  // 单组退化为普通响应
              // 批量中第一项标记 isFirstInBatch=true，后续项标记 false，防止 note 重复保存
              for (var i = 0; i < items.length; i++) {
                items[i]['isFirstInBatch'] = i == 0;
              }
              return {'multiResult': true, 'items': items};
            }
          }

          if (eventTitles.isNotEmpty) {
            response['hasEvent'] = true;
            response['eventTitles'] = eventTitles;
            response['eventTitle'] = eventTitles.first;
            response['isTimeExact'] = parsed['isTimeExact'] == true;
            if (parsed['eventType'] != null) response['eventType'] = parsed['eventType'];
            if (d != null) {
              response['eventDate'] = d.toIso8601String();
              final existingEvents = await fetchEventsByDate(d);
              if (existingEvents.isNotEmpty) {
                response['existingEvents'] = existingEvents
                    .map((e) => {
                          'id': e.id,
                          'title': e.title,
                          'startAt': e.startAt?.toIso8601String(),
                        })
                    .toList();
              }
            }
          } else if (d != null) {
            // Date found but no explicit event titles — use input as title
            response['hasEvent'] = true;
            response['eventDate'] = d.toIso8601String();
            response['isTimeExact'] = parsed['isTimeExact'] == true;
            response['eventTitles'] = [trimmed];
            response['eventTitle'] = trimmed;
            final existingEvents = await fetchEventsByDate(d);
            if (existingEvents.isNotEmpty) {
              response['existingEvents'] = existingEvents
                  .map((e) => {
                        'id': e.id,
                        'title': e.title,
                        'startAt': e.startAt?.toIso8601String(),
                      })
                  .toList();
            }
          } else {
            response['hasEvent'] = false;
          }

          // Per-contact info tags suggested by AI
          if (rawContactInfoTags is List && rawContactInfoTags.isNotEmpty) {
            response['contactInfoTags'] = rawContactInfoTags;
          }

          response['aiFallback'] = false;
          if (kDebugMode) {
            debugPrint('[QuickCapture] AI path response: $response');
          }
          return response;
        }
      } catch (_) {
        // fallthrough to local parser
      }
    } catch (_) {
      // fallthrough to local parser
    }
  }

  // AI not used or failed — run local parser and mark aiFallback if AI was attempted
  if (kDebugMode) {
    debugPrint('[QuickCapture] Local parser path. nerHints=$nerHints  dateHints=$dateHints');
  }
  final parser = QuickCaptureParser();
  final result = parser.parse(trimmed, contacts, nerHints: nerHints, dateHints: dateHints);

  final response = <String, dynamic>{};
  if (result.matchedContact != null) {
    response['hasContact'] = true;
    response['contactType'] = 'matched';
    response['contactName'] = result.matchedContact!.name;
    response['contactId'] = result.matchedContact!.id;
    // 保留原始提取名（用户实际输入的名字），供UI"新建联系人"使用
    if (result.candidateNewName != null && result.candidateNewName!.isNotEmpty) {
      response['originalName'] = result.candidateNewName!;
    }
  } else if (result.candidateNewName != null) {
    response['hasContact'] = true;
    response['contactType'] = 'candidate';
    response['contactName'] = result.candidateNewName!;
  } else {
    response['hasContact'] = false;
  }

  if (result.detectedDate != null) {
    response['hasEvent'] = true;
    response['eventDate'] = result.detectedDate!.toIso8601String();
    response['isTimeExact'] = result.isTimeExact;
    final localTitle = result.suggestedEventTitle ?? trimmed;
    response['eventTitle'] = localTitle;
    response['eventTitles'] = [localTitle];
    if (result.detectedEventType != null) response['eventType'] = result.detectedEventType;

    final existingEvents = await fetchEventsByDate(result.detectedDate!);
    if (existingEvents.isNotEmpty) {
      response['existingEvents'] = existingEvents
          .map((e) => {
                'id': e.id,
                'title': e.title,
                'startAt': e.startAt?.toIso8601String(),
              })
          .toList();
    }
  } else {
    response['hasEvent'] = false;
  }

  // AI 被尝试但失败时展示 fallback banner；未启用 AI 时静默
  response['aiFallback'] = attemptedAi;

  if (kDebugMode) {
    debugPrint('[QuickCapture] Local parser response: $response');
  }
  return response;
}

/// Strip a markdown code fence (```json … ``` or ``` … ```) and return the
/// inner JSON string.  Returns the original trimmed string if it already starts
/// with '{', or null if no JSON object can be found.
/// Also handles responses where the model forgot to close the fence.
String? _stripCodeFence(String content) {
  final trimmed = content.trim();
  if (trimmed.startsWith('{')) return trimmed;
  // Match ```[lang]\n{ ... }\n``` (with or without closing fence)
  final withFence = RegExp(r'```[a-z]*\s*({[\s\S]*})\s*```').firstMatch(trimmed);
  if (withFence != null) return withFence.group(1)!.trim();
  // Fallback: opening fence present but closing fence absent — extract content after the fence header
  final openFence = RegExp(r'```[a-z]*\s*({[\s\S]*)').firstMatch(trimmed);
  if (openFence != null) {
    final candidate = openFence.group(1)!.trim();
    if (candidate.startsWith('{')) return candidate;
  }
  return null;
}
