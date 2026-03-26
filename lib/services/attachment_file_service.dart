import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../exceptions/app_exception.dart';
import '../models/attachment.dart';
import '../models/attachment_draft.dart';
import '../config/app_constants.dart';
import '../repositories/attachment_repository.dart';
import 'platform_file_opener.dart';

/// 附件文件 I/O 操作：复制、删除、路径解析、存储模式判断、打开/显示。
class AttachmentFileService {
  final AttachmentRepository _attachmentRepository;
  final Future<Directory> Function()? _attachmentsDirectoryResolver;
  final PlatformFileOpener _fileOpener;

  AttachmentFileService(
    this._attachmentRepository, {
    Future<Directory> Function()? attachmentsDirectoryResolver,
    PlatformFileOpener? fileOpener,
  })  : _attachmentsDirectoryResolver = attachmentsDirectoryResolver,
        _fileOpener = fileOpener ?? const DefaultPlatformFileOpener();

  Future<Directory> getAttachmentsDirectory() async {
    final resolver = _attachmentsDirectoryResolver;
    if (resolver != null) {
      return resolver();
    }

    final baseDirectory = await getApplicationDocumentsDirectory();
    final attachmentsDirectory = Directory(path.join(baseDirectory.path, 'attachments'));
    if (!await attachmentsDirectory.exists()) {
      await attachmentsDirectory.create(recursive: true);
    }
    return attachmentsDirectory;
  }

  AttachmentStorageMode resolveStorageMode(AttachmentDraft draft, int sizeBytes) {
    final preferredStorageMode = draft.preferredStorageMode;
    if (preferredStorageMode != null) {
      if (preferredStorageMode == AttachmentStorageMode.linked && supportsLinkedStorage()) {
        return AttachmentStorageMode.linked;
      }
      return AttachmentStorageMode.managed;
    }

    if (supportsLinkedStorage() && sizeBytes > AttachmentImportLimits.linkedPreferredThresholdBytes) {
      return AttachmentStorageMode.linked;
    }

    return AttachmentStorageMode.managed;
  }

  Future<void> openAttachment(Attachment attachment) async {
    final openPath = await resolveOpenPath(attachment);
    final file = File(openPath);
    if (!await file.exists()) {
      throw const FileStorageException(
        message: '附件文件不存在，无法打开',
        code: 'attachment_file_missing',
      );
    }

    await _fileOpener.openFile(openPath);
  }

  Future<void> revealAttachment(Attachment attachment) async {
    final revealPath = await resolveRevealPath(attachment);
    await _fileOpener.revealFile(revealPath);
  }

  Future<String> resolveOpenPath(Attachment attachment) async {
    if (attachment.storageMode == AttachmentStorageMode.linked) {
      final sourcePath = attachment.sourcePath ?? attachment.storagePath;
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        await updateSourceStatus(attachment, AttachmentSourceStatus.missing);
        throw const FileStorageException(
          message: '原文件已丢失，无法打开附件',
          code: 'attachment_source_missing',
        );
      }

      await updateSourceStatus(attachment, AttachmentSourceStatus.available);
      return sourcePath;
    }

    return attachment.managedPath ?? attachment.storagePath;
  }

  Future<String> resolveRevealPath(Attachment attachment) async {
    if (attachment.storageMode == AttachmentStorageMode.linked) {
      final sourcePath = attachment.sourcePath ?? attachment.storagePath;
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        await updateSourceStatus(attachment, AttachmentSourceStatus.missing);
        throw const FileStorageException(
          message: '原文件已丢失，无法显示所在位置',
          code: 'attachment_source_missing',
        );
      }

      await updateSourceStatus(attachment, AttachmentSourceStatus.available);
      return sourcePath;
    }

    final managedPath = attachment.managedPath ?? attachment.storagePath;
    final managedFile = File(managedPath);
    if (!await managedFile.exists()) {
      throw const FileStorageException(
        message: '托管文件不存在，无法显示所在位置',
        code: 'attachment_file_missing',
      );
    }

    return managedPath;
  }

  Future<void> updateSourceStatus(
    Attachment attachment,
    AttachmentSourceStatus status,
  ) async {
    if (attachment.sourceStatus == status && attachment.sourceLastVerifiedAt != null) {
      return;
    }

    await _attachmentRepository.update(
      attachment.copyWith(
        sourceStatus: status,
        sourceLastVerifiedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> deleteManagedArtifacts(Attachment attachment) async {
    final managedPath = attachment.managedPath;
    if (managedPath != null && managedPath.isNotEmpty) {
      final file = File(managedPath);
      if (await file.exists()) {
        await file.delete();
      }
    } else if (attachment.storageMode == AttachmentStorageMode.managed) {
      final file = File(attachment.storagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    final snapshotPath = attachment.snapshotPath;
    if (snapshotPath != null && snapshotPath.isNotEmpty) {
      final snapshotFile = File(snapshotPath);
      if (await snapshotFile.exists()) {
        await snapshotFile.delete();
      }
    }
  }

  String formatLimit(int sizeBytes) {
    final megaBytes = sizeBytes / (1024 * 1024);
    if (megaBytes >= 1024) {
      return '${(megaBytes / 1024).toStringAsFixed(1)} GB';
    }
    return '${megaBytes.toStringAsFixed(0)} MB';
  }
}
