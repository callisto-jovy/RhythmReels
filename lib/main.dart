import 'dart:io';

import 'package:flutter/material.dart';
import 'package:updat/updat.dart';

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

  @override
  void initState() {
    super.initState();
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
            UpdatWidget(
              currentVersion: "1.0.0",
              getLatestVersion: () async {
                // Here you should fetch the latest version. It must be semantic versioning for update detection to work properly.
                return "1.0.1";
              },
              getBinaryUrl: (latestVersion) async {
                return "https://github.com/latest/release/video_cutter-windows.zip";
              },
              // Lastly, enter your app name so we know what to call your files.
              appName: widget.title,
            ),
            const Padding(padding: EdgeInsets.all(2)),
            _buildNextButton()
          ]),
        ),
      ),
    );
  }
}
