import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // Configure this URL
  static const String _versionUrl = 'https://client.urbot.ai/version.json';

  Future<Map<String, dynamic>?> _fetchVersionInfo() async {
    try {
      final response = await http.get(Uri.parse(_versionUrl));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Failed to fetch version info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching version info: $e');
      return null;
    }
  }

  Future<void> checkForUpdate(BuildContext context, {bool showNoUpdateDialog = true}) async {
    print("Entered checkforUpdate");
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    int currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

    print('Current app version code: $currentVersionCode');

    final versionInfo = await _fetchVersionInfo();
    print(versionInfo);
    if (versionInfo == null) {
      print("Could not connect to update server.");
      if (showNoUpdateDialog) _showErrorDialog(context, "Could not connect to update server.");
      return;
    }

    int latestVersionCode = versionInfo['latestVersionCode'] as int;
    String latestVersionName = versionInfo['latestVersionName'] as String;
    String apkUrl = versionInfo['apkUrl'] as String;
    String releaseNotes = versionInfo['releaseNotes'] as String;

    print('Latest version code from server: $latestVersionCode');

    if (latestVersionCode > currentVersionCode) {
      bool forceUpdate = true; // Or based on your versionInfo logic
      _showUpdateDialog(context, latestVersionName, releaseNotes, apkUrl, forceUpdate);
    } else {
      if (showNoUpdateDialog) {
         _showNoUpdateDialog(context);
      }
      debugPrint('App is up to date.');
    }
  }

  // --- MODIFIED SECTION ---
  // We now use url_launcher to open the APK URL in the browser.

  void _showUpdateDialog(BuildContext context, String versionName, String releaseNotes, String apkUrl, bool forceUpdate) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => !forceUpdate,
          child: AlertDialog(
            title: Text('Update Available: v$versionName'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  const Text('A new version of the app is available.'),
                  const SizedBox(height: 10),
                  const Text('Release Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(releaseNotes),
                ],
              ),
            ),
            actions: <Widget>[
              if (!forceUpdate)
                TextButton(
                  child: const Text('Later'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              TextButton(
                child: const Text('Update Now'),
                onPressed: () {
                  // The original call to _downloadAndInstallApk is replaced by this.
                  _launchUpdateUrl(apkUrl, context);
                  // We can pop the dialog immediately as the browser will take over.
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchUpdateUrl(String apkUrl, BuildContext context) async {
    final Uri url = Uri.parse(apkUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        // If launching fails, show an error dialog.
        _showErrorDialog(context, 'Could not launch the update URL: $apkUrl');
    }
  }
  // --- END OF MODIFIED SECTION ---


  void _showNoUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Updates'),
          content: Text('You are using the latest version of the app.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // The _requestPermissions and _downloadAndInstallApk methods
  // are no longer needed and have been removed.
}