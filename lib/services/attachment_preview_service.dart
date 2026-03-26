import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/attachment.dart';
import '../repositories/attachment_repository.dart';

class AttachmentPreviewOutput {
  final String snapshotPath;

  const AttachmentPreviewOutput({required this.snapshotPath});
}

typedef AttachmentPreviewGenerator = Future<AttachmentPreviewOutput?> Function({
  required Attachment attachment,
  required String sourcePath,
  required Directory previewsDirectory,
});

abstract class AttachmentPreviewService {
  Future<void> ensurePreview(Attachment attachment, {bool force = false});
}

class DefaultAttachmentPreviewService implements AttachmentPreviewService {
  final AttachmentRepository _attachmentRepository;
  final Future<Directory> Function()? _previewsDirectoryResolver;
  final AttachmentPreviewGenerator? _previewGenerator;

  DefaultAttachmentPreviewService(
    this._attachmentRepository, {
    Future<Directory> Function()? previewsDirectoryResolver,
    AttachmentPreviewGenerator? previewGenerator,
  })  : _previewsDirectoryResolver = previewsDirectoryResolver,
        _previewGenerator = previewGenerator;

  @override
  Future<void> ensurePreview(Attachment attachment, {bool force = false}) async {
    if (!attachment.supportsPreview) {
      if (attachment.previewStatus != AttachmentPreviewStatus.none || attachment.previewError != null) {
        await _attachmentRepository.update(
          attachment.copyWith(
            previewStatus: AttachmentPreviewStatus.none,
            previewError: null,
            previewUpdatedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
      return;
    }

    final currentSnapshotPath = attachment.snapshotPath;
    if (!force &&
        attachment.previewStatus == AttachmentPreviewStatus.ready &&
        currentSnapshotPath != null &&
        currentSnapshotPath.isNotEmpty &&
        await File(currentSnapshotPath).exists()) {
      return;
    }

    final sourcePath = attachment.managedPath ?? attachment.sourcePath ?? attachment.storagePath;
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      if (currentSnapshotPath != null &&
          currentSnapshotPath.isNotEmpty &&
          await File(currentSnapshotPath).exists()) {
        return;
      }

      await _attachmentRepository.update(
        attachment.copyWith(
          previewStatus: AttachmentPreviewStatus.failed,
          previewError: 'source_missing',
          previewUpdatedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }

    await _attachmentRepository.update(
      attachment.copyWith(
        previewStatus: AttachmentPreviewStatus.pending,
        previewError: null,
        previewUpdatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    try {
      final previewsDirectory = await _getPreviewsDirectory();
      final generatedPreview = await (_previewGenerator ?? _generatePreview)(
        attachment: attachment,
        sourcePath: sourcePath,
        previewsDirectory: previewsDirectory,
      );

      if (generatedPreview == null) {
        await _attachmentRepository.update(
          attachment.copyWith(
            previewStatus: AttachmentPreviewStatus.none,
            previewError: null,
            previewUpdatedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        return;
      }

      await _attachmentRepository.update(
        attachment.copyWith(
          snapshotPath: generatedPreview.snapshotPath,
          previewStatus: AttachmentPreviewStatus.ready,
          previewError: null,
          previewUpdatedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } on Exception catch (error) {
      await _attachmentRepository.update(
        attachment.copyWith(
          previewStatus: AttachmentPreviewStatus.failed,
          previewError: error.toString(),
          previewUpdatedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<Directory> _getPreviewsDirectory() async {
    final previewsDirectoryResolver = _previewsDirectoryResolver;
    if (previewsDirectoryResolver != null) {
      final directory = await previewsDirectoryResolver();
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    }

    final baseDirectory = await getApplicationDocumentsDirectory();
    final previewsDirectory = Directory(path.join(baseDirectory.path, 'attachments', 'previews'));
    if (!await previewsDirectory.exists()) {
      await previewsDirectory.create(recursive: true);
    }
    return previewsDirectory;
  }

  Future<AttachmentPreviewOutput?> _generatePreview({
    required Attachment attachment,
    required String sourcePath,
    required Directory previewsDirectory,
  }) async {
    if (Platform.isMacOS && attachment.supportsPreview) {
      return _generateMacOsQuickLookPreview(
        attachment: attachment,
        sourcePath: sourcePath,
        previewsDirectory: previewsDirectory,
      );
    }

    if (attachment.isImageFile) {
      return AttachmentPreviewOutput(snapshotPath: sourcePath);
    }

    return null;
  }

  Future<AttachmentPreviewOutput?> _generateMacOsQuickLookPreview({
    required Attachment attachment,
    required String sourcePath,
    required Directory previewsDirectory,
  }) async {
    final workingDirectory = Directory(path.join(previewsDirectory.path, '${attachment.id}_tmp'));
    if (await workingDirectory.exists()) {
      await workingDirectory.delete(recursive: true);
    }
    await workingDirectory.create(recursive: true);

    try {
      final args = ['-t', '-s', '640', '-o', workingDirectory.path, sourcePath];
      final result = await Process.run('qlmanage', args);
      if (result.exitCode != 0) {
        throw ProcessException('qlmanage', args, result.stderr.toString(), result.exitCode);
      }

      final generatedPreviewFile = File(
        path.join(workingDirectory.path, '${path.basename(sourcePath)}.png'),
      );
      if (!await generatedPreviewFile.exists()) {
        return null;
      }

      final targetFile = File(path.join(previewsDirectory.path, '${attachment.id}.png'));
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      await generatedPreviewFile.rename(targetFile.path);
      return AttachmentPreviewOutput(snapshotPath: targetFile.path);
    } finally {
      if (await workingDirectory.exists()) {
        await workingDirectory.delete(recursive: true);
      }
    }
  }
}