import 'dart:io';

import '../exceptions/app_exception.dart';

/// 当前平台是否支持链接存储（linked storage）模式。
bool supportsLinkedStorage() {
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}

/// 平台文件操作抽象：打开文件、在文件管理器中显示。
///
/// 生产实现通过 [Process.run] 调用系统命令；
/// 测试环境可注入自定义实现避免真实子进程调用。
abstract class PlatformFileOpener {
  /// 用系统默认应用打开文件。
  Future<void> openFile(String filePath);

  /// 在文件管理器中选中并显示文件。
  Future<void> revealFile(String filePath);
}

/// 基于 [Process.run] 的默认实现，按平台分发系统命令。
class DefaultPlatformFileOpener implements PlatformFileOpener {
  const DefaultPlatformFileOpener();

  @override
  Future<void> openFile(String filePath) async {
    final result = await _runPlatformOpen(filePath);
    if (result.exitCode != 0) {
      throw FileStorageException(
        message: '打开文件失败',
        code: 'file_open_failed',
        originalException: result.stderr,
      );
    }
  }

  @override
  Future<void> revealFile(String filePath) async {
    final result = await _runPlatformReveal(filePath);
    if (result.exitCode != 0) {
      throw FileStorageException(
        message: '显示文件位置失败',
        code: 'file_reveal_failed',
        originalException: result.stderr,
      );
    }
  }

  Future<ProcessResult> _runPlatformOpen(String filePath) {
    if (Platform.isMacOS) {
      return Process.run('open', [filePath]);
    } else if (Platform.isWindows) {
      return Process.run('cmd', ['/c', 'start', '', filePath]);
    } else {
      return Process.run('xdg-open', [filePath]);
    }
  }

  Future<ProcessResult> _runPlatformReveal(String filePath) {
    if (Platform.isMacOS) {
      return Process.run('open', ['-R', filePath]);
    } else if (Platform.isWindows) {
      return Process.run('explorer', ['/select,', filePath]);
    } else {
      return Process.run('xdg-open', [_parentDirectory(filePath)]);
    }
  }

  String _parentDirectory(String filePath) {
    final lastSep = filePath.lastIndexOf(Platform.pathSeparator);
    if (lastSep <= 0) return filePath;
    return filePath.substring(0, lastSep);
  }
}
