import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

final Directory workingDirectory = Directory('temp')..createSync();
final Directory downloadDirectory = Directory(path.join(workingDirectory.path, 'downloaded'))..createSync();
final Directory scenesDirectory = Directory(path.join(workingDirectory.path, 'scenes'))..createSync();
final Directory resourceDirectory = Directory(path.join(workingDirectory.path, 'resources'))..createSync();
final Directory dataDirectory = Directory(path.join(workingDirectory.path, 'data'))..createSync();

const Uuid kUUID = Uuid();
