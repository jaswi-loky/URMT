import 'package:flutter/material.dart';
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