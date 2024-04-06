import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/backend/backend.dart' as backend;
import '../util/utils.dart';
import '../widgets/widgets.dart';

class ProgramOutputPage extends StatefulWidget {
  final String audioPath;
  final List<double> beatTimes;

  const ProgramOutputPage({super.key, required this.audioPath, required this.beatTimes});

  @override
  State<ProgramOutputPage> createState() => _ProgramOutputPageState();
}

class _ProgramOutputPageState extends State<ProgramOutputPage> {
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _videosController = TextEditingController(text: 'videos.txt');
  final StreamController<String> _streamController = StreamController();
  final ScrollController _scrollLogController = ScrollController();

  // [File] which contains the export result from the image editor.
  File? imageOverlay;

  final GlobalKey<ProImageEditorState> _imageEditor = GlobalKey();

  @override
  void initState() {
    super.initState();

    // load previous input

    getPreferences().then((value) {
      _outputController.text = value.getString(kOutputKey) ?? _outputController.text;
      _videosController.text = value.getString(kVideosKey) ?? _videosController.text;
    }).then((value) => setState(() {}));
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    // save text contents
    await _savePreferences();

    await _streamController.close();
    _outputController.dispose();
    _videosController.dispose();
    _scrollLogController.dispose();
  }

  Future<void> _savePreferences() async {
    final SharedPreferences preferences = await getPreferences();
    await preferences.setString(kOutputKey, _outputController.text);
    await preferences.setString(kVideosKey, _videosController.text);
  }

  Future<void> _saveEditorConfig() async {
    return getPreferences().then((pref) => _imageEditor.currentState
        ?.exportStateHistory(
          // All configurations are optional
          configs: const ExportEditorConfigs(
            exportPainting: true,
            exportText: true,
            exportCropRotate: false,
            exportFilter: true,
            exportEmoji: true,
            exportSticker: true,
            historySpan: ExportHistorySpan.current,
          ),
        )
        .toJson()
        .then((value) => pref.setString(kEditorStateKey, value)));
  }

  Future<void> _runCutter() async {
    // save the text contents
    await _savePreferences();

    final StringBuffer logBuffer = StringBuffer();
    // Transformer that concatenates all the stream's data using a [StringBuffer]
    final transformer = StreamTransformer<dynamic, String>.fromHandlers(
      handleData: (data, sink) {
        // clear the buffer, every now and then -- limit the amount of data to 120.
        if(logBuffer.length > 120) {
          logBuffer.clear();
        }

        logBuffer.write(data);

        sink.add(logBuffer.toString());

      },
    );

    // port for the isolate.
    final ReceivePort receivePort = ReceivePort();

    receivePort.transform(transformer).listen((message) => _streamController.add(message.toString()));

    backend.runBackendIsolate(
        receivePort: receivePort,
        audioPath: widget.audioPath,
        outputPath: _outputController.text,
        videosPath: _videosController.text,
        beatTimes: widget.beatTimes,
        imageOverlay: imageOverlay);
  }

  Future<void> _openEditor() async {
    // load previous editor state
    final String? previousState = await getPreferences().then((value) => value.getString(kEditorStateKey));

    final ImportStateHistory? history =
        previousState == null ? null : ImportStateHistory.fromJson(previousState, configs: const ImportEditorConfigs(mergeMode: ImportEditorMergeMode.merge));

    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditor.asset(
          'assets/transparent_9_16.png',
          key: _imageEditor,
          onImageEditingComplete: (Uint8List bytes) async {
            // save the bytes into a temp file & use that file in the actual editing process.

            _saveEditorConfig().then((value) => saveImageBytes(bytes)).then((value) => imageOverlay = value).then((value) => Navigator.pop(context));
          },
          configs: ProImageEditorConfigs(
            initStateHistory: history,
            cropRotateEditorConfigs: const CropRotateEditorConfigs(enabled: false),
            emojiEditorConfigs: const EmojiEditorConfigs(
              enabled: true,
              initScale: 5.0,
              textStyle: TextStyle(fontFamily: 'AppleColorEmoji', fontFamilyFallback: ['NotoColorEmoji']),
              checkPlatformCompatibility: false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramOutput() {
    return SizedBox(
      height: 150,
      child: StreamBuilder(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          //return Text(snapshot.hasError ? 'Error occurred: ${snapshot.error}' : snapshot.data ?? 'Waiting for output');

          return SingleChildScrollView(
            controller: _scrollLogController,
            scrollDirection: Axis.vertical,
            child: Text(snapshot.hasError ? 'Error occurred: ${snapshot.error}' : snapshot.data ?? 'Waiting for output'),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Cutting'),
      ),
      body: Center(
        child: SizedBox(
          height: 600,
          width: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _outputController,
                decoration: const InputDecoration(
                  labelText: 'Output directory',
                ),
                validator: (value) {
                  return (value != null && value.isEmpty) ? 'The given url may not be empty!' : null;
                },
              ),
              TextFormField(
                controller: _videosController,
                decoration: const InputDecoration(
                  labelText: 'Videos input file',
                ),
                validator: (value) {
                  return (value != null && value.isEmpty) ? 'The given url may not be empty!' : null;
                },
              ),
              TextButton(
                onPressed: _openEditor,
                style: textButtonStyle(context),
                child: const Text('Open editor'),
              ),
              TextButton(
                onPressed: _runCutter,
                style: textButtonStyle(context),
                child: const Text('Cut'),
              ),
              _buildProgramOutput()
            ]
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.all(10),
                    child: e,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
