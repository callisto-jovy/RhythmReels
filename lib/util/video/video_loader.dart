import 'dart:io';

import 'package:path/path.dart' as path;

import '../utils.dart';

Future<File> loadVideo(final String videoUrl) async {
  final String fileName = '${videoUrl.hashCode}.mp4';
  final File videoFile = File(path.join(downloadDirectory.path, fileName));

  // Don't re-download the file.
  if (await videoFile.exists()) {
    return videoFile;
  }

  // Download the mp4. Force the container
  await Downloader().download(url: videoUrl, output: videoFile, command: ['-S', 'res,ext:mp4:m4a']);

  return videoFile;
}
