import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const EVNProApp());
}

class EVNProApp extends StatelessWidget {
  const EVNProApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'EVN Pro',
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
  InAppWebViewController? _webViewController;
  bool _loading = true;

  Future<void> _shareFile(String content, String filename) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], text: filename);
    } catch (e) {
      debugPrint('Share file error: $e');
    }
  }

  Future<void> _saveImage(String base64Data, String filename) async {
    try {
      final data = base64Data.contains(',')
          ? base64Data.split(',')[1]
          : base64Data;
      final bytes = base64Decode(data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      debugPrint('Save image error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b3e),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialFile: 'assets/index.html',
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
                allowsInlineMediaPlayback: true,
                mediaPlaybackRequiresUserGesture: false,
                useOnDownloadStart: true,
                isFraudulentWebsiteWarningEnabled: false,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                controller.addJavaScriptHandler(
                  handlerName: 'shareFile',
                  callback: (args) {
                    if (args.length >= 2) {
                      _shareFile(args[0].toString(), args[1].toString());
                    }
                    return null;
                  },
                );
                controller.addJavaScriptHandler(
                  handlerName: 'saveImage',
                  callback: (args) {
                    if (args.length >= 2) {
                      _saveImage(args[0].toString(), args[1].toString());
                    }
                    return null;
                  },
                );
              },
              onLoadStop: (controller, url) async {
                setState(() => _loading = false);
                await controller.evaluateJavascript(source: """
                  window._flutterShare = function(content, filename) {
                    window.flutter_inappwebview.callHandler('shareFile', content, filename);
                  };
                  window._flutterSaveImage = function(base64Data, filename) {
                    window.flutter_inappwebview.callHandler('saveImage', base64Data, filename || 'image.png');
                  };
                  document.addEventListener('click', function(e) {
                    var a = e.target.closest('a[download]');
                    if (a && a.href && a.href.startsWith('blob:')) {
                      e.preventDefault();
                      fetch(a.href)
                        .then(r => r.text())
                        .then(text => {
                          window._flutterShare(text, a.download || 'backup.json');
                        });
                    }
                  }, true);
                """);
              },
            ),
            if (_loading)
              const ColoredBox(
                color: Color(0xFF0d1b3e),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text('EVN Pro',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
