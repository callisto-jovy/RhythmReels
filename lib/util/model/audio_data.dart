import 'dart:core';
import 'dart:io';

class AudioData {
  final File audioFile;
  final List<double> beatPositions;

  AudioData(this.audioFile, this.beatPositions);

  String get path => audioFile.path;
}
