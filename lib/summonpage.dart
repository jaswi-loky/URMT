import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class SummonPage extends StatefulWidget {
  final String? newIp;
  @override
  const SummonPage({Key? key, required this.newIp}) : super(key: key);
  State<SummonPage> createState() => _SummonPageState();
}

class _SummonPageState extends State<SummonPage> {
  String? selectedPoint; // 初始无选中
  String? selectedIp; // 初始无选中

  final List<String> ipList = [
    '', // 空选项
    '172.20.24.3-Ontario3F',
    '172.20.24.5-Ontario2F',
    '172.20.24.7-Ontario1F',
    '192.168.200.146-NY',
    '192.168.0.110-Monrovia'
    '192.168.10.10-Connect to Robot'
  ];

  void resetSelections() {
    setState(() {
      selectedIp = null;
      selectedPoint = null;
    });
  }

  final List<String> arrivePoints = [
    '', // 空选项
    'front_desk',
    'steakhouse',
    'coffee_station',
    'Kitchen',
  ];

  Future<void> _postApiCall({
    required BuildContext context, // FIX: Added 'required'
    required int port,
    required String path,
    String? successMessage,
    String? failureMessage,
  }) async {
    String? robotIpAddress = widget.newIp;
    final String apiUrl = 'http://$robotIpAddress:$port$path';
    print('Calling API: $apiUrl');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        print('Success for $path: ${response.body}');
        _showFeedback(context, successMessage ?? 'Operation successful!', Colors.green);
      } else {
        print('API Error for $path: Status ${response.statusCode}, Body: ${response.body}');
        _showFeedback(context, failureMessage ?? 'Operation failed: Error ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      print('Network Error for $path: $e');
      _showFeedback(context, 'Network Error: Could not connect to the robot.', Colors.red);
    }
  }
  
  void _showFeedback(BuildContext context, String message, Color color) { // FIX: Added comma
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    }
  }

  void _returnToCharging(BuildContext context) {
    _postApiCall(
      context: context,
      port: 19001,
      path: '/api/tools/operation/task/go-back',
      successMessage: 'Robot is returning to charge.',
      failureMessage: 'Failed to send return command.',
    );
  }

  void _attachChassis(BuildContext context, String? summon) async {
    const int port = 18080;
    const String path = '/api/v1/task/flow';
    String? robotIpAddress = widget.newIp;
    final String apiUrl = 'http://$robotIpAddress:$port$path';

    final String taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final String timestamp = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc());
    String scqSn = "";

    var url = Uri.parse('http://$robotIpAddress:9001/api/robot_status');

    try{
      var response1 = await http.get(url);
      var decodedData = jsonDecode(response1.body);
      int currentFloor = decodedData['results']['current_floor'];
      final response = await http.get(
          Uri.parse("http://$robotIpAddress:9001/api/markers/query_list?floor=$currentFloor"),
          headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        );
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      final Map<String, dynamic> results = decoded['results'];
      List<String> keys = results.keys.toList();
      for (String marker in keys){
        String firstSix = marker.length >= 6 ? marker.substring(0, 6) : marker;
        print(marker);
        if (firstSix =="charge"){
          Map<String, dynamic> properties =  jsonDecode(results[marker]['properties']);
          if(properties['charging_pile_type'] == 'up_charging_pile'){
            scqSn = properties['cabin_key'];
          }
        } 
      }

    }catch(e){
    }
    //const String scqSn = "SCQS00G0450101020";
    //const String scqSn = "SCQS00G13C0100349";
    //const String movePoint = "waiting";

    final Map<String, dynamic> optionDocking = {
      "optionId": "1001",
      "executionId": "docking_cabin",
      "params": {
        "cabinKey": scqSn,
        "attach": {
          "storeId": "202412209218662201730709785088",
          "taskId": [taskId],
        },
        "sweep": {
          "cabinType": "hcp",
          "hcp": 2,
        }
      }
    };

    final Map<String, dynamic> optionMove = {
      "optionId": "0002",
      "executionId": "move",
      "params": {
        "attach": {
          "storeId": "202412209218662201730709785088",
          "taskId": [taskId],
        },
        "marker": summon,
        "maxSpeedLinear": 1,
      }
    };

    final List<Map<String, dynamic>> executorsList = [optionDocking, optionMove];
    final String executorsJsonString = jsonEncode(executorsList);

    final Map<String, dynamic> requestData = {
      "cabinKey": scqSn,
      //"cabinKey": "SCQS00G13C0100349",
      "cabinDeviceType": 456,
      "taskType": 0,
      "clientToken": "41f04677025c4808a1df84138eb6e53e",
      "executors": executorsJsonString,
      "forceCancel": true,
      "taskId": taskId,
      "versionNumber": "1",
      "timestamp": timestamp,
    };

    print('Calling API: $apiUrl');
    print('--- FULL REQUEST BODY ---');
    print(jsonEncode(requestData));

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        print('Docking Task Created Successfully: ${response.body}');
        _showFeedback(context, 'Docking task created!', Colors.green);
      } else {
        print('API Error for docking task: Status ${response.statusCode}');
        _showFeedback(context, 'Failed to create docking task: Error ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      print('Network Error for docking task: $e');
      _showFeedback(context, 'Network Error: Could not connect to the robot.', Colors.red);
    }
  }

  void _cancelCleaning(BuildContext context) {
    _postApiCall(
      context: context,
      port: 19001,
      path: '/api/tools/operation/task/cancel',
      successMessage: 'Cleaning Canceled Successfully!',
      failureMessage: 'Failed to cancel cleaning.',
    );
  }




  @override
  Widget build(BuildContext context) {
    final Color commonWhite = Colors.white;
    String? newIp = widget.newIp; 

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
                            print("changed");
                        
                            selectedPoint = newValue;
                            //String apiUrl = "http://$newIp:9001/api/move?marker=$selectedPoint";
                            //print(apiUrl);
                            /*try {
                            // Using http.get as specified in the documentation
                            //final response = http.post(
                            //Uri.parse(apiUrl),
                            //);
                            _attachChassis(context, selectedPoint);
                            }catch(e){
                              print("fail");
                            }*/
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 59, 52, 85),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              ),
                            onPressed: () {
                              if (selectedPoint != null && selectedPoint!.isNotEmpty) {
                                try {
                                  _attachChassis(context, selectedPoint);
                                  print("Sent to $selectedPoint using IP $newIp");
                                } catch (e) {
                                  print("Failed: $e");
                                }
                              } else {
                                print("No destination selected");
                              }
                              },
                            child: const Text(
                            'Send',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Georgia',
                              color: Colors.white,
                            ),
                          ),
                        ),
            const SizedBox(height: 40),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 93, 59, 215),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              ),
                            onPressed: () {
                              if (selectedPoint != null && selectedPoint!.isNotEmpty) {
                                try {
                                  _returnToCharging(context);
                                  print("Return to Charging pile");
                                } catch (e) {
                                  print("Failed: $e");
                                }
                              } else {
                                print("No destination selected");
                              }
                              },
                            child: const Text(
                            'Return to Charging',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Georgia',
                              color: Colors.white,
                            ),
                          ),
                        ),
                const SizedBox(height: 40),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 151, 14, 14),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              ),
                            onPressed: () {
                              if (selectedPoint != null && selectedPoint!.isNotEmpty) {
                                try {
                                  _cancelCleaning(context);
                                  print("Cancel task");
                                } catch (e) {
                                  print("Failed: $e");
                                }
                              } else {
                                print("No destination selected");
                              }
                              },
                            child: const Text(
                            'Cancel Task',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Georgia',
                              color: Colors.white,
                            ),
                          ),
                        ),
          ],
        ),
      ),
    );
  }
}