import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class FunctionsPage extends StatefulWidget {
  @override
  _FunctionsPageState createState() => _FunctionsPageState();
}
class _FunctionsPageState extends State<FunctionsPage> {

  bool _showSetLocationSection = false;
  String? _selectedMap = 'map_1';
  final List<String> _mapOptions = ['map_1', 'map_2', 'map_3', 'map_4','map_5'];

  final String _robotIpAddress = '10.1.17.101';
  final Uuid _uuid = Uuid();

  // --- 1. Reusable API Helper Function ---
  /// Makes a generic POST request to the robot.
  ///
  /// Takes [port] and [path] to build the URL dynamically.
  /// Also takes optional messages for user feedback.
  Future<void> _postApiCall({
    required BuildContext context, // FIX: Added 'required'
    required int port,
    required String path,
    String? successMessage,
    String? failureMessage,
  }) async {
    final String apiUrl = 'http://$_robotIpAddress:$port$path';
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

    void _switchChassisPosition(BuildContext context, String marker) async {
    const int port = 9001;
    final String path = '/api/position_adjust?marker=$marker';
    final String apiUrl = 'http://$_robotIpAddress:$port$path';


    try {
      // Using http.get as specified in the documentation
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        print('Success for position adjust: ${response.body}');
        _showFeedback(context, 'Position switched to $marker successfully!', Colors.green);
      } else {
        print('API Error for position adjust: Status ${response.statusCode}, Body: ${response.body}');
        _showFeedback(context, 'Failed to switch position: Error ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      print('Network Error for position adjust: $e');
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

  void _attachChassis(BuildContext context) async {
    const int port = 18080;
    const String path = '/api/v1/task/flow';
    final String apiUrl = 'http://$_robotIpAddress:$port$path';

    final String taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final String timestamp = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc());

    const String scqSn = "SCQS00G13C0100349";
    const String movePoint = "waiting";

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
        "marker": movePoint,
        "maxSpeedLinear": 1,
      }
    };

    final List<Map<String, dynamic>> executorsList = [optionDocking, optionMove];
    final String executorsJsonString = jsonEncode(executorsList);

    final Map<String, dynamic> requestData = {
      "cabinKey": "SCQS00S039YF00153",
      "cabinDeviceType": 456,
      "taskType": 0,
      "clientToken": "41f04677025c4808a1df84138eb6e53e",
      "executors": executorsJsonString,
      "forceCancel": false,
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

  // FIX: Added 'async' and corrected hardness parameter usage
  void _startCarpetVacuuming(BuildContext context, String hardness) async {
    const int port = 18080;
    const String path = '/api/v1/task/flow';
    final String apiUrl = 'http://$_robotIpAddress:$port$path';

    final String taskId = _uuid.v4();
    final String clientToken = _uuid.v4().replaceAll('-', '');
    final String timestamp = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc());

    final Map<String, dynamic> sweepZone1 = {
      "coordinates": [
        {"x": "5.29", "y": "4.07"},
        {"x": "5.39", "y": "-3.03"},
        {"x": "11.05", "y": "-2.95"},
        {"x": "10.95", "y": "4.19"},
      ],
      "creator": "{wt_sn}",
      "dirtyImgUrls": [],
      "floor": 7,
      "id": "20240514040328107630247857670629",
      "label": "",
      "level": 0,
      "material": "marble",
      "probability": "",
      "zoneName": "{zone}",
      "zoneType": "SWEEP",
    };

    final Map<String, dynamic> executorObject = {
      "optionId": "1002",
      "executionId": "sweep",
      "params": {
        "cabinKey": "SCQS00S039YF00153",
        "attach": {
          "storeId": "202412209218662201730709785088",
          "taskId": ["{taskId}"],
        },
        "hcp": 2,
        "hardness": hardness, // FIX: Changed 'L' to use the 'hardness' parameter
        "zones": [sweepZone1],
      }
    };

    final String executorsJsonString = jsonEncode([executorObject]); // FIX: executorObject should be in a list

    final Map<String, dynamic> requestData = {
      "cabinKey": "SCQS00S039YF00153",
      "cabinDeviceType": 456,
      "taskType": 0,
      "clientToken": clientToken,
      "executors": executorsJsonString,
      "forceCancel": false,
      "taskId": taskId,
      "versionNumber": "1",
      "timestamp": timestamp,
    };

    print('Calling API: $apiUrl');
    print('Request Body: ${jsonEncode(requestData)}');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        print('Task Flow Started Successfully: ${response.body}');
        _showFeedback(context, 'Task flow started!', Colors.green);
      } else {
        print('API Error for task flow: Status ${response.statusCode}');
        _showFeedback(context, 'Failed to start task flow: Error ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      print('Network Error for task flow: $e');
      _showFeedback(context, 'Network Error: Could not connect to the robot.', Colors.red);
    }
  }

  // FIX: Added BuildContext parameter
  void _startFloorSweeping(BuildContext context) {
    _startCarpetVacuuming(context, "M"); // FIX: Added semicolon
  }

  // FIX: Added BuildContext parameter
  void _startMarbleMopping(BuildContext context) {
    _startCarpetVacuuming(context, "S"); // FIX: Added semicolon
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

  void _returnToCharging(BuildContext context) {
    _postApiCall(
      context: context,
      port: 19001,
      path: '/api/tools/operation/task/go-back',
      successMessage: 'Robot is returning to charge.',
      failureMessage: 'Failed to send return command.',
    );
  }

  void _automaticLifting(BuildContext context) {
    _postApiCall(
      context: context,
      port: 19001,
      path: '/api/tools/operation/lift/up',
      successMessage: 'Robot lifts successfully',
      failureMessage: 'Failed to lift the robot',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Robot Control',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color.fromARGB(255, 93, 59, 215),
          iconTheme: IconThemeData(color: Colors.white),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Robot behavior'),
              Tab(text: 'Select location'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: [
                    // FIX: Corrected all onPressed handlers
                    _buildActionButton(
                      text: 'Attach Chassis to Cleaning Module',
                      onPressed: () => _attachChassis(context),
                    ),
                    _buildActionButton(
                      text: 'Start Carpet Vacuuming',
                      emoji: '👾🧹',
                      onPressed: () => _startCarpetVacuuming(context, "H"),
                    ),
                    _buildActionButton(
                      text: 'Start floor Sweeping',
                      emoji: '👾🧹',
                      onPressed: () => _startFloorSweeping(context),
                    ),
                    _buildActionButton(
                      text: 'Marble wet mopping',
                      emoji: '😳🧹',
                      onPressed: () => _startMarbleMopping(context),
                    ),
                    _buildActionButton(
                      text: 'Cancel Cleaning',
                      onPressed: () => _cancelCleaning(context),
                    ),
                    _buildActionButton(
                      text: 'Return to Charging',
                      onPressed: () => _returnToCharging(context),
                    ),
                    _buildActionButton(
                      text: 'Automatic lifting',
                      emoji: '🎃',
                      onPressed: () => _automaticLifting(context),
                    ),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      elevation: 4.0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select the location you want to switch to:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _showSetLocationSection = true;
                                    });
                                    print('Select button pressed');
                                  },
                                  child: Text(
                                    'Select',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF4A75E4),
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // --- CONDITIONALLY VISIBLE SECTION ---
                    if (_showSetLocationSection)
                      Card(
                        margin: const EdgeInsets.only(top: 16.0),
                        elevation: 4.0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Set current location:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedMap,
                                items: _mapOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedMap = newValue;
                                  });
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      // Handle Submit Logic
                                      if (_selectedMap != null) {
                                        print('Submitted marker: $_selectedMap');
                                        _switchChassisPosition(context, _selectedMap!);
                                      } else {
                                        _showFeedback(context, 'Please select a location.', Colors.orange);
                                      }
                                    },
                                    child: Text('Submit'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF4285F4), // Blue color
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Handle Reset Logic
                                      setState(() {
                                        _selectedMap = 'map_1'; // Reset to initial value
                                      });
                                    },
                                    child: Text('Reset'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFFBBC05), // Yellow color
                                      foregroundColor: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    String? emoji,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(
              emoji,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
          ],
          Text(text),
        ],
      ),
    );
  }
}

  // FIX: Added 'Widget' return type
  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    String? emoji,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(
              emoji,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
          ],
          Text(text),
        ],
      ),
    );
  }
