import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';

import 'config.dart';

Future<File> saveImageBytes(final Uint8List bytes) async {
  final File file = File(join(scenesDirectory.path, kUUID.v4()));

  return file.writeAsBytes(bytes);
}
