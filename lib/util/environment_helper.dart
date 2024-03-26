import 'dart:io';

(bool, String) checkEnvironment() {
  final Map<String, String> vars = Platform.environment;

  final List<String> required = ['ffmpeg', 'java'];

  // TODO: Try to run

  for (final String s in required) {



  }

  return (true, 'Environment ok!');
}
