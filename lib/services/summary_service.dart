import 'package:uuid/uuid.dart';

import '../exceptions/app_exception.dart';
import '../models/action_item.dart';
import '../models/attachment_link.dart';
import '../models/event_summary.dart';
import '../models/event_summary_draft.dart';
import '../repositories/attachment_repository.dart';
import '../repositories/summary_repository.dart';
import '../utils/action_item_parser.dart';
import '../utils/text_normalize.dart';

abstract class SummaryService {
  Future<List<DailySummary>> getSummaries();
  Future<List<DailySummary>> searchByKeyword(String keyword);
  Future<DailySummary?> getSummaryByDate(DateTime summaryDate);
  Future<DailySummary> getSummary(String id);
  Future<DailySummary> createSummary(DailySummaryDraft draft);
  Future<DailySummary> updateSummary(DailySummary summary);
  Future<void> deleteSummary(String id);
  Future<List<ActionItem>> extractActionItemsFromSummary(String summaryId);
}

class DefaultSummaryService implements SummaryService {
  final SummaryRepository _summaryRepository;
  final AttachmentRepository _attachmentRepository;
  final Uuid _uuid;

  DefaultSummaryService(
    this._summaryRepository,
    this._attachmentRepository, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  @override
  Future<List<DailySummary>> getSummaries() {
    return _summaryRepository.getAll();
  }

  @override
  Future<List<DailySummary>> searchByKeyword(String keyword) {
    return _summaryRepository.searchByKeyword(keyword);
  }

  @override
  Future<DailySummary?> getSummaryByDate(DateTime summaryDate) {
    return _summaryRepository.getByDate(summaryDate);
  }

  @override
  Future<DailySummary> getSummary(String id) {
    return _summaryRepository.getById(id);
  }

  @override
  Future<DailySummary> createSummary(DailySummaryDraft draft) async {
    final normalizedTodaySummary = draft.todaySummary.trim();
    final normalizedTomorrowPlan = draft.tomorrowPlan.trim();
    if (normalizedTodaySummary.isEmpty && normalizedTomorrowPlan.isEmpty) {
      throw const ValidationException(message: '当日总结和明日计划至少填写一项', code: 'summary_content_required');
    }

    final normalizedDate = _normalizeDate(draft.summaryDate);
    final existing = await _summaryRepository.getByDate(normalizedDate);
    if (existing != null) {
      throw const BusinessException(message: '该日期的总结已存在', code: 'summary_date_exists');
    }

    final now = DateTime.now();
    final summary = DailySummary(
      id: _uuid.v4(),
      summaryDate: normalizedDate,
      todaySummary: normalizedTodaySummary,
      tomorrowPlan: normalizedTomorrowPlan,
      source: draft.source,
      createdByContactId: normalizeOptionalText(draft.createdByContactId),
      aiJobId: normalizeOptionalText(draft.aiJobId),
      createdAt: now,
      updatedAt: now,
    );

    return _summaryRepository.insert(summary);
  }

  @override
  Future<DailySummary> updateSummary(DailySummary summary) async {
    if (summary.todaySummary.trim().isEmpty && summary.tomorrowPlan.trim().isEmpty) {
      throw const ValidationException(message: '当日总结和明日计划至少填写一项', code: 'summary_content_required');
    }

    final existing = await _summaryRepository.getById(summary.id);
    final summaryAtSameDate = await _summaryRepository.getByDate(summary.summaryDate);
    if (summaryAtSameDate != null && summaryAtSameDate.id != summary.id) {
      throw const BusinessException(message: '该日期的总结已存在', code: 'summary_date_exists');
    }

    return _summaryRepository.update(
      summary.copyWith(
        summaryDate: _normalizeDate(summary.summaryDate),
        todaySummary: summary.todaySummary.trim(),
        tomorrowPlan: summary.tomorrowPlan.trim(),
        source: summary.source,
        createdByContactId: normalizeOptionalText(summary.createdByContactId),
        aiJobId: normalizeOptionalText(summary.aiJobId),
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteSummary(String id) async {
    await _summaryRepository.getById(id);
    await _attachmentRepository.unlinkAllByOwner(AttachmentOwnerType.summary, id);
    await _summaryRepository.delete(id);
  }

  @override
  Future<List<ActionItem>> extractActionItemsFromSummary(String summaryId) async {
    final summary = await _summaryRepository.getById(summaryId);
    final combinedContent = [summary.tomorrowPlan, summary.todaySummary]
        .where((section) => section.trim().isNotEmpty)
        .join('\n');

    return parseActionItems(combinedContent);
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}