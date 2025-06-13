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

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final topHeight = constraints.maxHeight * 0.25;
        final buttonTextSize = constraints.maxHeight * 0.04;

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
                    _buildButton('Navigate', buttonTextSize),
                    _buildButton('Summon', buttonTextSize),
                    _buildButton('Settings', buttonTextSize),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Main Content Area',
                    style: TextStyle(fontSize: 20),
                  ),
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
          fontFamily: 'Georgia', //字体
        ),
      ),
    );
  }
}