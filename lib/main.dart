import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URMT',
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedIp;
  String? selectedPoint;

  final List<String> ipList = [
    '',
    '10.1.16.118',
    '10.1.17.101',
    '10.1.17.240',
  ];

  void resetSelections() {
    setState(() {
      selectedIp = null;
      selectedPoint = null;
    });
  }

  void resetPointOnly() {
    setState(() {
      selectedPoint = null;
    });
  }

  Future<void> _goToSummonPage(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SummonPage(
          selectedIp: selectedIp,
          onSelectPoint: (point, didSend) async {
            selectedPoint = point;
            if (selectedIp != null &&
                selectedIp!.isNotEmpty &&
                point != null &&
                point.isNotEmpty) {
              final url =
                  'http://${selectedIp!}:9001/api/move?marker=$point';
              try {
                await http.get(Uri.parse(url));
              } catch (_) {}
              didSend();
            }
          },
        ),
      ),
    );
    if (result == 'reset_point') {
      resetPointOnly();
    }
    if (result == 'reset') {
      resetSelections();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color commonWhite = Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPortrait =
            MediaQuery.of(context).orientation == Orientation.portrait;
        final topHeight = constraints.maxHeight * 0.25;
        final buttonTextSize = constraints.maxHeight * 0.04;
        final actualButtonTextSize =
            isPortrait ? buttonTextSize * 0.8 : buttonTextSize;

        return Scaffold(
          body: Column(
            children: [
              Container(
                height: topHeight,
                width: double.infinity,
                color: const Color.fromARGB(255, 93, 59, 215),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton('Navigate', actualButtonTextSize, context,
                        onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NavigatePage(),
                        ),
                      );
                    }),
                    _buildButton(
                      'Summon',
                      actualButtonTextSize,
                      context,
                      onPressed: () => _goToSummonPage(context),
                    ),
                    _buildButton('Settings', actualButtonTextSize, context),
                  ],
                ),
              ),
              Container(
                height: 32,
                width: double.infinity,
                color: commonWhite,
              ),
              Container(
                height: 96,
                width: double.infinity,
                color: commonWhite,
                padding: const EdgeInsets.symmetric(horizontal: 28.8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'IP address:',
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Georgia',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 19.2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.4, vertical: 9.6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 0.4),
                        borderRadius: BorderRadius.circular(4.8),
                        color: commonWhite,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedIp,
                          hint: const Text(''),
                          icon: const Icon(Icons.arrow_drop_down, size: 28.8),
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 24,
                            color: Colors.black87,
                          ),
                          itemHeight: 57.6,
                          items: ipList.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value.isEmpty ? null : value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 24,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedIp = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: commonWhite,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButton(String label, double fontSize, BuildContext context,
      {VoidCallback? onPressed}) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontFamily: 'Georgia',
        ),
      ),
    );
  }
}

class SummonPage extends StatefulWidget {
  final String? selectedIp;
  final Future<void> Function(String? point, void Function() didSend)? onSelectPoint;

  const SummonPage({Key? key, this.selectedIp, this.onSelectPoint}) : super(key: key);

  @override
  State<SummonPage> createState() => _SummonPageState();
}

class _SummonPageState extends State<SummonPage> {
  String? selectedPoint;
  final List<String> arrivePoints = [
    '',
    'arrive_point_1',
    'arrive_point_2',
    'arrive_point_3',
    'arrive_point_4',
    'arrive_point_5',
  ];

  bool _sending = false;

  void _afterSend() {
    if (!mounted) return;
    setState(() {
      _sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color commonWhite = Colors.white;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop('reset_point');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 93, 59, 215),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          automaticallyImplyLeading: true,
        ),
        body: Container(
          color: commonWhite,
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Container(
                height: 96,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Send the robot to:',
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Georgia',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 19.2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.4, vertical: 9.6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 0.4),
                        borderRadius: BorderRadius.circular(4.8),
                        color: commonWhite,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPoint,
                          hint: const Text(''),
                          icon: const Icon(Icons.arrow_drop_down, size: 28.8),
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 24,
                            color: Colors.black87,
                          ),
                          itemHeight: 57.6,
                          items: arrivePoints.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value.isEmpty ? null : value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 24,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) async {
                            setState(() {
                              selectedPoint = newValue;
                              _sending = true;
                            });
                            if (widget.onSelectPoint != null) {
                              await widget.onSelectPoint!(
                                selectedPoint,
                                _afterSend,
                              );
                            } else {
                              if (mounted) {
                                setState(() {
                                  _sending = false;
                                });
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_sending) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

// =================== Navigate 页面 =====================
enum Speed { slow, normal, fast }

class NavigatePage extends StatefulWidget {
  const NavigatePage({super.key});

  @override
  State<NavigatePage> createState() => _NavigatePageState();
}

class _NavigatePageState extends State<NavigatePage> {
  Speed _selectedSpeed = Speed.normal;
  double speed = 0.7;
  Timer? _timer;
  DateTime? _pressTime;

  final Map<String, bool> _buttonPressed = {
    'F': false, 'B': false, 'L': false, 'R': false,
    'FL': false, 'FR': false, 'BL': false, 'BR': false,
  };

  double _lastLinear = 0;
  double _lastAngular = 0;
  bool _estopActive = false;

  static const String baseUrl = 'http://192.168.10.10:9001/api/joy_control';

  Future<void> sendCommand(double angular, double linear) async {
    _lastAngular = angular;
    _lastLinear = linear;
    final url = Uri.parse(
        '$baseUrl?angular_velocity=$angular&linear_velocity=$linear');
    try {
      await http.get(url);
    } catch (e) {}
  }

  Future<void> toggleEstop() async {
    setState(() {
      _estopActive = !_estopActive;
    });
    final flag = _estopActive ? 'true' : 'false';
    final url = Uri.parse('http://192.168.10.10:9001/api/estop?flag=$flag');
    try {
      await http.get(url);
    } catch (e) {}
  }

  void handlePress(String label) {
    setState(() {
      _buttonPressed[label] = true;
    });
    _pressTime = DateTime.now();
    _timer?.cancel();

    Duration period = const Duration(milliseconds: 100);

    if (label == 'F') {
      sendCommand(0, speed);
      _timer = Timer.periodic(period, (_) {
        sendCommand(0, speed);
      });
    } else if (label == 'B') {
      sendCommand(3.1415926 / 4, 0);
      _timer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(_pressTime!).inMilliseconds;
        if (elapsed <= 4000) {
          sendCommand(3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'L') {
      sendCommand(3.1415926 / 4, 0);
      _timer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(_pressTime!).inMilliseconds;
        if (elapsed <= 2000) {
          sendCommand(3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'R') {
      sendCommand(-3.1415926 / 4, 0);
      _timer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(_pressTime!).inMilliseconds;
        if (elapsed <= 2000) {
          sendCommand(-3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'FL') {
      sendCommand(3.1415926 / 4, 0);
      _timer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(_pressTime!).inMilliseconds;
        if (elapsed <= 1000) {
          sendCommand(3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'FR') {
      sendCommand(-3.1415926 / 4, 0);
      _timer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(_pressTime!).inMilliseconds;
        if (elapsed <= 1000) {
          sendCommand(-3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'BL') {
      sendCommand(3.1415926 / 4, 0);
      _timer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(_pressTime!).inMilliseconds;
        if (elapsed <= 3000) {
          sendCommand(3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'BR') {
      sendCommand(-3.1415926 / 4, 0);
      _timer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(_pressTime!).inMilliseconds;
        if (elapsed <= 3000) {
          sendCommand(-3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    }
  }

  void handleRelease(String label) async {
    setState(() {
      _buttonPressed[label] = false;
    });
    _timer?.cancel();

    if (_lastAngular == 0 && _lastLinear.abs() > 0.01) {
      double currentLinear = _lastLinear;
      double step = currentLinear.abs() / 10;
      if (step < 0.01) step = 0.01;
      Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (currentLinear.abs() <= 0.01) {
          sendCommand(0, 0);
          timer.cancel();
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Colors.white;
    Color black = Colors.black;

    final orientation = MediaQuery.of(context).orientation;
    final bool isLandscape = orientation == Orientation.landscape;

    // 横屏时大圆等为0.7*1.2=0.84倍，Speed-radio为0.7*1.5=1.05倍
    final double padScale = isLandscape ? 0.84 : 1.0;
    final double radioScale = isLandscape ? 1.05 : 1.0;

    // Speed和ESTOP相关字体横屏额外1.5倍
    final double speedTextFont = isLandscape ? 24 * 0.7 * 1.5 : 24;
    final double speedRadioFont = isLandscape ? 22 * 0.7 * 1.5 : 22;
    final double estopDescFont = isLandscape ? 20 * 0.7 * 1.5 : 20;

    // 大圆和Speed那行间距：先缩短横屏一半，再缩放padScale
    final double sizedBox80 = isLandscape ? 80 * 0.5 * padScale : 80;
    // 两行间距横屏缩短一半
    final double sizedBoxBetween = isLandscape ? 28 * 0.5 : 28;
    final double sizedBox24 = isLandscape ? 24 * 0.5 : 24;

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
                onDirectionPressed: (dir) {},
                onCenterPressed: toggleEstop,
                color: black,
                onDirectionTapDown: handlePress,
                onDirectionTapUp: handleRelease,
                estopActive: _estopActive,
                buttonPressed: _buttonPressed,
                scale: padScale,
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
                        'Speed：',
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

class DirectionPad extends StatelessWidget {
  final void Function(String direction) onDirectionPressed;
  final VoidCallback onCenterPressed;
  final Color color;
  final void Function(String label)? onDirectionTapDown;
  final void Function(String label)? onDirectionTapUp;
  final bool estopActive;
  final Map<String, bool> buttonPressed;
  final double scale;

  DirectionPad({
    required this.onDirectionPressed,
    required this.onCenterPressed,
    required this.color,
    this.onDirectionTapDown,
    this.onDirectionTapUp,
    this.estopActive = false,
    required this.buttonPressed,
    this.scale = 1.0,
  });

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

  @override
  Widget build(BuildContext context) {
    double screen = MediaQuery.of(context).size.shortestSide;
    double size = screen * 0.7 * scale;
    double innerCircle = size * 0.36;
    double directionFontSize = size * 0.09;
    Color pressedColor = Colors.red;
    Color pressedBg = const Color(0xFFFFA0A0);
    double highlightRadius = size * 0.12;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
          ),
          ..._labels.map((label) {
            double rad = label.angle * pi / 180;
            double r = size / 2 - highlightRadius - 12 * scale;
            double cx = (size / 2) + r * sin(rad);
            double cy = (size / 2) - r * cos(rad);
            bool isPressed = buttonPressed[label.text] ?? false;

            return Positioned(
              left: cx - highlightRadius,
              top: cy - highlightRadius,
              child: GestureDetector(
                onTap: () => onDirectionPressed(label.text),
                onTapDown: onDirectionTapDown != null
                    ? (_) => onDirectionTapDown!(label.text)
                    : null,
                onTapUp: onDirectionTapUp != null
                    ? (_) => onDirectionTapUp!(label.text)
                    : null,
                onTapCancel: onDirectionTapUp != null
                    ? () => onDirectionTapUp!(label.text)
                    : null,
                child: Container(
                  width: highlightRadius * 2,
                  height: highlightRadius * 2,
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isPressed)
                        Container(
                          width: highlightRadius * 2,
                          height: highlightRadius * 2,
                          decoration: BoxDecoration(
                            color: pressedBg,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        label.text,
                        style: TextStyle(
                          color: isPressed ? pressedColor : color,
                          fontSize: directionFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: onCenterPressed,
            child: Container(
              width: innerCircle,
              height: innerCircle,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: estopActive ? pressedBg : Colors.white,
                border: Border.all(
                  color: estopActive ? Colors.red : color,
                  width: 4 * scale,
                ),
              ),
              child: Text(
                'ESTOP',
                style: TextStyle(
                  color: estopActive ? Colors.red : color,
                  fontSize: 44 * 0.8 * scale,
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

class _DirectionLabel {
  final String text;
  final double angle;

  const _DirectionLabel(this.text, this.angle);
}