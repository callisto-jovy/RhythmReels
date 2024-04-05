import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rhythm_reels/util/config.dart';

import 'ffmpeg_progress.dart';

//
const String _ffmpegWindowsUrl = 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip';

const String _ffmpegMacOsUrl = 'https://evermeet.cx/pub/ffmpeg/ffmpeg-6.1.1.zip';
const String _ffprobeMacOsUrl = 'https://evermeet.cx/pub/ffprobe/ffprobe-6.1.1.zip';

class FFMpegHelper {
  static final FFMpegHelper _singleton = FFMpegHelper._internal();

  factory FFMpegHelper() => _singleton;

  FFMpegHelper._internal();

  static FFMpegHelper get instance => _singleton;

  /// Creates the necessary directories for the ffmpeg windows install.
  /// Returns the [Director] to the bin directories where the binaries lie.
  Future<Directory> _getWindowsDirectory() async {
    final Directory appDir = await getApplicationDirectory();

    final String ffmpegInstallationPath = path.join(appDir.path, 'ffmpeg');
    final String ffmpegBinDirectory = path.join(ffmpegInstallationPath, 'ffmpeg-master-latest-win64-gpl', 'bin');

    return Directory(ffmpegBinDirectory).create();
  }

  /// Creates the necessary directories for the ffmpeg windows install.
  /// Returns the [Director] to the ffmpeg directory where the binaries lie.
  Future<Directory> _getMacDirectory() async {
    final Directory appDir = await getApplicationDirectory();
    final String ffmpegInstallationPath = path.join(appDir.path, 'ffmpeg');

    return Directory(ffmpegInstallationPath).create();
  }

  Future<Directory?> getPlatformFFMpeg() {
    if (Platform.isWindows) {
      return _getWindowsDirectory();
    } else if (Platform.isMacOS) {
      return _getMacDirectory();
    }

    return Future(() => null);
  }

  /// Verifies whether Ffmpeg has been installed by the program on windows. Checks for ffmpeg & ffprobe
  ///
  Future<bool> _checkFFMpegWindows() async {
    final Directory ffmpegBinDir = await _getWindowsDirectory();

    final File ffmpeg = File(path.join(ffmpegBinDir.path, 'ffmpeg.exe'));
    final File ffprobe = File(path.join(ffmpegBinDir.path, 'ffprobe.exe'));

    return await ffmpeg.exists() && await ffprobe.exists();
  }

  Future<bool> _checkFFMpegMacOs() async {
    final Directory ffmpegBinDir = await _getMacDirectory();

    final File ffmpeg = File(path.join(ffmpegBinDir.path, 'ffmpeg.app'));
    final File ffprobe = File(path.join(ffmpegBinDir.path, 'ffprobe.app'));

    return await ffmpeg.exists() && await ffprobe.exists();
  }

  Future<bool> _checkFFMpegViaProcess() async {
    try {
      final Process processFfmpeg = await Process.start(
        'ffmpeg',
        ['--help'],
      );

      // TODO: Find way to do this.
      final Process processFprobe = await Process.start(
        'ffprobe',
        ['--help'],
      );

      // Terminate after five seconds. The process isn't responding.
      Future.delayed(const Duration(seconds: 5)).then((value) => processFfmpeg.kill());
      final int ffmpeg = await processFfmpeg.exitCode;

      Future.delayed(const Duration(seconds: 5)).then((value) => processFprobe.kill());
      final int ffprobe = await processFprobe.exitCode;

      return ffmpeg == 0 && ffprobe == 0; // success
    } catch (e) {
      return false;
    }
  }

  Future<bool> localInstallPerformed() async {
    if (Platform.isWindows) {
      return _checkFFMpegWindows();
    } else if (Platform.isMacOS) {
      return _checkFFMpegMacOs();
    }

    return false;
  }

  /// Platform independent check of the ffmpeg install.
  ///
  Future<bool> isFFMpegPresent() async {
    if (Platform.isWindows) {
      return _checkFFMpegViaProcess().then((value) async => value ? value : await _checkFFMpegWindows());
    } else if (Platform.isMacOS) {
      return _checkFFMpegViaProcess().then((value) async => value ? value : await _checkFFMpegMacOs());
    } else if (Platform.isLinux) {
      return _checkFFMpegViaProcess();
    }
    // No ffmpeg detected.
    return false;
  }

  Future<bool> setupFFMpeg({
    CancelToken? cancelToken,
    void Function(FFMpegProgress progress)? onProgress,
    Map<String, dynamic>? queryParameters,
  }) {
    if (Platform.isWindows) {
      return _setupFFMpegWindows();
    } else if (Platform.isMacOS) {
      return _setupFFMpegMacOs();
    }

    return Future.error('Setup on operating system not supported.');
  }

  Future<bool> _download({
    required String url,
    required String output,
    CancelToken? cancelToken,
    void Function(FFMpegProgress progress)? onProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    final Response response = await Dio().download(
      url,
      output,
      cancelToken: cancelToken,
      onReceiveProgress: (int received, int total) => onProgress?.call(FFMpegProgress(
        downloaded: received,
        fileSize: total,
        phase: FFMpegProgressPhase.downloading,
      )),
      queryParameters: queryParameters,
    );

    return response.statusCode == HttpStatus.ok;
  }

  Future<bool> _extractZip({
    required String zipPath,
    required String targetDir,
    void Function(FFMpegProgress progress)? onProgress,
  }) async {
    onProgress?.call(FFMpegProgress(downloaded: 0, fileSize: 0, phase: FFMpegProgressPhase.decompressing));

    return Isolate.run(() async {
      try {
        await extractFileToDisk(zipPath, targetDir);
        return true;
      } catch (e) {
        return false;
      }
    });
  }

  Future<bool> _setupFFMpegMacOs({
    CancelToken? cancelToken,
    void Function(FFMpegProgress progress)? onProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    final Directory macosDir = await _getMacDirectory();
    final Directory temporaryDir = await getTemporaryDirectory();
    final Directory tempDir = Directory(path.join(temporaryDir.path, 'ffmpeg'))..create();

    final String zipFfmpegPath = path.join(tempDir.path, 'ffmpeg.zip');
    final String zipFfprobePath = path.join(tempDir.path, 'ffprobe.zip');

    final bool ffmpegExists = File(zipFfmpegPath).existsSync();
    final bool ffprobeExists = File(zipFfprobePath).existsSync();
    // extract ffmpeg from zip

    if (!ffmpegExists &&
        !await _download(url: _ffmpegMacOsUrl, output: zipFfmpegPath, onProgress: onProgress, cancelToken: cancelToken, queryParameters: queryParameters)) {
      return false;
    }

    if (!await _extractZip(zipPath: zipFfmpegPath, targetDir: macosDir.path, onProgress: onProgress)) {
      return false;
    }

    if (!ffprobeExists &&
        !await _download(url: _ffprobeMacOsUrl, output: zipFfprobePath, cancelToken: cancelToken, onProgress: onProgress, queryParameters: queryParameters)) {
      return false;
    }

    if (!await _extractZip(zipPath: zipFfprobePath, targetDir: macosDir.path, onProgress: onProgress)) {
      return false;
    }

    return ffprobeExists && ffmpegExists;
  }

  Future<bool> _setupFFMpegWindows({
    CancelToken? cancelToken,
    void Function(FFMpegProgress progress)? onProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    final Directory windowsDir = await _getWindowsDirectory();
    final Directory temporaryDir = await getTemporaryDirectory();
    final Directory tempDir = Directory(path.join(temporaryDir.path, 'ffmpeg'))..create();

    final String zipPath = path.join(tempDir.path, 'ffmpeg.zip');

    // Download, then extract
    if (!File(zipPath).existsSync()) {
      if (!await _download(url: _ffmpegWindowsUrl, output: zipPath, onProgress: onProgress, cancelToken: cancelToken, queryParameters: queryParameters)) {
        return false;
      }
    }

    return _extractZip(zipPath: zipPath, targetDir: windowsDir.path, onProgress: onProgress);
  }
}
