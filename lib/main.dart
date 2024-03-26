import 'package:flutter/material.dart';
import 'package:simple_youtube_editor_ui/pages/fill_in_page.dart';
import 'package:simple_youtube_editor_ui/util/environment_helper.dart';
import 'package:simple_youtube_editor_ui/widgets/build_context_extension.dart';

import 'widgets/styles.dart';

void main() {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              Text('Environment status:\n${_environmentStatus.$2}', style: Theme.of(context).textTheme.headlineSmall),
              _buildNextButton()
            ]
                .map((e) => Padding(
                      padding: const EdgeInsets.all(10),
                      child: e,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
