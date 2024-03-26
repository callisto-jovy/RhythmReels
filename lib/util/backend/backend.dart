import 'dart:async';
import 'dart:convert';
import 'dart:io';

const String kCuttingRunnable = 'cutter.exe';

Stream<String> runCutting(
    {required String audioPath, required String outputPath, required String videosPath, required List<double> beatTimes, File? imageOverlay}) async* {
  final List<String> beats = [];
  for (final double value in beatTimes) {
    beats.add('--beat');
    beats.add('${value / 1000}'); // Program expects the timestamps in seconds
  }

  final Process process = await Process.start(
    kCuttingRunnable,
    [
      '--audio',
      audioPath,
      '--videos',
      videosPath,
      '--output',
      outputPath,
      if (imageOverlay != null) ...['--image_overlay', imageOverlay.path], // love dart for allowing spreads like this :)
      ...beats
    ],
  );

  // print(['--audio', audioPath, '--videos', videosPath, '--output', outputPath, ...beats].join(" "));

  //process.stdout.transform(utf8.decoder).forEach(print);
  //process.stderr.transform(utf8.decoder).forEach(print);

  yield* process.stdout.transform(utf8.decoder);

  // Potential error log.

  final List<String> errorLog = await process.stderr.transform(utf8.decoder).asyncMap((event) => 'Error: $event').toList();

  for (final String error in errorLog) {
    yield 'Error: $error';
  }
}
