import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  final List<String> urls = [
    "http://127.0.0.1:8001/dashboard",
    "http://127.0.0.1:8000/dashboard",
    "http://127.0.0.1:8002/dashboard",
  ];

  late final WebViewController _controller;
  int _currentIndex = 0;
  bool _loading = true;
  bool _allFailed = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // <-- request on app open

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (_) => _tryNextUrl(),
        ),
      );

    _loadCurrentUrl();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.storage,
      Permission.photos,        // Android 13+ images
      Permission.videos,        // Android 13+ videos
    ].request();
  }

  void _loadCurrentUrl() {
    if (_currentIndex < urls.length) {
      _controller.loadRequest(Uri.parse(urls[_currentIndex]));
    } else {
      setState(() => _allFailed = true);
    }
  }

  void _tryNextUrl() {
    if (_currentIndex < urls.length - 1) {
      _currentIndex++;
      _loadCurrentUrl();
    } else {
      setState(() => _allFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Stack(
        children: [
          if (!_allFailed) WebViewWidget(controller: _controller),
          if (_loading && !_allFailed)
            const Center(child: CircularProgressIndicator()),
          if (_allFailed)
            const Center(
              child: Text("Unable to load dashboard",
                  style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
  }
}