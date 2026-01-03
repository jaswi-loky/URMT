import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class naviPage extends StatefulWidget {
  final String? newIp;
  @override
  const naviPage({Key? key, required this.newIp}) : super(key: key);
  State<naviPage> createState() => _NavigatePageState();
}

enum Speed { slow, normal, fast }

class _NavigatePageState extends State<naviPage> {
  Speed _selectedSpeed = Speed.normal;
  double speed = 0.7;
  Timer? _moveTimer;
  Timer? _monitorTimer;
  Timer? _decelTimer;
  DateTime? _pressTime;
  bool _monitorStarted = false;

  int? _activeSectorIndex;
  

  static const List<String> labels = [
    'F', 'FR', 'R', 'BR', 'B', 'BL', 'L', 'FL'
  ];



  double _lastLinear = 0;
  double _lastAngular = 0;
  bool _estopActive = false;

  @override
  void initState() {
    super.initState();
    print("NAVIPAGE INIT");
    startMonitoring();
  }  

  Future<void> sendCommand(double angular, double linear) async {
    _lastAngular = angular;
    _lastLinear = linear;
    String? robotIpAddress = widget.newIp;
    final String baseUrl = 'http://$robotIpAddress:9001/api/joy_control';

    final url = Uri.parse(
        '$baseUrl?angular_velocity=$angular&linear_velocity=$linear');
    print(url);
    try {
      await http.get(url);
    } catch (e) {}
  }

  Future<void> toggleEstop() async {
    setState(() {
      _estopActive = !_estopActive;
    });

    if (_estopActive) {
      _moveTimer?.cancel();
      _decelTimer?.cancel();
      await sendCommand(0, 0);
    }

    final flag = _estopActive ? 'true' : 'false';
    final ip = widget.newIp;
    final url = Uri.parse('http://$ip:9001/api/estop?flag=$flag');
    try {
      await http.get(url);
    } catch (_) {}
  }

  void handleSectorTapDown(TapDownDetails details, double size, double innerCircle) {
    final Offset center = Offset(size / 2, size / 2);
    final Offset local = details.localPosition;
    final Offset delta = local - center;
    final double r = delta.distance;
    final double outerRadius = size / 2;
    final double innerRadius = innerCircle / 2;
    if (r < innerRadius || r > outerRadius) return;

    double angle = atan2(delta.dy, delta.dx) * 180 / pi;
    angle = angle < 0 ? angle + 360 : angle;
    int sector = ((angle + 22.5) ~/ 45) % 8;
    setState(() {
      _activeSectorIndex = sector;
    });
    handlePress(labels[sector]);
  }

  void handleSectorTapUp(TapUpDetails details) {
    setState(() {
      _activeSectorIndex = null;
    });
    if (_pressTime != null && _activeSectorIndex != null) {
      handleRelease(labels[_activeSectorIndex!]);
    }
  }

  void handleSectorTapCancel() {
    setState(() {
      _activeSectorIndex = null;
    });
  }

  void handlePress(String label) {
    final DateTime pressTime = DateTime.now();
    _pressTime = pressTime;
    _moveTimer?.cancel();
    print(label);
    Duration period = const Duration(milliseconds: 100);

    if (label == 'F') {
      sendCommand(0, speed);
      _moveTimer = Timer.periodic(period, (_) {
        sendCommand(0, speed);
      });
    } else if (label == 'B') {
      sendCommand(3.1415926 / 4, 0);
      _moveTimer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(pressTime).inMilliseconds;
        if (elapsed <= 4000) {
          sendCommand(3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'L') {
      sendCommand(3.1415926 / 4, 0);
      _moveTimer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(pressTime).inMilliseconds;
        if (elapsed <= 2000) {
          sendCommand(3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'R') {
      sendCommand(-3.1415926 / 4, 0);
      _moveTimer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(pressTime).inMilliseconds;
        if (elapsed <= 2000) {
          sendCommand(-3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'FL') {
      sendCommand(3.1415926 / 4, 0);
      _moveTimer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(pressTime).inMilliseconds;
        if (elapsed <= 1000) {
          sendCommand(3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'FR') {
      sendCommand(-3.1415926 / 4, 0);
      _moveTimer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(pressTime).inMilliseconds;
        if (elapsed <= 1000) {
          sendCommand(-3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'BL') {
      sendCommand(3.1415926 / 4, 0);
      _moveTimer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(pressTime).inMilliseconds;
        if (elapsed <= 3000) {
          sendCommand(3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'BR') {
      sendCommand(-3.1415926 / 4, 0);
      _moveTimer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(pressTime).inMilliseconds;
        if (elapsed <= 3000) {
          sendCommand(-3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    }
  }

  void handleRelease(String label) async {
    _moveTimer?.cancel();
    print("release");

    if (_lastAngular == 0 && _lastLinear.abs() > 0.01) {
      double currentLinear = _lastLinear;
      double step = currentLinear.abs() / 6;
      if (step < 0.01) step = 0.01;
      _decelTimer?.cancel();
      _decelTimer = Timer.periodic(
      const Duration(milliseconds: 30),
        (timer) {
        if (currentLinear.abs() <= 0.01) {
          sendCommand(0, 0);
          timer.cancel();
          _decelTimer = null;
        } else {
          if (currentLinear > 0) {
            currentLinear -= step;
            if (currentLinear < 0) currentLinear = 0;
          } else {
            currentLinear += step;
            if (currentLinear > 0) currentLinear = 0;
          }
          sendCommand(0, currentLinear);
        }
      });
    } else {
      await sendCommand(0, 0);
    }
    _pressTime = null;
  }


  void startMonitoring() {
  print("startMonitoring called, started=$_monitorStarted");
  if (_monitorStarted) return;
  _monitorStarted = true;
  print("Monitoring started");
  _monitorTimer = Timer.periodic(
    const Duration(seconds: 1),
    (_) async {
      final ip = widget.newIp;
      final statusUrl = Uri.parse(
        'http://$ip:9001/api/robot_status'
      );

      try {
        final response = await http.get(statusUrl);
        final data = jsonDecode(response.body);
        final status = data['results']['running_status'];
        final target = data['results']['move_target'];

        if (status == "running" && target.startsWith("charge")) {
          final cancelUrl = Uri.parse(
            "http://$ip:19001/api/tools/operation/task/cancel"
          );
          await http.post(cancelUrl);
          print("cancel sent (charging detected)");
        }
      } catch (_) {}
    },
  );
}


  void stopMonitoring() {
    _monitorTimer?.cancel();
  }



  @override
  void dispose() {
    _moveTimer?.cancel();
    _monitorTimer?.cancel();
    _decelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Colors.white;
    Color black = Colors.black;

    final orientation = MediaQuery.of(context).orientation;
    final bool isLandscape = orientation == Orientation.landscape;

    final double padScale = isLandscape ? 0.84 : 1.0;
    final double radioScale = isLandscape ? 1.05 : 1.0;
    final double speedTextFont = isLandscape ? 24 * 0.7 * 1.5 : 24;
    final double speedRadioFont = isLandscape ? 22 * 0.7 * 1.5 : 22;
    final double estopDescFont = isLandscape ? 20 * 0.7 * 1.5 : 20;

    final double sizedBox80 = isLandscape ? 80 * 0.5 * padScale : 80;
    final double sizedBoxBetween = isLandscape ? 28 * 0.5 : 28;
    final double sizedBox24 = isLandscape ? 24 * 0.5 : 24;

    //startMonitoring(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigate'),
        backgroundColor: background,
        foregroundColor: Colors.black87,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DirectionPad(
                color: black,
                onDirectionPressed: (dir) {handlePress(dir);},
                onCenterPressed: toggleEstop,
                onRelease: (dir) {handleRelease(dir);},
                estopActive: _estopActive,
                activeSectorIndex: _activeSectorIndex,
                scale: padScale,
                onDirectionTapDown: null,
                onDirectionTapUp: null,
              ),
              SizedBox(height: sizedBox80),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0 * padScale),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Speed:',
                        style: TextStyle(color: black, fontSize: speedTextFont),
                      ),
                      SizedBox(width: 20 * padScale),
                      _buildSpeedOption('slow', Speed.slow, black, speedRadioFont, radioScale),
                      SizedBox(width: 24 * padScale),
                      _buildSpeedOption('normal', Speed.normal, black, speedRadioFont, radioScale),
                      SizedBox(width: 24 * padScale),
                      _buildSpeedOption('fast', Speed.fast, black, speedRadioFont, radioScale),
                    ],
                  ),
                ),
              ),
              SizedBox(height: sizedBoxBetween),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0 * padScale),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '''ESTOP: Press to lock the robot - other direction buttons will be disabled and the background turns red. Press again to unlock.''',
                    style: TextStyle(
                      color: black,
                      fontSize: estopDescFont,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              SizedBox(height: sizedBox24),
              const Center(
                child: Text(
                  '0',
                  style: TextStyle(
                    color: Colors.transparent,
                    fontSize: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedOption(String label, Speed value, Color color, double fontSize, double radioScale) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontSize: fontSize),
        ),
        Transform.scale(
          scale: radioScale,
          child: Radio<Speed>(
            value: value,
            groupValue: _selectedSpeed,
            activeColor: color,
            onChanged: (Speed? v) {
              setState(() {
                _selectedSpeed = v!;
                if (_selectedSpeed == Speed.slow) {
                  speed = 0.4;
                } else if (_selectedSpeed == Speed.normal) {
                  speed = 0.7;
                } else if (_selectedSpeed == Speed.fast) {
                  speed = 1.0;
                }
              });
            },
          ),
        ),
      ],
    );
  }
}

class DirectionPad extends StatefulWidget {
  final void Function(String direction) onDirectionPressed;
  final VoidCallback onCenterPressed;
  final void Function(String direction) onRelease;
  final Color color;
  final bool estopActive;
  final int? activeSectorIndex;
  final double scale;
  final void Function(String label)? onDirectionTapDown;
  final void Function(String label)? onDirectionTapUp;

  DirectionPad({
    required this.onDirectionPressed,
    required this.onCenterPressed,
    required this.onRelease,
    required this.color,
    this.estopActive = false,
    this.activeSectorIndex,
    this.scale = 1.0,
    this.onDirectionTapDown,
    this.onDirectionTapUp,
  });

  @override
  State<DirectionPad> createState() => _DirectionPadState();
}

class _DirectionPadState extends State<DirectionPad> {
  int? _highlightIndex;

  final List<_DirectionLabel> _labels = const [
    _DirectionLabel('F', 0),
    _DirectionLabel('FR', 45),
    _DirectionLabel('R', 90),
    _DirectionLabel('BR', 135),
    _DirectionLabel('B', 180),
    _DirectionLabel('BL', 225),
    _DirectionLabel('L', 270),
    _DirectionLabel('FL', 315),
  ];

  void _handleTapDown(TapDownDetails details, double size, double innerCircle) {
    final Offset center = Offset(size / 2, size / 2);
    final Offset local = details.localPosition;
    final Offset delta = local - center;
    final double r = delta.distance;
    final double outerRadius = size / 2;
    final double innerRadius = innerCircle / 2;
    if (r < innerRadius || r > outerRadius) return;

    double angle = atan2(delta.dy, delta.dx) * 180 / pi;
    angle = angle < 0 ? angle + 360 : angle;
    angle = (angle + 90) % 360;
    int sector = ((angle + 22.5) ~/ 45) % 8;
    setState(() {
      _highlightIndex = (sector + 6) % 8;
    });
    widget.onDirectionPressed(_labels[sector].text);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _highlightIndex = null;
    });
    widget.onRelease(" ");
  }

  void _handleTapCancel() {
    setState(() {
      _highlightIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screen = MediaQuery.of(context).size.shortestSide;
    double size = screen * 0.7 * widget.scale;
    // ESTOP小圆半径变成原来的1.1倍
    double innerCircle = size * 0.36 * 1.1;
    double directionFontSize = size * 0.09;

    // ESTOP高亮色（字母高亮总是红色）
    const Color estopLetterHighlight = Colors.red;

    return GestureDetector(
      onTapDown: (details) => _handleTapDown(details, size, innerCircle),
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DirectionPadLinesPainter(
              color: widget.color,
              lineCount: 8,
              angleOffsetDegree: 22.5,
              highlightSector: _highlightIndex,
              highlightColor: const Color(0xFFFFA0A0).withOpacity(0.7),
              highlightOutlineColor: const Color(0xFFFFA0A0),
              innerCircle: innerCircle,
              highlightOffsetDegree: 89,
            ),
          ),
          ..._labels.asMap().entries.map((entry) {
            int i = entry.key;
            _DirectionLabel label = entry.value;
            double rad = label.angle * pi / 180;
            double r = size / 2 - (size * 0.12) - 12 * widget.scale;
            double cx = (size / 2) + r * sin(rad);
            double cy = (size / 2) - r * cos(rad);

            // 高亮字母为当前高亮扇形右转90度的字母
            int? highlightIndex = _highlightIndex;
            bool labelHighlighted = highlightIndex != null && (i == (highlightIndex + 2) % 8);

            return Positioned(
              left: cx - size * 0.12,
              top: cy - size * 0.12,
              child: Container(
                width: size * 0.24,
                height: size * 0.24,
                alignment: Alignment.center,
                child: Text(
                  label.text,
                  style: TextStyle(
                    color: labelHighlighted ? estopLetterHighlight : widget.color,
                    fontSize: directionFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: widget.onCenterPressed,
            child: Container(
              width: innerCircle,
              height: innerCircle,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.estopActive ? const Color(0xFFFFA0A0) : Colors.white,
                border: Border.all(
                  color: widget.estopActive ? Colors.red : widget.color,
                  width: 4 * widget.scale,
                ),
              ),
              child: Text(
                'ESTOP',
                style: TextStyle(
                  color: widget.estopActive ? estopLetterHighlight : widget.color,
                  fontSize: 44 * 0.8 * widget.scale * 1.1, // 放大1.1倍
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionPadLinesPainter extends CustomPainter {
  final Color color;
  final int lineCount;
  final double angleOffsetDegree;
  final int? highlightSector;
  final Color? highlightColor;
  final Color? highlightOutlineColor;
  final double? innerCircle;
  final double highlightOffsetDegree;

  _DirectionPadLinesPainter({
    required this.color,
    this.lineCount = 8,
    this.angleOffsetDegree = 0,
    this.highlightSector,
    this.highlightColor,
    this.highlightOutlineColor,
    this.innerCircle,
    this.highlightOffsetDegree = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;
    // ESTOP小圆半径是1.1倍
    final double estopR = (innerCircle != null ? innerCircle! / 2 : radius * 0.36);
    final double sectorInnerR = estopR;

    if (highlightSector != null && highlightColor != null) {
      final double startAngle = ((360 / lineCount) * highlightSector! + angleOffsetDegree - (360 / lineCount) / 2 - 111.5 + highlightOffsetDegree) * pi / 180;
      final double sweep = (360 / lineCount) * pi / 180;
      final Path sectorPath = Path()
        ..moveTo(center.dx + sectorInnerR * cos(startAngle), center.dy + sectorInnerR * sin(startAngle))
        ..arcTo(
          Rect.fromCircle(center: center, radius: sectorInnerR),
          startAngle,
          sweep,
          false,
        )
        ..lineTo(center.dx + radius * cos(startAngle + sweep), center.dy + radius * sin(startAngle + sweep))
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle + sweep,
          -sweep,
          false,
        )
        ..close();

      final Paint fillPaint = Paint()
        ..color = highlightColor!
        ..style = PaintingStyle.fill;
      canvas.drawPath(sectorPath, fillPaint);

      if (highlightOutlineColor != null) {
        final Paint outlinePaint = Paint()
          ..color = highlightOutlineColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: sectorInnerR),
          startAngle,
          sweep,
          false,
          outlinePaint,
        );
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweep,
          false,
          outlinePaint,
        );
        final Offset p1 = center + Offset(sectorInnerR * cos(startAngle), sectorInnerR * sin(startAngle));
        final Offset p2 = center + Offset(radius * cos(startAngle), radius * sin(startAngle));
        final Offset p3 = center + Offset(sectorInnerR * cos(startAngle + sweep), sectorInnerR * sin(startAngle + sweep));
        final Offset p4 = center + Offset(radius * cos(startAngle + sweep), radius * sin(startAngle + sweep));
        canvas.drawLine(p1, p2, outlinePaint);
        canvas.drawLine(p3, p4, outlinePaint);
      }
    }

    canvas.drawCircle(center, radius, paint);

    for (int i = 0; i < lineCount; i++) {
      double angle = (2 * pi / lineCount) * i + angleOffsetDegree * pi / 180;
      final Offset p2 = center + Offset(radius * sin(angle), -radius * cos(angle));
      canvas.drawLine(center, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DirectionPadLinesPainter oldDelegate) {
    return oldDelegate.highlightSector != highlightSector ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.highlightOutlineColor != highlightOutlineColor ||
        oldDelegate.highlightOffsetDegree != highlightOffsetDegree;
  }
}

class _DirectionLabel {
  final String text;
  final double angle;
  const _DirectionLabel(this.text, this.angle);
}