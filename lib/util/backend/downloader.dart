import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

import '../config.dart';

const String kYtDlpLatest = 'https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest';

final Downloader downloader = Downloader(resourceDirectory);

class Downloader {
  final File _localInstall;
  final Directory _directory;

  Downloader(this._directory) : _localInstall = File(path.join(_directory.path, 'yt-dlp.exe'));

  Future<void> download({required String url, required File output, List<String>? command}) async {
    await _organizeResources();

    final Process process =
        await Process.start(_localInstall.path, ['--update-to', 'nightly', ...?command, url, '--output', output.path]);

    process.stdout.transform(utf8.decoder).forEach(print);

    // wait for the process to finish
    final int exitCode = await process.exitCode;

    if(exitCode != 0) {
      return Future.error('Yt-dlp exited with a code of non-zero. Something went wrong while downloading.');
    }
  }

  Future<void> _organizeResources() async {
    if (_localInstall.existsSync()) {
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

      if (name != path.basename(_localInstall.path) || url == null) {
        continue;
      }

      await _localInstall.writeAsBytes(await http.readBytes(Uri.parse(url)));
    }
  }
}
