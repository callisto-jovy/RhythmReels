import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ffmpeg_util.dart';

const String kCuttingRunnable = 'cutter.jar';

Future<File> initBackend() async {
  // TODO: This is NOT the way...

  // Move the file out of the assets bundle, so that the temp folder may be shared.
  // TODO: Would be better, if the backend had a argument which would set the temp folder
  // maybe pass a env??
  final File file = File(kCuttingRunnable);

  // final bool exists = await file.exists();

  // TODO: Sanity check. Also, check the file version and override when a new version comes.
  // For now: Just always override
  // if (exists && await file.length() > 0) {
  //  return file;
  //}

  // write byte data into the applications document directory.
  final ByteData byteData = await rootBundle.load('assets/$kCuttingRunnable');

  return await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
}

Future<void> runBackendIsolate({
  required ReceivePort receivePort,
  required String audioPath,
  required String outputPath,
  required String videosPath,
  required List<double> beatTimes,
  File? imageOverlay,
}) async {

  // Custom ffmpeg location
  final bool ffmpegPresent = await FFMpegHelper().localInstallPerformed();
  final Directory? ffmpegPlatform = await FFMpegHelper().getPlatformFFMpeg();
  // Load the cutter from the root bundle, cant to that in the isolate...
  final File backendExecutable = await initBackend();

  try {
    await Isolate.spawn(
        _runBackend,
        {
          'port': receivePort.sendPort,
          'backend': backendExecutable,
          'audio_path': audioPath,
          'output_path': outputPath,
          'videos_path': videosPath,
          'beat_times': beatTimes,
          'ffmpeg_install': ffmpegPlatform,
          'ffmpeg_present': ffmpegPresent,
          'image_overlay': imageOverlay,
        },
        onExit: receivePort.sendPort);
  } catch (e) {
    debugPrint('Isolate failed: $e');
    receivePort.close();
    rethrow;
  }
}

void _runBackend(final Map<String, dynamic> args) {
  final SendPort port = args['port'];

  final Stream<String> logs = runCutting(
      backend: args['backend'],
      audioPath: args['audio_path'],
      outputPath: args['output_path'],
      videosPath: args['videos_path'],
      beatTimes: args['beat_times'],
      ffmpegInstall: args['ffmpeg_install'],
      ffmpegPresent: args['ffmpeg_present'],
      imageOverlay: args['image_overlay']);

  logs.listen((log) => port.send(log));
}

Stream<String> runCutting({
  required File backend,
  required String audioPath,
  required String outputPath,
  required String videosPath,
  required List<double> beatTimes,
  File? imageOverlay,
  bool ffmpegPresent = false,
  Directory? ffmpegInstall,
}) async* {
  final List<String> beats = [];
  for (final double value in beatTimes) {
    beats.add('--beat');
    beats.add('${value / 1000}'); // Program expects the timestamps in seconds
  }

  final Process process = await Process.start(
    'java',
    [
      '-jar',
      backend.path,
      '--audio',
      audioPath,
      '--videos',
      videosPath,
      '--output',
      outputPath,
      if (ffmpegPresent && ffmpegInstall != null) ...['ffmpeg', ffmpegInstall.path],
      if (imageOverlay != null) ...['--image_overlay', imageOverlay.path], // love dart for allowing spreads like this :)
      ...beats
    ],
  );

  //process.stdout.transform(utf8.decoder).forEach(print);
  //process.stderr.transform(utf8.decoder).forEach(print);

  yield* process.stdout.transform(utf8.decoder);

  // Potential error log.
  final List<String> errorLog = await process.stderr.transform(utf8.decoder).asyncMap((event) => 'Error: $event').toList();

  for (final String error in errorLog) {
    yield 'Error: $error';
  }

  // process exited non-successful
  if (await process.exitCode != 0) {
    throw Exception('Cutting process was not successful. Please check the output logs.');
  }
}
