import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
                // Cho phép upload file & ảnh
                allowsInlineMediaPlayback: true,
                mediaPlaybackRequiresUserGesture: false,
                useOnDownloadStart: true,
                // iOS specific
                allowsPictureInPictureMediaPlayback: true,
                isFraudulentWebsiteWarningEnabled: false,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStop: (c, u) => setState(() => _loading = false),

              // Xử lý download file (xuất backup)
              onDownloadStartRequest: (controller, request) async {
                // Mở file trong Safari để download
                await SystemChannels.platform.invokeMethod(
                  'url_launcher/launch',
                  request.url.toString(),
                );
              },

              // Xử lý file picker (chọn ảnh)
              onShowFileChooser: (controller, params) async {
                // Trả về null để iOS tự xử lý file picker native
                return [];
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
