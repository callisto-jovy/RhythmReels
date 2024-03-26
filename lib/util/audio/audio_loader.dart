import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import '../utils.dart';

Future<AudioData> loadAudioData(final Audio audio, final File audioFile) async {
  final String fileName = '${audio.hashCode}.bin';
  final File output = File(path.join(dataDirectory.path, fileName));

  if (!await output.exists()) {
    return AudioData(audioFile, []);
  }

  final Uint8List bytes = await output.readAsBytes();
  final Float64List asFloat64 = Float64List.view(bytes.buffer);

  return AudioData(audioFile, asFloat64.toList());
}

Future<void> saveAudioData(final AudioData audioData, final List<double> beatPositions) async {
  if (beatPositions.isEmpty) {
    return;
  }

  final String fileName = '${path.basenameWithoutExtension(audioData.audioFile.path)}.bin';
  final File output = File(path.join(dataDirectory.path, fileName));

  final Float64List beatsAsFloat64 = Float64List.fromList(beatPositions);

  await output.writeAsBytes(beatsAsFloat64.buffer.asInt8List(), mode: FileMode.write);
}

Future<File> loadAudio(final Audio audio) async {
  final String fileName = '${audio.hashCode}.wav';
  final File audioFile = File(path.join(downloadDirectory.path, fileName));

  if (await audioFile.exists()) {
    return audioFile;
  }

  await downloader.download(url: audio.url, output: audioFile, command: [
    "--extract-audio",
    "--audio-format",
    "wav",
    "--postprocessor-args",
    "ffmpeg: -ss ${audio.startTime} ${audio.endTime.isEmpty ? '' : '-to ${audio.endTime}'}",
  ]);

  return audioFile;
}
