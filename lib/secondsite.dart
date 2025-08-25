// ip_webview_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class IpWebViewPage extends StatefulWidget {
  final String? ipAddress;

  const IpWebViewPage({Key? key, required this.ipAddress}) : super(key: key);

  @override
  State<IpWebViewPage> createState() => _IpWebViewPageState();
}

class _IpWebViewPageState extends State<IpWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // Set platform implementation
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("http://${widget.ipAddress}:8085"));

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("WebView: ${widget.ipAddress}:8085")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
