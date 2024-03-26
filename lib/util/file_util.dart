import 'dart:io';

import 'package:path/path.dart';
import 'package:simple_youtube_editor_ui/util/config.dart';

Future<File> createTemporaryFile(final Directory directory, {String? suffix}) async {
  final Directory tempDir = await directory.createTemp();
  final File tempFile = File(join(tempDir.path, '${kUUID.v4()}.${suffix ?? 'data'}'));

  return tempFile;
}
