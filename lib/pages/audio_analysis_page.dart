import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:path/path.dart' as path;
import 'package:simple_youtube_editor_ui/pages/program_output_page.dart';
import 'package:simple_youtube_editor_ui/util/audio/audio_util.dart';
import 'package:simple_youtube_editor_ui/util/model/audio_data.dart';
import 'package:simple_youtube_editor_ui/widgets/build_context_extension.dart';
import 'package:simple_youtube_editor_ui/widgets/time_stamp_painter.dart';
import 'package:wav/wav_file.dart';
import '../util/audio/audio_loader.dart' as audio_loader;

import '../widgets/audio_player_controls.dart';
import '../widgets/styles.dart';

class AudioAnalysis extends StatefulWidget {
  final AudioData data;

  const AudioAnalysis({super.key, required this.data});

  @override
  State<AudioAnalysis> createState() => _AudioAnalysisState();
}

class _AudioAnalysisState extends State<AudioAnalysis> {
  /// [AudioPlayer] instance to play the audio from the file, in order to make the preview interactive.
  final AudioPlayer _player = AudioPlayer();

  /// [StreamSubscription] for the audio player's position. Canceled in dispose.
  late final StreamSubscription _playerPositionStream;

  /// [Duration] for the position of the audio player.
  Duration _playerPosition = const Duration();

  /// The length [Duration] of the audio file.
  Duration _audioLength = const Duration(milliseconds: 10000); //Placeholder duration

  /// [List] of the audio file's audio samples.
  final List<double> _samples = [];

  ///
  double _lengthInMillis = 0;

  /// [GlobalKey] assigned to the timestamp painer.
  final GlobalKey _paintKey = GlobalKey();

  /// The [Offset] of the latest mouse hit.
  Offset? _hitOffset;

  ///
  final List<double> beatTimes = [];

  final FocusNode _keyboardFocus = FocusNode();

  /// Starts to load the audio from the config video path.
  /// Calculates the length in milliseconds, chops the samples & adds them to the [List]
  Future<void> loadAudio() async {
    final Wav wav = await Wav.readFile(widget.data.path);

    /// Total length / spp = length in seconds
    _lengthInMillis = ((wav.toMono().length / wav.samplesPerSecond) * 1000);

    final List<double> samplesData = chopSamples(wav.toMono(), wav.samplesPerSecond);

    setState(() {
      _samples.clear();
      _samples.addAll(samplesData);
    });

    // Set the max duration for the waveform
    _audioLength = Duration(milliseconds: _lengthInMillis.round());

    // Listen for position changes, so that the state can change, whenever the position passes a beat.
    _playerPositionStream = _player.onPositionChanged.listen((event) {
      setState(() {
        // Enables the waveform to display the playback.
        _playerPosition = event;
        // TODO: toggle beat if detected (was a timestamp passed?)
        // Display beat with a certain time.
      });
    });

    // reload the previous beat stamps

    beatTimes.addAll(widget.data.beatPositions);

    // Start the playback
    _player.play(DeviceFileSource(widget.data.path));
  }

  void _addTimeStampForRemoval(final List<double> timeStamp) {
    for (final double element in timeStamp) {
      beatTimes.remove(element);
    }
    _hitOffset = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
  }

  void _handleMouseInput(PointerDownEvent event) {
    final RenderBox? referenceBox = _paintKey.currentContext?.findRenderObject() as RenderBox?;

    if (referenceBox == null) {
      return;
    }

    final Offset offset = event.localPosition;

    setState(() {
      _hitOffset = offset;
    });
  }

  void _handleKeyboardInput(final KeyEvent event) {
    if (event is! KeyDownEvent) {
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _addNewTimeStamp(_playerPosition.inMilliseconds.toDouble());
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      if (_player.state == PlayerState.playing) {
        _player.pause();
      } else if (_player.state == PlayerState.paused || _player.state == PlayerState.completed) {
        _player.resume();
      }
    }
  }

  void _addNewTimeStamp(final double timeStamp) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      beatTimes.add(timeStamp);
      // Sort timestamps.
      beatTimes.sort();
      setState(() {});
    });
  }

  void _navigateToCutPage() async {
     await _player.pause();

    audio_loader
        .saveAudioData(widget.data, beatTimes)
        .then((value) => context.navigatePage((context) => ProgramOutputPage(audioPath: widget.data.path, beatTimes: beatTimes)));
  }

  @override
  void initState() {
    super.initState();
    loadAudio();
  }

  @override
  void dispose() async {
    super.dispose();
    await _playerPositionStream.cancel();
    await _player.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = context.mediaSize;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(path.basename(widget.data.path)),
      ),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(25)),
          Text('Total cuts: ${beatTimes.length}'),
          const Padding(padding: EdgeInsets.all(25)),
          Expanded(
            child: Listener(
              onPointerDown: _handleMouseInput,
              child: KeyboardListener(
                focusNode: _keyboardFocus,
                autofocus: true,
                onKeyEvent: _handleKeyboardInput,
                child: Stack(
                  children: [
                    RepaintBoundary(
                      child: PolygonWaveform(
                        samples: _samples,
                        height: size.height * 0.5,
                        width: size.width * 0.95,
                        elapsedDuration: _playerPosition,
                        maxDuration: _audioLength,
                        activeColor: Colors.greenAccent,
                      ),
                    ),
                    CustomPaint(
                      key: _paintKey,
                      size: Size(
                        size.width * 0.95,
                        size.height * 0.5,
                      ),
                      painter: TimeStampPainter(
                        timeStamps: beatTimes,
                        audioLength: _lengthInMillis,
                        hitOffset: _hitOffset,
                        hitTimeStamp: _addTimeStampForRemoval,
                        newTimeStamp: _addNewTimeStamp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                //TODO: Play / pause in a single button..
                PlayerWidget(player: _player),

                TextButton(
                  onPressed: _navigateToCutPage,
                  style: textButtonStyle(context),
                  child: const Text('Next'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
