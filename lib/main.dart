import 'package:flutter/material.dart';
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
  String? selectedIp; // 初始无选中
  String? selectedPoint; // Summon页选择的点

  final List<String> ipList = [
    '', // 空选项
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

  // 用于从SummonPage返回后重置
  Future<void> _goToSummonPage(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SummonPage(
          selectedIp: selectedIp,
          onSelectPoint: (point, didSend) async {
            selectedPoint = point;
            // 如果两个都选了非空，发指令
            if (selectedIp != null &&
                selectedIp!.isNotEmpty &&
                point != null &&
                point.isNotEmpty) {
              final url =
                  'http://${selectedIp!}:9001/api/move?marker=$point';
              try {
                await http.get(Uri.parse(url));
              } catch (_) {}
              // 发完指令后停留在Summon页，不做返回
              didSend();
            }
          },
        ),
      ),
    );
    // 返回首页后，重置所有选择
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
              // 顶部蓝色按钮栏
              Container(
                height: topHeight,
                width: double.infinity,
                color: const Color.fromARGB(255, 93, 59, 215),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton('Navigate', actualButtonTextSize, context),
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
              // 空白行
              Container(
                height: 32,
                width: double.infinity,
                color: commonWhite,
              ),
              // IP address 行
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
              // 空白画布区域
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
      onPressed: label == 'Summon'
          ? (onPressed ??
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SummonPage(),
                  ),
                );
              })
          : null,
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
  String? selectedPoint; // 初始无选中
  final List<String> arrivePoints = [
    '', // 空选项
    'arrive_point_1',
    'arrive_point_2',
    'arrive_point_3',
    'arrive_point_4',
    'arrive_point_5',
  ];

  bool _sending = false;

  // 指令发完后停留本页
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
        // 返回主界面时，重置所有选择
        Navigator.of(context).pop('reset');
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