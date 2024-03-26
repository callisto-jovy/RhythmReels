import 'dart:io';

import 'package:auto_update/auto_update.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_youtube_editor_ui/pages/fill_in_page.dart';
import 'package:simple_youtube_editor_ui/util/environment_helper.dart';
import 'package:simple_youtube_editor_ui/widgets/build_context_extension.dart';

import 'widgets/styles.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Pizza cutter'),
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
  final (bool, String) _environmentStatus = checkEnvironment();
  final Map<dynamic, dynamic> _packageUpdateUrl = {};

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    Map<dynamic, dynamic> updateUrl;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      updateUrl = await AutoUpdate.fetchGithub("callisto-jovy", "video_cutter_ui");
    } on PlatformException {
      updateUrl = {'assetUrl': 'Failed to get the url of the new release.'};
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _packageUpdateUrl.clear();
      _packageUpdateUrl.addAll(updateUrl);
    });
  }

  Widget _buildUpdateButton() {
    return TextButton(
      onPressed: () async {
        if (_packageUpdateUrl['assetUrl'].isNotEmpty &&
            _packageUpdateUrl['assetUrl'] != "up-to-date" &&
            (_packageUpdateUrl['assetUrl'] as String).contains("https://")) {
          try {
            await AutoUpdate.downloadAndUpdate(_packageUpdateUrl['assetUrl']);
          } on PlatformException {
            setState(() {
              _packageUpdateUrl['assetUrl'] = "Unable to download";
            });
          }
        }
      },
      style: textButtonStyle(context),
      child: const Text('Check for update'),
    );
  }

  Widget _buildNextButton() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextButton.icon(
        onPressed: _environmentStatus.$1 ? () => context.navigatePage((context) => const FillInPage()) : null,
        style: textButtonStyle(context),
        icon: const Icon(Icons.navigate_before),
        label: const Text('Next'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const Padding(padding: EdgeInsets.all(10)),
            Text('Environment status:\n${_environmentStatus.$2}', style: Theme.of(context).textTheme.headlineSmall),
            const Padding(padding: EdgeInsets.all(10)),
            _buildUpdateButton(),
            const Padding(padding: EdgeInsets.all(2)),
            _buildNextButton()
          ]),
        ),
      ),
    );
  }
}
