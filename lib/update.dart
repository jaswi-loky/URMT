

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class UpdateService {
  // Configure this URL
  static const String _versionUrl = 'https://yourdomain.com/app_updates/version.json';

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
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    int currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

    debugPrint('Current app version code: $currentVersionCode');

    final versionInfo = await _fetchVersionInfo();
    if (versionInfo == null) {
      if (showNoUpdateDialog) _showErrorDialog(context, "Could not connect to update server.");
      return;
    }

    int latestVersionCode = versionInfo['latestVersionCode'] as int;
    String latestVersionName = versionInfo['latestVersion'] as String;
    String apkUrl = versionInfo['apkUrl'] as String;
    String releaseNotes = versionInfo['releaseNotes'] as String;
    int minRequiredVersionCode = (versionInfo['minRequiredVersionCode'] as int?) ?? 0;

    debugPrint('Latest version code from server: $latestVersionCode');

    if (latestVersionCode > currentVersionCode) {
      bool forceUpdate = currentVersionCode < minRequiredVersionCode;
      _showUpdateDialog(context, latestVersionName, releaseNotes, apkUrl, forceUpdate);
    } else {
      if (showNoUpdateDialog) {
         _showNoUpdateDialog(context);
      }
      debugPrint('App is up to date.');
    }
  }

  void _showUpdateDialog(BuildContext context, String versionName, String releaseNotes, String apkUrl, bool forceUpdate) { // 43
    showDialog( // 44
      context: context, // 45
      barrierDismissible: !forceUpdate, // 46
      builder: (BuildContext context) { // 47
        return WillPopScope( // 48
          onWillPop: () async => !forceUpdate, // 49
          child: AlertDialog( // 50
            title: Text('Update Available: v$versionName'), // 51
            content: SingleChildScrollView( // 52
              child: ListBody( // 53
                children: <Widget>[ // 54
                  Text('A new version of the app is available.'), // 55
                  SizedBox(height: 10), // 56
                  Text('Release Notes:', style: TextStyle(fontWeight: FontWeight.bold)), // 57
                  Text(releaseNotes), // 58
                ],
              ),
            ),
            actions: <Widget>[ // 59
              if (!forceUpdate) // 60
                TextButton( // 61
                  child: Text('Later'), // 62
                  onPressed: () { // 63
                    Navigator.of(context).pop(); // 64
                  },
                ),
              TextButton( // 65
                child: Text('Update Now'), // 66
                onPressed: () { // 67
                  Navigator.of(context).pop(); // 68
                  _downloadAndInstallApk(context, apkUrl); // 69
                },
              ),
            ],
          ),
        );
      },
    );
  }

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

  Future<bool> _requestPermissions() async {
    // For Android 10 (API 29) and below, WRITE_EXTERNAL_STORAGE is needed.
    // For Android 11 (API 30) and above, MANAGE_EXTERNAL_STORAGE is powerful,
    // but typically not needed just for app updates. Scoped storage is preferred.
    // REQUEST_INSTALL_PACKAGES is needed for Android 8.0 (API 26) and above.

    // Permission to install packages
    var installPermission = await Permission.requestInstallPackages.status;
    if (installPermission.isDenied) {
      if (await Permission.requestInstallPackages.request().isGranted) {
        // Permission granted
      } else {
        debugPrint('Install packages permission denied');
        return false; // User denied permission
      }
    } else if (installPermission.isPermanentlyDenied) {
        debugPrint('Install packages permission PERMANENTLY denied');
        // Consider guiding user to settings: openAppSettings();
        return false;
    }


    // Storage permission (primarily for older Android versions or if downloading to shared storage)
    // For newer Android, getExternalFilesDir (used below) doesn't require explicit storage permission.
    if (Platform.isAndroid) {
        // More fine-grained control might be needed depending on target Android SDK
        var storagePermission = await Permission.storage.status;
        if (storagePermission.isDenied) {
            if (await Permission.storage.request().isGranted) {
                // Permission granted
            } else {
                 debugPrint('Storage permission denied');
                return false;
            }
        } else if (storagePermission.isPermanentlyDenied) {
            debugPrint('Storage permission PERMANENTLY denied');
            // Consider guiding user to settings: openAppSettings();
            return false;
        }
    }
    return true;
  }

  Future<void> _downloadAndInstallApk(BuildContext context, String apkUrl) async {
    // Show a loading indicator if you want
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Requesting permissions...')));

    if (!await _requestPermissions()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Permissions denied. Cannot update.')));
      // Consider showing a dialog guiding user to settings if permanently denied.
      // openAppSettings();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading update... Please wait.')));

    try {
      final directory = await getExternalStorageDirectory(); // Or getApplicationDocumentsDirectory()
      if (directory == null) {
        _showErrorDialog(context, 'Could not get download directory.');
        return;
      }
      final filePath = '${directory.path}/app_update.apk';
      final file = File(filePath);

      final response = await http.get(Uri.parse(apkUrl));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('APK downloaded to: $filePath');
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide download message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download complete. Opening installer...')));

        // Open the APK file to trigger installation
        final OpenResult result = await OpenFilex.open(filePath, type: "application/vnd.android.package-archive");

        if (result.type != ResultType.done) {
          debugPrint('Error opening APK file: ${result.message}');
          _showErrorDialog(context, 'Could not open installer: ${result.message}');
        }
      } else {
        debugPrint('Failed to download APK: ${response.statusCode}');
        _showErrorDialog(context, 'Failed to download update: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading or installing APK: $e');
      _showErrorDialog(context, 'An error occurred: $e');
    }
  }
}