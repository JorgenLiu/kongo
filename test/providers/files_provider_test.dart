import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/attachment.dart';
import 'package:kongo/models/attachment_draft.dart';
import 'package:kongo/models/attachment_link.dart';
import 'package:kongo/models/event_summary_draft.dart';
import 'package:kongo/providers/files_provider.dart';
import 'package:kongo/services/attachment_preview_service.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('kongo_files_provider_test_');
    harness = await createTestAppHarnessWithOptions(
      attachmentsDirectoryResolver: () async => tempDirectory,
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
    await harness.dispose();
  });

  test('FilesProvider filters attachments by storage mode and missing source state', () async {
    final managedSource = File('${tempDirectory.path}/managed.txt');
    await managedSource.writeAsString('managed');
    final linkedSource = File('${tempDirectory.path}/linked.txt');
    await linkedSource.writeAsString('linked');
    final missingSource = File('${tempDirectory.path}/missing.txt');
    await missingSource.writeAsString('missing');

    await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: managedSource.path,
        preferredStorageMode: AttachmentStorageMode.managed,
      ),
    );
    await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: linkedSource.path,
        preferredStorageMode: AttachmentStorageMode.linked,
      ),
    );
    final missingAttachment = await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: missingSource.path,
        preferredStorageMode: AttachmentStorageMode.linked,
      ),
    );
    await missingSource.delete();
    try {
      await harness.dependencies.attachmentService.openAttachment(missingAttachment);
    } catch (_) {}

    final provider = harness.dependencies.filesProvider;
    await provider.loadFiles();

    expect(provider.files.length, 3);

    provider.updateStorageFilter(FilesLibraryStorageFilter.managed);
    expect(provider.files.length, 1);
    expect(provider.files.single.storageMode, AttachmentStorageMode.managed);

    provider.updateStorageFilter(FilesLibraryStorageFilter.linked);
    expect(provider.files.length, 2);
    expect(provider.files.every((item) => item.storageMode == AttachmentStorageMode.linked), isTrue);

    provider.setMissingSourceOnly(true);
    expect(provider.files.length, 1);
    expect(provider.files.single.storageMode, AttachmentStorageMode.linked);
    expect(provider.files.single.sourceStatus, AttachmentSourceStatus.missing);

    provider.updateStorageFilter(FilesLibraryStorageFilter.managed);
    expect(provider.files, isEmpty);

    provider.setMissingSourceOnly(false);
    expect(provider.files.length, 1);
    expect(provider.files.single.storageMode, AttachmentStorageMode.managed);
  });

  test('FilesProvider sorts attachments by file name and size', () async {
    final gammaSource = File('${tempDirectory.path}/gamma.txt');
    await gammaSource.writeAsString('1234567890');
    final alphaSource = File('${tempDirectory.path}/alpha.txt');
    await alphaSource.writeAsString('1234');
    final betaSource = File('${tempDirectory.path}/beta.txt');
    await betaSource.writeAsString('1234567');

    await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: gammaSource.path,
        preferredStorageMode: AttachmentStorageMode.managed,
      ),
    );
    await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: alphaSource.path,
        preferredStorageMode: AttachmentStorageMode.managed,
      ),
    );
    await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: betaSource.path,
        preferredStorageMode: AttachmentStorageMode.managed,
      ),
    );

    final provider = harness.dependencies.filesProvider;
    await provider.loadFiles();

    provider.updateSort(FilesLibrarySort.fileNameAsc);
    expect(
      provider.files.map((item) => item.fileName).toList(),
      ['alpha.txt', 'beta.txt', 'gamma.txt'],
    );

    provider.updateSort(FilesLibrarySort.fileSizeDesc);
    expect(
      provider.files.map((item) => item.fileName).toList(),
      ['gamma.txt', 'beta.txt', 'alpha.txt'],
    );
  });

  test('FilesProvider exposes link counts and cleans up orphan files only', () async {
    final managedSource = File('${tempDirectory.path}/cleanup_managed.txt');
    await managedSource.writeAsString('managed');
    final linkedSource = File('${tempDirectory.path}/cleanup_linked.txt');
    await linkedSource.writeAsString('linked');

    final orphanAttachment = await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: managedSource.path,
        preferredStorageMode: AttachmentStorageMode.managed,
      ),
    );

    final summary = await harness.dependencies.summaryService.createSummary(
      DailySummaryDraft(
        summaryDate: DateTime(2030, 1, 1),
        todaySummary: '带附件总结',
        tomorrowPlan: '',
      ),
    );

    await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: linkedSource.path,
        preferredStorageMode: AttachmentStorageMode.linked,
        ownerType: AttachmentOwnerType.summary,
        ownerId: summary.id,
      ),
    );

    final provider = harness.dependencies.filesProvider;
    await provider.loadFiles();

    expect(provider.linkCountFor(orphanAttachment.id), 0);
    expect(provider.orphanFileCount, 1);

    final deletedCount = await provider.cleanupOrphanFiles();

    expect(deletedCount, 1);
    expect(provider.orphanFileCount, 0);
    expect(provider.files.length, 1);
    expect(await managedSource.exists(), isTrue);
  });

  test('FilesProvider supports multi-select and batch deletes orphan attachments', () async {
    final firstSource = File('${tempDirectory.path}/batch_first.txt');
    await firstSource.writeAsString('first');
    final secondSource = File('${tempDirectory.path}/batch_second.txt');
    await secondSource.writeAsString('second');
    final linkedSource = File('${tempDirectory.path}/batch_linked.txt');
    await linkedSource.writeAsString('linked');

    final firstAttachment = await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: firstSource.path,
        preferredStorageMode: AttachmentStorageMode.managed,
      ),
    );
    final secondAttachment = await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: secondSource.path,
        preferredStorageMode: AttachmentStorageMode.managed,
      ),
    );
    final summary = await harness.dependencies.summaryService.createSummary(
      DailySummaryDraft(
        summaryDate: DateTime(2030, 1, 5),
        todaySummary: '批量删除测试',
        tomorrowPlan: '',
      ),
    );
    await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: linkedSource.path,
        preferredStorageMode: AttachmentStorageMode.linked,
        ownerType: AttachmentOwnerType.summary,
        ownerId: summary.id,
      ),
    );

    final provider = harness.dependencies.filesProvider;
    await provider.loadFiles();

    provider.enterSelectionMode();
    provider.toggleSelection(firstAttachment.id);
    provider.toggleSelection(secondAttachment.id);

    expect(provider.selectionMode, isTrue);
    expect(provider.selectedCount, 2);
    expect(provider.selectedLinkedCount, 0);
    expect(provider.selectedOrphanCount, 2);

    final deletedCount = await provider.deleteSelectedFiles();

    expect(deletedCount, 2);
    expect(provider.selectionMode, isFalse);
    expect(provider.selectedCount, 0);
    expect(provider.fileById(firstAttachment.id), isNull);
    expect(provider.fileById(secondAttachment.id), isNull);
    expect(provider.files.length, 1);
  });

  test('FilesProvider refreshes preview and updates attachment snapshot', () async {
    final previewRoot = await Directory.systemTemp.createTemp('kongo_files_preview_test_');
    final previewAttachmentsRoot = await Directory.systemTemp.createTemp('kongo_files_preview_attachments_');
    final previewHarness = await createTestAppHarnessWithOptions(
      attachmentsDirectoryResolver: () async => previewAttachmentsRoot,
      attachmentPreviewsDirectoryResolver: () async => previewRoot,
      attachmentPreviewGenerator: ({
        required attachment,
        required sourcePath,
        required previewsDirectory,
      }) async {
        final previewFile = File('${previewsDirectory.path}/${attachment.id}.png');
        await previewFile.writeAsString('preview-image');
        return AttachmentPreviewOutput(snapshotPath: previewFile.path);
      },
    );

    try {
      final imageSource = File('${previewAttachmentsRoot.path}/preview_source.png');
      await imageSource.writeAsString('fake-image-content');

      final attachment = await previewHarness.dependencies.attachmentService.saveAttachment(
        AttachmentDraft(
          sourcePath: imageSource.path,
          preferredStorageMode: AttachmentStorageMode.managed,
        ),
      );

      final provider = previewHarness.dependencies.filesProvider;
      await provider.loadFiles();

      await provider.refreshPreview(attachment.id, force: true);

      final afterRefresh = provider.fileById(attachment.id);
      expect(afterRefresh, isNotNull);
      expect(afterRefresh!.previewStatus, AttachmentPreviewStatus.ready);
      expect(afterRefresh.snapshotPath, isNotNull);
      expect(afterRefresh.snapshotPath, isNotEmpty);
      expect(provider.isRefreshingPreview(attachment.id), isFalse);
      expect(await File(afterRefresh.snapshotPath!).exists(), isTrue);
    } finally {
      await previewHarness.dispose();
      if (await previewRoot.exists()) {
        await previewRoot.delete(recursive: true);
      }
      if (await previewAttachmentsRoot.exists()) {
        await previewAttachmentsRoot.delete(recursive: true);
      }
    }
  });
}