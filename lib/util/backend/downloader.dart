import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../utils.dart';

/// Const api point for the latest yt-dlp release.
const String kYtDlpLatest = 'https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest';

class Downloader {
  static final Downloader _singleton = Downloader._internal();

  factory Downloader() => _singleton;

  Downloader._internal();

  Future<String> _getLocalInstallPath() async {
    if (!Platform.isWindows) {
      return 'yt-dlp';
    }

    return (await _organizeResourcesWindows()).path;
  }

  Future<void> download({required String url, required File output, List<String>? command}) async {
    final String localInstall = await _getLocalInstallPath();

    final Process process = await Process.start(
        localInstall, ['--update-to', 'stable', ...?command, url, '--output', output.path]);

    process.stdout.transform(utf8.decoder).forEach(print);

    // wait for the process to finish
    final int exitCode = await process.exitCode;

    if (exitCode != 0) {
      return Future.error(
          'Yt-dlp exited with a code of non-zero. Something went wrong while downloading.');
    }
  }

  Future<File> _organizeResourcesWindows() async {
    final Directory documents = await getApplicationDirectory();

    final File localInstall = File(path.join(documents.path, 'yt-dlp.exe'));

    if (localInstall.existsSync()) {
      return localInstall;
    }

    http.Response response = await http.get(Uri.parse(kYtDlpLatest));

    if (response.statusCode != 200) {
      return Future.error(
          'Response returned a status code of non-200, response code was ${response.statusCode}.');
    }

    final dynamic json = jsonDecode(response.body);
    final dynamic assets = json['assets'];

    for (final dynamic asset in assets) {
      final String name = asset['name'];
      final String? url = asset['browser_download_url'];

      if (name != path.basename(localInstall.path) || url == null) {
        continue;
      }

      try {
        await Dio().download(url, localInstall.path);
      } catch (e) {
        rethrow;
      }
    }

    return localInstall;
  }
}
