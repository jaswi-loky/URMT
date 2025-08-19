import 'package:flutter/material.dart';

import 'functionspage.dart';
import 'summonpage.dart';


import 'update.dart'; 


import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());



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

    '', // 空选项
    '172.20.24.2',
    '172.20.24.3',
    '172.20.24.5',
    '192.168.10.10'

  ];
  final UpdateService _updateService = UpdateService();
  @override
  void initState() {
    
    super.initState();
   
    Future.delayed(Duration(seconds: 2), () {
     
      if (mounted) { // Ensure widget is still in the tree
        
        _updateService.checkForUpdate(context);
      }
    });
  }

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

  void _goToNavigatePage(BuildContext context) {
    if (selectedIp == null || selectedIp!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please first select the IP Address')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NavigatePage(selectedIp: selectedIp!),
      ),
    );
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
            isPortrait ? buttonTextSize * 0.65 : buttonTextSize;

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

                    _buildButton('Navigate', actualButtonTextSize, context),
                    _buildButton('Summon', actualButtonTextSize, context),
                    _buildButton('Functions', actualButtonTextSize, context),
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


      


  
     
 