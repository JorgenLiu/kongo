import '../../models/action_item.dart';
import '../../models/attachment.dart';
import '../../models/attachment_link.dart';
import '../../models/event_summary.dart';
import '../../repositories/attachment_repository.dart';
import '../../repositories/summary_repository.dart';
import '../../utils/action_item_parser.dart';

abstract class SummaryReadService {
  Future<SummaryDetailReadModel> getSummaryDetail(String summaryId);
  Future<SummaryDetailReadModel?> getSummaryDetailByDate(DateTime summaryDate);
}

class DefaultSummaryReadService implements SummaryReadService {
  final SummaryRepository _summaryRepository;
  final AttachmentRepository _attachmentRepository;

  DefaultSummaryReadService(
    this._summaryRepository,
    this._attachmentRepository,
  );

  @override
  Future<SummaryDetailReadModel> getSummaryDetail(String summaryId) async {
    final summary = await _summaryRepository.getById(summaryId);
    return _buildDetailReadModel(summary);
  }

  @override
  Future<SummaryDetailReadModel?> getSummaryDetailByDate(DateTime summaryDate) async {
    final summary = await _summaryRepository.getByDate(summaryDate);
    if (summary == null) {
      return null;
    }

    return _buildDetailReadModel(summary);
  }

  Future<SummaryDetailReadModel> _buildDetailReadModel(DailySummary summary) async {
    final attachments = await _attachmentRepository.getByOwner(
      AttachmentOwnerType.summary,
      summary.id,
    );

    final combinedContent = [summary.tomorrowPlan, summary.todaySummary]
        .where((section) => section.trim().isNotEmpty)
        .join('\n');
    final actionItems = parseActionItems(combinedContent);

    return SummaryDetailReadModel(
      summary: summary,
      attachments: attachments,
      actionItems: actionItems,
    );
  }
}

class SummaryDetailReadModel {
  final DailySummary summary;
  final List<Attachment> attachments;
  final List<ActionItem> actionItems;

  const SummaryDetailReadModel({
    required this.summary,
    required this.attachments,
    required this.actionItems,
  });
}
