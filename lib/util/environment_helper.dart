import 'dart:io';
import '../util/utils.dart';

Future<(bool, String)> checkEnvironment() async {
  final Map<String, String> vars = Platform.environment;

  final List<String> required = ['ffmpeg', 'java'];

  // TODO: Try to run

  if (!await FFMpegHelper.instance.isFFMpegPresent()) {
    return (false, 'Ffmpeg is missing. Please ');
  }

  return (true, 'Environment ok!');
}
