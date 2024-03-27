import 'dart:convert';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

final Directory workingDirectory = Directory('temp')..createSync();
final Directory downloadDirectory = Directory(path.join(workingDirectory.path, 'downloaded'))..createSync();
final Directory scenesDirectory = Directory(path.join(workingDirectory.path, 'scenes'))..createSync();
final Directory resourceDirectory = Directory(path.join(workingDirectory.path, 'resources'))..createSync();

///
Future<Directory> getApplicationDirectory() async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final Directory documentsDir = await getApplicationDocumentsDirectory();
  final String appName = packageInfo.appName;

  final Directory dataDirectory = Directory(path.join(documentsDir.path, appName));

  return dataDirectory.create();
}

Future<Directory> getDataDirectory() async {
  return getApplicationDirectory().then((value) => Directory(path.join(value.path, 'data')).create());
}

const Uuid kUUID = Uuid();

const String kGitHubProject = 'callisto-jovy/video_cutter_ui';

Future<String> getLatestVersion() async {
  // Github gives us a super useful latest endpoint, and we can use it to get the latest stable release
  final data = await http.get(Uri.parse(
    "https://api.github.com/repos/$kGitHubProject/releases/latest",
  ));

  // Return the tag name, which is always a semantically versioned string.
  return jsonDecode(data.body)["tag_name"];
}

// TODO: Other operating systems than windows.
Future<String> getLatestBinary(final String? latestVersion) async {
  return "https://github.com/$kGitHubProject/releases/download/$latestVersion/video_cutter-${Platform.operatingSystem}-$latestVersion.zip";
}

Future<String> getChangeLog(final String _, final String __) async {
  // That same latest endpoint gives us access to a markdown-flavored release body. Perfect!
  final data = await http.get(Uri.parse(
    "https://api.github.com/repos/$kGitHubProject/releases/latest",
  ));
  return jsonDecode(data.body)["body"];
}
