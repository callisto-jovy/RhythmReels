import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
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
  }

  @override
  void dispose() {
    super.dispose();
    _outputController.dispose();
    _videosController.dispose();
    _scrollLogController.dispose();
    _streamController.close();
  }

  Future<void> _runCutter() async {
    final Stream<String> logStream = backend.runCutting(
        audioPath: widget.audioPath,
        outputPath: _outputController.text,
        videosPath: _videosController.text,
        beatTimes: widget.beatTimes,
        imageOverlay: imageOverlay);

    final StringBuffer logBuffer = StringBuffer();

    logStream.listen((event) {
      logBuffer.write(event);
      _streamController.add(logBuffer.toString());
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollLogController.jumpTo(_scrollLogController.position.maxScrollExtent));
    }).onError((e) => ScaffoldMessenger.of(context).showSnackBar(errorSnackbar('$e')));
  }

  Future<void> _saveEditorConfig() async {
    /*
    await _imageEditor.currentState
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
        .stateHistory();

     */
  }

  void _openEditor() {
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
          configs: const ProImageEditorConfigs(
            cropRotateEditorConfigs: CropRotateEditorConfigs(enabled: false),
            emojiEditorConfigs: EmojiEditorConfigs(
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
