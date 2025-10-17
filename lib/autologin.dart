import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';


class AutoLoginPage extends StatelessWidget {
  final String userId;
  const AutoLoginPage({super.key, required this.userId});


  @override
    Widget build(BuildContext context) {
      final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('http://10.0.2.2:4567/auto-login?userId=$userId'));
      // 10.0.2.2 connects Android emulator to local backend


      return Scaffold(
        appBar: AppBar(title: const Text('Logging In...')),
        body: WebViewWidget(controller: controller),
      );
    }
}