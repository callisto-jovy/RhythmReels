import 'package:flutter/material.dart';
import 'package:future_debounce_button/future_debounce_button.dart';
import 'package:updat/theme/chips/flat_with_check_for.dart';
import 'package:updat/updat_window_manager.dart';

import 'pages/fill_in_page.dart';
import 'src/version.dart' as version;
import 'util/utils.dart';
import 'widgets/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Cutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Video Cutter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _solveEnvironmentAndNavigate() async {
    return FFMpegHelper()
        .isFFMpegPresent()
        .then((value) async => value ? value : await FFMpegHelper.instance.setupFFMpeg())
        .then((value) => value
            ? context.navigatePage((context) => const FillInPage())
            : throw Exception('Could not set up ffmpeg.'))
        .catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar('$e'));
    });
  }

  Widget _buildNextButton() {
    return FutureDebounceButton<void>(
      buttonType: FDBType.filledTonal,
      onPressed: _solveEnvironmentAndNavigate,
      actionCallText: 'Next',
      onAbort: null,
      errorStateDuration: const Duration(seconds: 10),
      successStateDuration: const Duration(seconds: 5),
    );
  }

  // Reference: https://github.com/aguilaair/updat/blob/main/example/lib/main.dart
  @override
  Widget build(BuildContext context) {
    return UpdatWindowManager(
      appName: widget.title,
      currentVersion: version.packageVersion,
      getLatestVersion: getLatestVersion,
      getBinaryUrl: getLatestBinary,
      getChangelog: getChangeLog,
      updateChipBuilder: flatChipWithCheckFor,
      closeOnInstall: true,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          centerTitle: true,
        ),
        body: Center(
          child: SizedBox(
            width: 400,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const Padding(padding: EdgeInsets.all(10)),
                  _buildNextButton(),
                ]),
          ),
        ),
      ),
    );
  }
}
