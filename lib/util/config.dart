import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final Directory workingDirectory = Directory('temp')..createSync();
final Directory downloadDirectory = Directory(path.join(workingDirectory.path, 'downloaded'))
  ..createSync();
final Directory scenesDirectory = Directory(path.join(workingDirectory.path, 'scenes'))
  ..createSync();

/// Constant [UUID] to genrate unique identifiers.
const Uuid kUUID = Uuid();

///
Future<SharedPreferences> getPreferences() async {
  return SharedPreferences.getInstance();
}

/// Using the path_provider package, a new [Directory] with the app's name is created
/// in the documents directory.
/// Returns a Future with that [Directory].
Future<Directory> getApplicationDirectory() async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final Directory documentsDir = await getApplicationDocumentsDirectory();
  final String appName = packageInfo.appName;

  //
  final Directory applicationDir = Directory(path.join(documentsDir.path, appName));

  return applicationDir.create();
}

/// [Directory] inside the application's directory which may hold program generated
/// version-persistent data.
Future<Directory> getDataDirectory() async {
  return getApplicationDirectory()
      .then((value) => Directory(path.join(value.path, 'data')).create());
}

///////// Versioning /////////

/// constant that points to the project's github location.
/// Used for string interpolation with github's urls.
const String kGitHubProject = 'callisto-jovy/video_cutter_ui';

/// Fetches the latest version for this project
/// using GitHub's api. Checks against the last stable release's tag name.
Future<String> getLatestVersion() async {
  // Github gives us a super useful latest endpoint, and we can use it to get the latest stable release
  final data = await http.get(Uri.parse(
    "https://api.github.com/repos/$kGitHubProject/releases/latest",
  ));

  // Return the tag name, which is **always** a semantically versioned string.
  return jsonDecode(data.body)["tag_name"];
}

/// Fetches the url to the latest binary for the current operating system.
///
// TODO: Other operating systems than windows.
Future<String> getLatestBinary(final String? latestVersion) async {
  return "https://github.com/$kGitHubProject/releases/download/$latestVersion/video_cutter-${Platform.operatingSystem}-$latestVersion.zip";
}

/// Fetches the changelog for the latest release.
/// Again, making use of GitHub's API.
Future<String> getChangeLog(final String _, final String __) async {
  // That same latest endpoint gives us access to a markdown-flavored release body. Perfect!
  final data = await http.get(Uri.parse(
    "https://api.github.com/repos/$kGitHubProject/releases/latest",
  ));
  return jsonDecode(data.body)["body"];
}

///////// Preferences /////////

const String kEditorStateKey = 'editor.state';
const String kOutputKey = 'output.path';
const String kVideosKey = 'videos.path';
