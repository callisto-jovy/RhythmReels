import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:rhythm_reels/util/config.dart';

import 'ffmpeg_progress.dart';

class FFMpegHelper {
  static final FFMpegHelper _singleton = FFMpegHelper._internal();

  factory FFMpegHelper() => _singleton;

  FFMpegHelper._internal();

  static FFMpegHelper get instance => _singleton;

  //
  final String _ffmpegUrl = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip";
  String? _tempFolderPath;
  String? _ffmpegBinDirectory;
  String? _ffmpegInstallationPath;

  Future<void> initialize() async {
    if (Platform.isWindows) {
      final Directory tempDir = await getTemporaryDirectory();
      _tempFolderPath = path.join(tempDir.path, "ffmpeg");

      final Directory appDocDir = await getApplicationDirectory();
      _ffmpegInstallationPath = path.join(appDocDir.path, "ffmpeg");
      _ffmpegBinDirectory = path.join(_ffmpegInstallationPath!, "ffmpeg-master-latest-win64-gpl", "bin");
    }
  }

  String? get ffmpegBinDirectory => _ffmpegBinDirectory;

  Future<bool> isFFMpegPresent() async {
    if (Platform.isWindows) {
      if ((_ffmpegBinDirectory == null) || (_tempFolderPath == null)) {
        await initialize();
      }
      File ffmpeg = File(path.join(_ffmpegBinDirectory!, "ffmpeg.exe"));
      File ffprobe = File(path.join(_ffmpegBinDirectory!, "ffprobe.exe"));
      if ((await ffmpeg.exists()) && (await ffprobe.exists())) {
        return true;
      } else {
        return false;
      }
    } else if (Platform.isLinux) {
      try {
        Process process = await Process.start(
          'ffmpeg',
          ['--help'],
        );
        return await process.exitCode == 0; // success
      } catch (e) {
        return false;
      }
    } else {
      return true;
    }
  }

  static Future<void> extractZipFileIsolate(Map data) async {
    try {
      String? zipFilePath = data['zipFile'];
      String? targetPath = data['targetPath'];
      if ((zipFilePath != null) && (targetPath != null)) {
        await extractFileToDisk(zipFilePath, targetPath);
      }
    } catch (e) {
      return;
    }
  }

  Future<bool> setupFFMpegOnWindows({
    CancelToken? cancelToken,
    void Function(FFMpegProgress progress)? onProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (Platform.isWindows) {
      if ((_ffmpegBinDirectory == null) || (_tempFolderPath == null)) {
        await initialize();
      }
      Directory tempDir = Directory(_tempFolderPath!);
      if (await tempDir.exists() == false) {
        await tempDir.create(recursive: true);
      }
      Directory installationDir = Directory(_ffmpegInstallationPath!);
      if (await installationDir.exists() == false) {
        await installationDir.create(recursive: true);
      }
      final String ffmpegZipPath = path.join(_tempFolderPath!, "ffmpeg.zip");
      final File tempZipFile = File(ffmpegZipPath);
      if (await tempZipFile.exists() == false) {
        try {
          Dio dio = Dio();
          Response response = await dio.download(
            _ffmpegUrl,
            ffmpegZipPath,
            cancelToken: cancelToken,
            onReceiveProgress: (int received, int total) {
              onProgress?.call(FFMpegProgress(
                downloaded: received,
                fileSize: total,
                phase: FFMpegProgressPhase.downloading,
              ));
            },
            queryParameters: queryParameters,
          );
          if (response.statusCode == HttpStatus.ok) {
            onProgress?.call(FFMpegProgress(
              downloaded: 0,
              fileSize: 0,
              phase: FFMpegProgressPhase.decompressing,
            ));
            await compute(extractZipFileIsolate, {
              'zipFile': tempZipFile.path,
              'targetPath': _ffmpegInstallationPath,
            });
            onProgress?.call(FFMpegProgress(
              downloaded: 0,
              fileSize: 0,
              phase: FFMpegProgressPhase.inactive,
            ));
            return true;
          } else {
            onProgress?.call(FFMpegProgress(
              downloaded: 0,
              fileSize: 0,
              phase: FFMpegProgressPhase.inactive,
            ));
            return false;
          }
        } catch (e) {
          onProgress?.call(FFMpegProgress(
            downloaded: 0,
            fileSize: 0,
            phase: FFMpegProgressPhase.inactive,
          ));
          return false;
        }
      } else {
        onProgress?.call(FFMpegProgress(
          downloaded: 0,
          fileSize: 0,
          phase: FFMpegProgressPhase.decompressing,
        ));
        try {
          await compute(extractZipFileIsolate, {
            'zipFile': tempZipFile.path,
            'targetPath': _ffmpegInstallationPath,
          });
          onProgress?.call(FFMpegProgress(
            downloaded: 0,
            fileSize: 0,
            phase: FFMpegProgressPhase.inactive,
          ));
          return true;
        } catch (e) {
          onProgress?.call(FFMpegProgress(
            downloaded: 0,
            fileSize: 0,
            phase: FFMpegProgressPhase.inactive,
          ));
          return false;
        }
      }
    } else {
      onProgress?.call(FFMpegProgress(
        downloaded: 0,
        fileSize: 0,
        phase: FFMpegProgressPhase.inactive,
      ));
      return true;
    }
  }
}
