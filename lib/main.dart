import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:updat/theme/chips/floating_with_silent_download.dart';
import 'package:updat/updat.dart';

import 'package:http/http.dart' as http;
import 'package:updat/updat_window_manager.dart';
import 'src/version.dart' as version;
import 'pages/fill_in_page.dart';
import 'util/utils.dart';
import 'widgets/styles.dart';

Future<void> main() async {
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
  final (bool, String) _environmentStatus = checkEnvironment();

  Future<String> _getLatestVersion() async {
    // Github gives us a super useful latest endpoint, and we can use it to get the latest stable release
    final data = await http.get(Uri.parse(
      "https://api.github.com/repos/$kGitHubProject/releases/latest",
    ));

    // Return the tag name, which is always a semantically versioned string.
    return jsonDecode(data.body)["tag_name"];
  }

  Widget _buildNextButton() {
    return Directionality(
      textDirection: TextDirection.rtl, child: TextButton.icon(
        onPressed: _environmentStatus.$1 ? () => context.navigatePage((context) => const FillInPage()) : null,
        style: textButtonStyle(context),
        icon: const Icon(Icons.navigate_before),
        label: const Text('Next'),
      ),
    );
  }

  // Reference: https://github.com/aguilaair/updat/blob/main/example/lib/main.dart
  @override
  Widget build(BuildContext context) {
    return UpdatWindowManager(
      appName: widget.title,
      currentVersion: version.packageVersion,
      getLatestVersion: _getLatestVersion,
      getBinaryUrl: (latestVersion) async {
        return "https://github.com/$kGitHubProject/releases/download/$latestVersion/video_cutter-${Platform.operatingSystem}-$latestVersion.zip";
      },
      updateChipBuilder: floatingExtendedChipWithSilentDownload,
      child: Scaffold(
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
              _buildNextButton()
            ]),
          ),
        ),
      ),
    );
  }
}
