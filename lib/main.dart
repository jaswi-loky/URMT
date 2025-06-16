import 'package:flutter/material.dart';
import 'update.dart'; 
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
    '10.1.16.118',
    '10.1.17.101',
    '10.1.17.240',
  ];
  final UpdateService _updateService = UpdateService();
  @override
  void initState() {
    super.initState();
    // Check for updates when the app starts (optional)
    // Add a delay if you don't want it immediately on startup
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) { // Ensure widget is still in the tree
         _updateService.checkForUpdate(context);
      }
    });
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
                    _buildButton('Summon', actualButtonTextSize, context),
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
    return TextButton(
      onPressed: label == 'Summon'
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SummonPage(),
                ),
              );
            }
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

  @override
  Widget build(BuildContext context) {
    final Color commonWhite = Colors.white;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 93, 59, 215),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        color: commonWhite,
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 28.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 48),
            Container(
              height: 96,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Send the robot to:',
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
                        value: selectedPoint,
                        hint: Text(''),
                        icon: Icon(Icons.arrow_drop_down, size: 28.8),
                        style: TextStyle(
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
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 24,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedPoint = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}