import 'package:flutter/material.dart';
import 'functionspage.dart';
import 'summonpage.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URMT',
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedIp; // 初始无选中
  final List<String> ipList = [
    '', // 空选项
    '172.20.24.2',
    '172.20.24.3',
    '172.20.24.5',
    '192.168.10.10'
  ];

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
            isPortrait ? buttonTextSize * 0.65 : buttonTextSize;

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
                    _buildButton('Summon', actualButtonTextSize, context),
                    _buildButton('Functions', actualButtonTextSize, context),
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
                padding: EdgeInsets.symmetric(horizontal: 28.8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'IP address:',
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Georgia',
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 19.2),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.4, vertical: 9.6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 0.4),
                        borderRadius: BorderRadius.circular(4.8),
                        color: commonWhite,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedIp,
                          hint: Text(''),
                          icon: Icon(Icons.arrow_drop_down, size: 28.8),
                          style: TextStyle(
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
                                style: TextStyle(
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

  Widget _buildButton(String label, double fontSize, BuildContext context) {
    VoidCallback? onPressed;
    switch (label) {
      case 'Summon':
        onPressed = () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SummonPage(newIp: selectedIp)),
          );
        };
        break;
      case 'Functions':
        onPressed = () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => FunctionsPage(newIp: selectedIp)),
          );
        };
        break;
      default:
        onPressed = null;
    }
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

