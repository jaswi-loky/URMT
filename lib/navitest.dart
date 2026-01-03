import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

class SingleHandJoystickPage extends StatefulWidget {
  final String? robotIp;
  const SingleHandJoystickPage({super.key, required this.robotIp});

  @override
  State<SingleHandJoystickPage> createState() =>
      _SingleHandJoystickPageState();
}

class _SingleHandJoystickPageState extends State<SingleHandJoystickPage> {
  // =======================
  // 参数区（你之后只需要调这里）
  // =======================
  static const double MAX_LINEAR = 0.8;
  static const double MAX_ANGULAR = 0.6;
  static const double DEAD_ZONE = 0.1;

  static const int SEND_INTERVAL_MS = 50; // 10Hz

  static const int RELEASE_DECAY_STEPS = 10;
  static const double RELEASE_LINEAR_FACTOR = 0.88;
  static const double RELEASE_ANGULAR_FACTOR = 0.85;
  bool _manualOverrideActive = false;
  Timer? _manualOverrideTimer;
  bool _sending = false;
  double _pendingLinear = 0.0;
  double _pendingAngular = 0.0;
  bool _isBraking = false;
  final ip = currentRobotIp.value;


  // =======================
  // 状态变量
  // =======================
  Offset _stickOffset = Offset.zero; // [-1,1] normalized
  double _linear = 0.0;
  double _angular = 0.0;

  Timer? _sendTimer;
  Timer? _releaseTimer;

  double _releaseLinear = 0.0;
  double _releaseAngular = 0.0;
  int _releaseStep = 0;

  // =======================
  // 摇杆 → 速度映射
  // =======================
  @override
  void initState() {
    super.initState();
    print("NAVIPAGE INIT");
  } 

  @override
void dispose() {     // ← 你的 monitor stop
  _releaseTimer?.cancel();
  _sendTimer?.cancel();
  super.dispose();
}

  void _updateVelocity(double x, double y) {
  if (!_manualOverrideActive) {
    _startManualOverrideInterceptor();
  }
  if (_isBraking) {
    _releaseTimer?.cancel();
    _isBraking = false;
  }
    // 打断松手缓冲
    _releaseTimer?.cancel();

    double dx = (x.abs() < DEAD_ZONE) ? 0.0 : x;
    double dy = (y.abs() < DEAD_ZONE) ? 0.0 : y;

    double linear = dy * dy.abs() * MAX_LINEAR;

// 转向权重：连续变化
    if (dy != 0) {
      final turnWeight = 1.0 - 0.2 * dx.abs();
      linear *= turnWeight.clamp(0.7, 1.0);
    }

    double angular = -dx.sign * dx * dx * MAX_ANGULAR;

    setState(() {
      _linear = linear;
      _angular = angular;
    });

    _startSendLoop();
  }

  // =======================
  // 定频发送
  // =======================
  void _startSendLoop() {
    _sendTimer ??= Timer.periodic(
      const Duration(milliseconds: SEND_INTERVAL_MS),
      (_) => _queueMove(_linear, _angular),
    );
  }

  void _stopSendLoop() {
    _sendTimer?.cancel();
    _sendTimer = null;
  }


void _queueMove(double v, double a, {bool force = false}) {
  if (_isBraking && !force) {
    // 刹车期间，拒绝普通速度
    return;
  }
  _pendingLinear = v;
  _pendingAngular = a;

  if (!_sending) {
    _flushMove();
  }
}

Future<void> _flushMove() async {
  _sending = true;

  final v = _pendingLinear;
  final a = _pendingAngular;

  final url =
      'http://$ip:9001/api/joy_control'
      '?linear_velocity=${v.toStringAsFixed(3)}'
      '&angular_velocity=${a.toStringAsFixed(3)}';

  try {
    await http
        .post(Uri.parse(url))
        .timeout(const Duration(milliseconds: 200));
  } catch (_) {
    // 这里不要急停，避免误触
  }

  _sending = false;

  // ⭐ 关键：如果期间值被更新过，立刻再发
  if (v != _pendingLinear || a != _pendingAngular) {
    _flushMove();
  }
}

  // =======================
  // 松手缓冲减速
  // =======================
void _onStickRelease() {
  _stopSendLoop();

  _isBraking = true;
  _releaseLinear = _linear;
  _releaseAngular = _angular;
  _releaseStep = 0;

  _releaseTimer = Timer.periodic(
    const Duration(milliseconds: SEND_INTERVAL_MS),
    (_) {
      if (_releaseStep >= RELEASE_DECAY_STEPS) {
        _finishRelease();
        return;
      }

      _releaseLinear *= RELEASE_LINEAR_FACTOR;
      _releaseAngular *= RELEASE_ANGULAR_FACTOR;

      _queueMove(_releaseLinear, _releaseAngular, force: true);
      _releaseStep++;
      print('[BRAKE] $_releaseLinear');
    },
  );
}

void _finishRelease() {
  _releaseTimer?.cancel();
  _releaseTimer = null;
  _isBraking = false;

  _queueMove(0, 0,force: true);

  setState(() {
    _linear = 0;
    _angular = 0;
    _stickOffset = Offset.zero;
  });
}

  // =======================
  // 急停
  // =======================
  void _emergencyStop() {
    _releaseTimer?.cancel();
    _stopSendLoop();
    _hardStopBurst();

    setState(() {
      _linear = 0;
      _angular = 0;
      _stickOffset = Offset.zero;
    });
  }

void _startManualOverrideInterceptor() {
  _manualOverrideActive = true;
  print("Manual override interceptor started");

  int attempts = 0;

  _manualOverrideTimer = Timer.periodic(
    const Duration(milliseconds: 200), // 高频
    (_) async {
      attempts++;

      try {

        // 1️⃣ 查询状态
        final statusResp = await http.get(
          Uri.parse('http://$ip:9001/api/robot_status'),
        );

        final data = jsonDecode(statusResp.body);
        final status = data['results']['running_status'];
        final target = data['results']['move_target'];

        // 2️⃣ 如果正在返回 / 充电 → 立刻 cancel
        if (status == "running" &&
            target != null &&
            target.startsWith("charge")) {
          final cancelUrl = Uri.parse(
            "http://$ip:19001/api/tools/operation/task/cancel",
          );
          await http.post(cancelUrl);
          print("Manual override: cancel sent");
        }
      } catch (_) {}

      // 3️⃣ 最多执行 1 秒（5 次）
      if (attempts >= 5) {
        _manualOverrideTimer?.cancel();
        _manualOverrideTimer = null;
        _manualOverrideActive = false;
        print("Manual override interceptor finished");
      }
    },
  );
}




  void _hardStopBurst() { for (int i = 0; i < 3; i++) { Future.delayed( Duration(milliseconds: i * 30), () => _queueMove(0, 0), ); } }

  void _enterManualOverride() {
    _manualOverrideTimer?.cancel();
    _manualOverrideActive = true;

    _manualOverrideTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => _forceCancelReturn(),
    );

    // 3 秒后自动退出
    Future.delayed(const Duration(seconds: 3), () {
      _manualOverrideTimer?.cancel();
      _manualOverrideTimer = null;
      _manualOverrideActive = false;
    });
  }

  Future<void> _forceCancelReturn() async {
    try {
      await http.post(
        Uri.parse("http://$ip:19001/api/tools/operation/task/cancel"),
      );
    } catch (_) {}
  }


  // =======================
  // UI
  // =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Single-Hand Joystick')),
      body: Column(
        children: [
Expanded(
  child: LayoutBuilder(
    builder: (context, constraints) {
      final maxSize =
          min(constraints.maxWidth, constraints.maxHeight) * 0.6;

      return Center(
        child: SizedBox(
          width: maxSize,
          height: maxSize,
          child: _buildJoystick(),
        ),
      );
    },
  ),
),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'v: ${_linear.toStringAsFixed(2)} m/s   '
                  'a: ${_angular.toStringAsFixed(2)} rad/s',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 12),
Stack(
  clipBehavior: Clip.none,
  children: [
    // 主 STOP 按钮
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        minimumSize: const Size(double.infinity, 56),
      ),
      onPressed: _emergencyStop,
      child: const Text(
        'EMERGENCY STOP',
        style: TextStyle(fontSize: 18),
      ),
    ),
  ],
),

              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildJoystick() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final size = min(constraints.maxWidth, constraints.maxHeight);

      return GestureDetector(
        onPanStart: (_) {
          _releaseTimer?.cancel();
          setState(() => _stickOffset = Offset.zero);
          _enterManualOverride();
        },
        onPanUpdate: (details) {
          final center = Offset(size / 2, size / 2);
          final delta = details.localPosition - center;
          final radius = size / 2;

          Offset normalized = Offset(
            delta.dx / radius,
            delta.dy / radius,
          );

          if (normalized.distance > 1) {
            normalized = normalized / normalized.distance;
          }

          setState(() => _stickOffset = normalized);

          // Y 轴反向（屏幕向下是正）
          _updateVelocity(normalized.dx, -normalized.dy);
        },
        onPanEnd: (_) => _onStickRelease(),
        onPanCancel: _onStickRelease,
        child: CustomPaint(
          size: Size(size, size),
          painter: _JoystickPainter(_stickOffset),
        ),
      );
    },
  );
}




}

// =======================
// 摇杆绘制
// =======================
class _JoystickPainter extends CustomPainter {
  final Offset offset;
  _JoystickPainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final basePaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    final knobPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, basePaint);

    final knobCenter = center +
        Offset(offset.dx * radius, offset.dy * radius);

    canvas.drawCircle(knobCenter, radius * 0.2, knobPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
