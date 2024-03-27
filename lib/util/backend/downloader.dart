import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../utils.dart';


const String kYtDlpLatest = 'https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest';

const Downloader kDownloader = Downloader();
const kFileName = 'yt-dlp.exe';

class Downloader {
  const Downloader();

  Future<File> _getLocalInstallPath() async {
    final Directory documents = await getApplicationDirectory();

    return File(path.join(documents.path, 'yt-dlp.exe'));
  }

  Future<void> download({required String url, required File output, List<String>? command}) async {
    await _organizeResources();

    final File localInstall = await _getLocalInstallPath();

    final Process process = await Process.start(localInstall.path, ['--update-to', 'stable', ...?command, url, '--output', output.path]);

    process.stdout.transform(utf8.decoder).forEach(print);

    // wait for the process to finish
    final int exitCode = await process.exitCode;

    if (exitCode != 0) {
      return Future.error('Yt-dlp exited with a code of non-zero. Something went wrong while downloading.');
    }
  }

  Future<void> _organizeResources() async {
    final File localInstall = await _getLocalInstallPath();

    if (localInstall.existsSync()) {
      return;
    }

    http.Response response = await http.get(Uri.parse(kYtDlpLatest));

    if (response.statusCode != 200) {
      return Future.error('Response returned a status code of non-200, response code was ${response.statusCode}.');
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
  }
}
