import 'package:flutter/material.dart';

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
  String selectedIp = '10.1.16.118';

  final List<String> ipList = [
    '10.1.16.118',
    '10.1.17.101',
    '10.1.17.240',
  ];

  @override
  Widget build(BuildContext context) {
    final Color commonWhite = Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final topHeight = constraints.maxHeight * 0.25;
        final buttonTextSize = constraints.maxHeight * 0.04;

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
                    _buildButton('Navigate', buttonTextSize),
                    _buildButton('Summon', buttonTextSize),
                    _buildButton('Settings', buttonTextSize),
                  ],
                ),
              ),
              // 空白行，保证和下方画布白色一致
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
                padding: EdgeInsets.symmetric(horizontal: 28.8), // 36.0 * 0.8
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
                    SizedBox(width: 19.2), // 24 * 0.8
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.4, vertical: 9.6), // 18.0*0.8, 12.0*0.8
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 0.5 * 0.8), // 更细
                        borderRadius: BorderRadius.circular(4.8), // 6.0 * 0.8
                        color: commonWhite,
                      ),
                      child: DropdownButton<String>(
                        value: selectedIp,
                        underline: SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, size: 28.8), // 36 * 0.8
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 24,
                          color: Colors.black87,
                        ),
                        itemHeight: 57.6, // 72 * 0.8
                        items: ipList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
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
                            selectedIp = newValue!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // 下面的空白画布区域
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: commonWhite,
                  // 空白，无任何内容
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButton(String label, double fontSize) {
    return TextButton(
      onPressed: () {},
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