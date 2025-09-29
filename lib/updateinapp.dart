import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:android_package_installer/android_package_installer.dart';

class ApkUpdater {
  final Dio _dio = Dio();

  /// Downloads APK from [apkUrl] and reports progress via [onProgress].
  /// Throws an exception if download fails.
  Future<void> downloadAndInstall({
    required String apkUrl,
    required void Function(double progress) onProgress,
  }) async {
    if (!Platform.isAndroid) {
      throw Exception("APK installation is only supported on Android.");
    }

    final dir = await getTemporaryDirectory();
    final apkPath = "${dir.path}/app-release.apk";

    await _dio.download(
      apkUrl,
      apkPath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          onProgress(received / total);
        }
      },
    );

    // Trigger system installer
    await AndroidPackageInstaller.installApk(apkFilePath: apkPath);
  }
}
