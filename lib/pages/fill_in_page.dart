import 'package:flutter/material.dart';
import 'package:future_debounce_button/future_debounce_button.dart';
import '../util/audio/audio_loader.dart' as audio_loader;
import '../util/utils.dart';
import '../widgets/widgets.dart';
import 'audio_analysis_page.dart';

class FillInPage extends StatefulWidget {
  const FillInPage({super.key});

  @override
  State<FillInPage> createState() => _FillInPageState();
}

class _FillInPageState extends State<FillInPage> {
  /// [TextEditingController] used for the audio url
  final TextEditingController _audioUrlController = TextEditingController();

  /// [TextEditingController] used for the start time.
  final TextEditingController _startTimeController = TextEditingController();

  /// [TextEditingController] used for the end time.
  final TextEditingController _endTimeController = TextEditingController();

  /// [GlobalKey] which wraps all the text fields with a validation mechanism
  final GlobalKey<FormState> _formKey = GlobalKey();


  // TODO: move this elsewhere

  final RegExp ffmpegTimePattern = RegExp(r'^(\d\d:\d\d:\d\d)$|^(-)?[0-9]+(ms|us|s)?$');

  @override
  void dispose() {
    super.dispose();
    _audioUrlController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
  }

  Future<void> _downloadAndNavigate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String url = _audioUrlController.text;
    final String start = _startTimeController.text;
    final String end = _endTimeController.text;

    final Audio audio = Audio(url: url, startTime: start, endTime: end);

    return audio_loader
        .loadAudio(audio)
        .then((value) => audio_loader.loadAudioData(audio, value))
        .then((value) => context.navigatePage((context) => AudioAnalysis(data: value)))
        .catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar('$e'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Audio selection'),
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _audioUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Audio Url',
                  ),
                  validator: (value) {
                    return (value != null && value.isEmpty) ? 'The given url may not be empty!' : null;
                  },
                ),
                TextFormField(
                  controller: _startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Time to start the audio',
                  ),
                  validator: (value) {
                    return (value != null && !ffmpegTimePattern.hasMatch(value)) ? 'Given time does not match with Ffmpeg specification.' : null;
                  },
                ),
                TextFormField(
                  controller: _endTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Time to end the audio',
                  ),
                  validator: (value) {
                    return (value != null && !ffmpegTimePattern.hasMatch(value)) ? 'Given time does not match with Ffmpeg specification.' : null;
                  },
                ),
                FutureDebounceButton<void>(
                  buttonType: FDBType.filledTonal,
                  onPressed: _downloadAndNavigate,
                  actionCallText: 'Load',
                  onAbort: null,
                  errorStateDuration: const Duration(seconds: 10),
                  successStateDuration: const Duration(seconds: 5),
                ),
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
      ),
    );
  }
}
