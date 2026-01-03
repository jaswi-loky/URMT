import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';

class GlobalControlOverlay {
  static OverlayEntry? _entry;
  static bool _visible = false;

  /// 显示全局 Overlay
  static void show(BuildContext context) {
    if (_visible) return;

    _entry = OverlayEntry(
      builder: (_) => const _GlobalOverlayWidget(),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
    _visible = true;
  }

  /// 隐藏 Overlay
  static void hide() {
    _entry?.remove();
    _entry = null;
    _visible = false;
  }
}

class _GlobalOverlayWidget extends StatefulWidget {
  const _GlobalOverlayWidget();

  @override
  State<_GlobalOverlayWidget> createState() => _GlobalOverlayWidgetState();
}

class _GlobalOverlayWidgetState extends State<_GlobalOverlayWidget> {
  bool _sending = false;

  Future<void> _post(String path) async {
    final ip = currentRobotIp.value;

    if (ip == null || ip.isEmpty) {
      debugPrint('[Overlay] No robot IP, skip');
      return;
    }

    if (_sending) return;
    _sending = true;

    final url = Uri.parse('http://$ip$path');

    try {
      await http
          .post(url)
          .timeout(const Duration(milliseconds: 300));
      debugPrint('[Overlay] POST $url');
    } catch (e) {
      debugPrint('[Overlay] POST failed: $e');
    } finally {
      _sending = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 120,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            _buildButton(
              icon: Icons.keyboard_return, // 返回充电
              color: Colors.red,
              onTap: () =>
                  _post(':19001/api/tools/operation/task/go-back'),
            ),
            const SizedBox(height: 12),
            _buildButton(
              icon: Icons.cancel, // 取消任务
              color: Colors.orange,
              onTap: () =>
                  _post(':19001/api/tools/operation/task/cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black26,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
