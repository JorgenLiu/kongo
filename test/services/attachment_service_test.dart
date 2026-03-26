import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'package:kongo/models/attachment.dart';
import 'package:kongo/models/attachment_draft.dart';
import 'package:kongo/services/attachment_preview_service.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;
  late Directory tempDirectory;
  late Directory previewsDirectory;

  Future<AttachmentPreviewOutput?> fakePreviewGenerator({
    required Attachment attachment,
    required String sourcePath,
    required Directory previewsDirectory,
  }) async {
    final previewFile = File(path.join(previewsDirectory.path, '${attachment.id}.png'));
    await previewFile.create(recursive: true);
    await previewFile.writeAsString('preview:${path.basename(sourcePath)}');
    return AttachmentPreviewOutput(snapshotPath: previewFile.path);
  }

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('kongo_attachment_test_');
    previewsDirectory = Directory(path.join(tempDirectory.path, 'previews'));
    harness = await createTestAppHarnessWithOptions(
      attachmentsDirectoryResolver: () async => tempDirectory,
      attachmentPreviewsDirectoryResolver: () async => previewsDirectory,
      attachmentPreviewGenerator: fakePreviewGenerator,
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
    await harness.dispose();
  });

  test('AttachmentService saves managed attachment by copying source file', () async {
    final sourceFile = File('${tempDirectory.path}/managed_source.txt');
    await sourceFile.writeAsString('managed-content');

    final attachment = await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: sourceFile.path,
        preferredStorageMode: AttachmentStorageMode.managed,
      ),
    );

    expect(attachment.storageMode, AttachmentStorageMode.managed);
    expect(attachment.managedPath, isNotNull);
    expect(attachment.sourcePath, sourceFile.path);
    expect(await File(attachment.managedPath!).exists(), isTrue);
  });

  test('AttachmentService saves linked attachment without copying source file', () async {
    final sourceFile = File('${tempDirectory.path}/linked_source.txt');
    await sourceFile.writeAsString('linked-content');

    final attachment = await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: sourceFile.path,
        preferredStorageMode: AttachmentStorageMode.linked,
      ),
    );

    expect(attachment.storageMode, AttachmentStorageMode.linked);
    expect(attachment.sourcePath, sourceFile.path);
    expect(attachment.managedPath, isNull);
    expect(attachment.storagePath, sourceFile.path);
  });

  test('AttachmentService deletes only managed artifact for linked attachment record', () async {
    final sourceFile = File('${tempDirectory.path}/delete_linked_source.txt');
    await sourceFile.writeAsString('linked-content');

    final attachment = await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: sourceFile.path,
        preferredStorageMode: AttachmentStorageMode.linked,
      ),
    );

    await harness.dependencies.attachmentService.deleteAttachment(attachment.id);

    expect(await sourceFile.exists(), isTrue);
  });

  test('AttachmentService relinks linked attachment source to new file path', () async {
    final sourceFile = File('${tempDirectory.path}/relink_source_old.txt');
    await sourceFile.writeAsString('old-content');
    final replacementFile = File('${tempDirectory.path}/relink_source_new.txt');
    await replacementFile.writeAsString('new-content');

    final attachment = await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: sourceFile.path,
        preferredStorageMode: AttachmentStorageMode.linked,
      ),
    );

    final updated = await harness.dependencies.attachmentService.relinkAttachmentSource(
      attachment.id,
      replacementFile.path,
    );

    expect(updated.storageMode, AttachmentStorageMode.linked);
    expect(updated.sourcePath, replacementFile.path);
    expect(updated.storagePath, replacementFile.path);
    expect(updated.originalFileName, 'relink_source_new.txt');
  });

  test('AttachmentService converts linked attachment to managed copy', () async {
    final sourceFile = File('${tempDirectory.path}/convert_source.txt');
    await sourceFile.writeAsString('convert-content');

    final attachment = await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: sourceFile.path,
        preferredStorageMode: AttachmentStorageMode.linked,
      ),
    );

    final converted = await harness.dependencies.attachmentService.convertAttachmentToManaged(
      attachment.id,
    );

    expect(converted.storageMode, AttachmentStorageMode.managed);
    expect(converted.managedPath, isNotNull);
    expect(converted.storagePath, converted.managedPath);
    expect(await File(converted.managedPath!).exists(), isTrue);
    expect(await sourceFile.exists(), isTrue);
  });

  test('AttachmentService generates preview snapshot for image attachment', () async {
    final sourceFile = File(path.join(tempDirectory.path, 'preview_source.png'));
    await sourceFile.writeAsString('image-content');

    final attachment = await harness.dependencies.attachmentService.saveAttachment(
      AttachmentDraft(
        sourcePath: sourceFile.path,
        preferredStorageMode: AttachmentStorageMode.managed,
        mimeType: 'image/png',
      ),
    );

    await harness.dependencies.attachmentService.refreshAttachmentPreview(attachment.id, force: true);
    final refreshed = await harness.dependencies.attachmentService.getAttachment(attachment.id);

    expect(refreshed.previewStatus, AttachmentPreviewStatus.ready);
    expect(refreshed.snapshotPath, isNotNull);
    expect(await File(refreshed.snapshotPath!).exists(), isTrue);
  });
}