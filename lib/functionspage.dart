import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'checkbox.dart';
import 'package:crypto/crypto.dart';

class FunctionsPage extends StatefulWidget {
  final String? newIp;
  @override
  const FunctionsPage({Key? key, required this.newIp}) : super(key: key);
  _FunctionsPageState createState() => _FunctionsPageState();
}
class _FunctionsPageState extends State<FunctionsPage> {

  bool _showSetLocationSection = false;
  String? _selectedMap = 'map_1';
  final List<String> _mapOptions = [];
  
  final Uuid _uuid = Uuid();
  final String currentFloor = "1";
  String upper = "";

  @override
  void initState() {
    super.initState();
    _findPoints();
  }

  List<String> _selectedZones = [];

Widget buildZoneSelectorButton() {
    String? robotIpAddress = widget.newIp;
  return ElevatedButton.icon(
    icon: const Icon(Icons.layers),
    label: const Text('Select Zones'),
    onPressed: () async {
      var zoneurl = Uri.parse('http://$robotIpAddress:18080/api/marker/area/list');
      try {
        // ① 从 URL 获取 zone 列表
        final zones = await simplezone(zoneurl);
        debugPrint('zones from api: $zones');

        // ② 按楼层分组
        final grouped = groupByFloor(zones);
        debugPrint('grouped zones: $grouped');

        // ③ 弹出选择窗口
        final result = await showDialog<List<String>>(
          context: context,
          builder: (_) => ZoneSelectorDialog(
            groupedZones: grouped,
            initialSelected: _selectedZones,
          ),
        );

        // ④ 接收用户选择
        if (result != null) {
          setState(() {
            _selectedZones = result;
          });
          debugPrint('selected zones: $_selectedZones');
        }
      } catch (e) {
        debugPrint('zone load failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load zones')),
        );
      }
    },
  );
}


  Future<void> _findPoints() async{
     String? robotIpAddress = widget.newIp;
     print(robotIpAddress);
     try{
      final response = await http.get(Uri.parse("http://$robotIpAddress:9001/api/markers/query_list"));
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      final Map<String, dynamic> results = decoded['results'];
      List<String> keys = results.keys.toList();
      for (String marker in keys){
        String firstFour = marker.length >= 4 ? marker.substring(0, 4) : marker;
        if (firstFour =="map_"){
          _mapOptions.add(marker);
        } 
      }
    }catch(e){
    }

}
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

  void startPolling() {
  String? robotIpAddress = widget.newIp;
  String url = "http://$robotIpAddress:9001/api/robot_status"; // fixed IP
  var url10 = Uri.parse('http://$robotIpAddress:9001/api/robot_status');
  Timer? timer;
  DateTime? idleStartTime;

   timer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
    try {
      var response1 = await http.get(url10);
      var decodedData = jsonDecode(response1.body);
      int currentFloor = decodedData['results']['current_floor'];
       var url11 = Uri.parse('http://$robotIpAddress:9001/api/move?marker=map_$currentFloor');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final body = response.body.trim();

        if (body.contains("idle")) {
          // start counting idle duration
          idleStartTime ??= DateTime.now();

          final elapsed = DateTime.now().difference(idleStartTime!).inSeconds;

          // ✅ check that it is STILL idle after 30 seconds
          if (elapsed >= 30) {
            print("Idle for 30 continuous seconds, stopping polling.");
            if (currentFloor == 1){
              print("returning");
            _returnToCharging(context);
            }
            else{
              http.post(url11);
            }
            timer?.cancel();
          }
        } else {
          // reset timer if response is not idle anymore
          idleStartTime = null;
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Request failed: $e");
    }
  });
}
void startPollingSafe(BuildContext context) {
  String? robotIpAddress = widget.newIp;
  String url = "http://$robotIpAddress:9001/api/robot_status";
  DateTime? idleStartTime;

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final body = response.body.trim();
        int currentFloor = jsonDecode(body)['results']['current_floor'];

        if (body.contains("idle")) {
          idleStartTime ??= DateTime.now();
          final elapsed = DateTime.now().difference(idleStartTime!).inSeconds;
          if (elapsed >= 90) {
            print("Idle for 90s, stopping polling.");
            if (mounted && currentFloor == 1) _returnToCharging(context);
            timer.cancel();
          }
        } else {
          idleStartTime = null;
        }
      }
    } catch (e) {
      print("Polling error: $e");
    }
  });
}

    void _switchChassisPosition(BuildContext context, String marker) async {
    const int port = 9001;
    String? robotIpAddress = widget.newIp;
    final String path = '/api/position_adjust?marker=$marker';
    final String apiUrl = 'http://$robotIpAddress:$port$path';
    //final String currentFloor;

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
    String? robotIpAddress = widget.newIp;
    final String apiUrl = 'http://$robotIpAddress:$port$path';

    final String taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final String timestamp = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc());
    String scqSn = "";
    startPollingSafe(context);

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
        if (firstSix =="charge"){
          Map<String, dynamic> properties =  jsonDecode(results[marker]['properties']);
          if(properties['charging_pile_type'] == 'sweep_charging_pile'){
            scqSn = properties['cabin_key'];
          }
        } 
      }

    }catch(e){
    }
    //const String scqSn = "SCQS00G0450101020";
    //const String scqSn = "SCQS00G13C0100349";
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
      "cabinKey": scqSn,
      //"cabinKey": "SCQS00G13C0100349",
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
    upper = scqSn;
  }

void _attachNewChassis(BuildContext context) async{
  _returnToCharging(context);
  String? robotIpAddress = widget.newIp;
  var upUrl = Uri.parse('http://$robotIpAddress:19001/api/tools/operation/lift/up');
  try{
    http.get(upUrl);
    print("up success");
  }catch(e){
    print("up failed");
  }

}

  var zones = [];

List<List<String>> groupByFloor(List<String> zoneNames) {
  Map<int, List<String>> grouped = {};

  for (var name in zoneNames) {
    if (name.isEmpty) continue;

    // Extract floor number safely
    int? floor;
    try {
      floor = int.parse(name.split("F")[0]); // "1F_test2_m" -> 1
    } catch (e) {
      print('⚠️ Skipping invalid name: $name');
      continue;
    }

    grouped.putIfAbsent(floor, () => []);
    grouped[floor]!.add(name);
  }

  // Return a fixed list of 100 sublists (floor 1..100)
  return List.generate(100, (i) => grouped[i + 1] ?? []);
}

String _getMaterial(String zone){
  String type;
  if (zone.endsWith('c') || zone.endsWith('C')) {
  type = "carpet";
} else if (zone.endsWith('m')|| zone.endsWith('M')){
  type = "marble";
}
  else{
    type = "none";
  }
  return type;
}

Future<List<String>> waitForSweepNames(IO.Socket socket, List<String> sweepTypes) {
  final completer = Completer<List<String>>();

  socket.onAny((event, data) {
    if (data is Map) {
      final level = data['level'];
      final module = data['module'];

      if (level == 'info' && module == 'ros') {
        try {
          // Extract JSON from the message
          String rawMessage = data['message'] as String;
          final jsonStart = rawMessage.indexOf('{');
          if (jsonStart == -1) throw FormatException('No JSON found');
          final jsonStr = rawMessage.substring(jsonStart);

          final outerJson = Map<String, dynamic>.from(jsonDecode(jsonStr));
          final innerMessageStr = outerJson['message'] as String;
          final innerJson = Map<String, dynamic>.from(jsonDecode(innerMessageStr));

          final List<String> matchedNames = [];
          innerJson.forEach((areaName, areaDataRaw) {
            final areaData = Map<String, dynamic>.from(areaDataRaw);
            final type = areaData['type'];
            final propertiesRaw = areaData['properties'];

            Map<String, dynamic> properties;
            if (propertiesRaw is String) {
              properties = Map<String, dynamic>.from(jsonDecode(propertiesRaw));
            } else if (propertiesRaw is Map) {
              properties = Map<String, dynamic>.from(propertiesRaw);
            } else {
              return;
            }

            if (type == 'sweep_area' && sweepTypes.contains(properties['sweep_type'])) {
              matchedNames.add(areaData['name']);
            }
          });

          if (!completer.isCompleted) completer.complete(matchedNames);

        } catch (e) {
          if (!completer.isCompleted) completer.completeError('Error parsing message: $e');
        }
      }
    }
  });

  return completer.future;
}


Future<List<String>> zonehelper(
  Uri zoneUrl,
  String? robotIpAddress,
  List<String> sweepTypes,
) async {
  final socket = IO.io(
    'http://$robotIpAddress:19001',
    <String, dynamic>{
      'transports': ['websocket'],
      'forceNew': true,      // ✅ ensures fresh connection
      'reconnection': false, // ✅ don’t auto-reuse old socket
      'autoConnect': true,
    },
  );

  final connectCompleter = Completer<void>();
  socket.onConnect((_) {
    print('✅ Connected to Socket.IO server!');
    if (!connectCompleter.isCompleted) connectCompleter.complete();
  });

  socket.onError((data) {
    if (!connectCompleter.isCompleted) {
      connectCompleter.completeError('Socket connection error: $data');
    }
  });

  try {
    await connectCompleter.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print("⚠️ Socket connect timeout");
        return;
      },
    );
  } catch (e) {
    print("Socket connection failed: $e");
  }

  // listen for message BEFORE sending trigger
  final sweepFuture = waitForSweepNames(socket, sweepTypes);

  print('🔌 Sending HTTP GET to trigger server...');
  final response = await http.get(zoneUrl);
  print('📩 HTTP GET completed: ${response.statusCode}');

  List<String> sweepNames = [];
  try {
    sweepNames = await sweepFuture.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print("⚠️ Timeout waiting for sweep message");
        return <String>[]; // empty fallback
      },
    );
  } catch (e) {
    print("Error waiting for sweep message: $e");
  }

  await Future.delayed(const Duration(milliseconds: 200)); // small grace
  socket.dispose();  // ✅ ensures proper cleanup
  print("🧹 Socket closed cleanly.");

  return sweepNames;
}

Future<List<String>> simplezone(Uri zoneurl)async{
    try {
    final jsonResponse = await http.get(zoneurl);

    if (jsonResponse.statusCode != 200) {
      print("HTTP error: ${jsonResponse.statusCode}");
      return [];
    }

    final decoded = jsonDecode(jsonResponse.body);
    final List<dynamic> dataList = decoded['data'];

    return dataList
        .map((item) => item['name'].toString())
        .toList();
  } catch (e) {
    print("JSON parse error: $e");
    return [];
  }
}

Future<void> waitUntilRobotIdle(String? robotIpAddress) async {
  print("Waiting for robot to become idle...");
  String url = "http://$robotIpAddress:9001/api/robot_status";
  int idleSeconds = 0;


  while (true) {
    await Future.delayed(const Duration(seconds: 1));

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = response.body.trim();

        if (body.contains("idle")) {
          idleSeconds++;
        } else {
          idleSeconds = 0; // reset countdown if robot not idle
        }
        if (idleSeconds >= 15) {
          print("Robot is idle. Proceeding to next task.");
          return;
        }
      }
    } catch (e) {
      print("Polling error: $e");
       idleSeconds = 0; // reset on error too
    }
  }
}

String calculateSignature(Map<String, dynamic> parameters) {
  // 1. Sort parameters by key (lexicographically)
  String access_key_secret = "r8iVawyhWv3Ij8560NqGJr0nOEvhzkr5";
  
  final sortedKeys = parameters.keys.toList()..sort();

  // 2. Build query string: k=v&k=v
  final queryString = sortedKeys
      .map((key) => '$key=${parameters[key]}')
      .join('&');

  // 3. Append "&" to secret key (same as Python)
  final String key = '$access_key_secret&';

  // 4. HMAC-SHA1
  final hmacSha1 = Hmac(sha1, utf8.encode(key));
  final digest = hmacSha1.convert(utf8.encode(queryString));

  // 5. Base64 encode
  final signature = base64Encode(digest.bytes);

  return signature;
}

Future<String> generateAccessToken() async {
  final String timestamp =
      DateFormat("yyyy-MM-dd'T'HH:mm:ss+08:00").format(DateTime.now());

  final String signatureNonce = const Uuid().v4();
  String access_key_id = "9qv0rq7LBT4jlEid";
  String BASE_URL = "https://open-api.yunjibot.com";
  final Map<String, dynamic> parameters = {
    'signatureNonce': signatureNonce,
    'accessKeyId': access_key_id,
    'timestamp': timestamp,
  };

  final String signature = calculateSignature(parameters);

  parameters['signature'] = signature;

  final String url = '$BASE_URL/v3/auth/accessToken';

  print(parameters);

  final http.Response response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(parameters),
  );

  final Map<String, dynamic> responseData =
      jsonDecode(response.body) as Map<String, dynamic>;

  print(responseData['data']?['accessToken'] ?? '');

  return responseData['data']?['accessToken'] ?? '';
}

Future<Map<String, dynamic>> createPushTargetTask({
  required String storeId,
  required String taskId,
  required String robotId,
  bool autoBack = true,
  String? target,
}) async {
  String BASE_URL = "https://open-api.yunjibot.com";
  String access_key_id = "9qv0rq7LBT4jlEid";
  final String url = '$BASE_URL/v3/rcs/task/flow/execute';

  final String timestamp =
      DateFormat("yyyy-MM-dd'T'HH:mm:ss+08:00").format(DateTime.now());

  final String signatureNonce = const Uuid().v4();

  final Map<String, dynamic> parameters = {
    'signatureNonce': signatureNonce,
    'accessKeyId': access_key_id,
    'timestamp': timestamp,
  };

  final String signature = calculateSignature(parameters);
  String accessToken = await generateAccessToken();
  final Map<String, String> headers = {
    'token': accessToken,
    'signatureNonce': signatureNonce,
    'timestamp': timestamp,
    'accessKeyId': access_key_id,
    'signature': signature,
    'Content-Type': 'application/json',
  };

  final Map<String, dynamic> data = {
    'outTaskId': taskId,
    'templateId': 'dock_cabin_to_move_and_lift_down',
    'storeId': storeId,
    'params': {
      'dockCabinId': '',
      'chassisId': robotId,
      'dockingCabinMarker': 'charge_point_1F_40300423',
      'target': target,
    },
  };

  final http.Response response = await http.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(data),
  );

  final Map<String, dynamic> responseData =
      jsonDecode(response.body) as Map<String, dynamic>;

  print(responseData);

  if (responseData['code'] == 11012) {
    print('Access token has expired. Please refresh the token and try again.');
  } else if (responseData['code'] != 200) {
    print('Error occurred: ${responseData['message']}');
  }

  return responseData;
}

  void _attachChargingChassis(BuildContext context) async {
    const int port = 18080;
    const String path = '/api/v1/task/flow';
    String? robotIpAddress = widget.newIp;
    final String apiUrl = 'http://$robotIpAddress:$port$path';

    final String taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final String timestamp = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc());
    String scqSn = "";
    startPollingSafe(context);

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
        if (firstSix =="charge"){
          Map<String, dynamic> properties =  jsonDecode(results[marker]['properties']);
          if(properties['charging_pile_type'].startsWith("YJHJ")){
            scqSn = properties['cabin_key'];
          }
        } 
      }

    }catch(e){
    }
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
      "cabinKey": scqSn,
      //"cabinKey": "SCQS00G13C0100349",
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
    upper = scqSn;
  }

void _attachNewChassisDemo(BuildContext context) async{
  createPushTargetTask(storeId: "2025141028176506291344364707328", taskId: _uuid.v4(), robotId: "WTHT08E03B0616789");
}

  // FIX: Added 'async' and corrected hardness parameter usage
  Future<void> _startCarpetVacuuming(BuildContext context, String hardness) async {
    
    const int port = 18080;
    const String path = '/api/v1/task/flow';
    String? robotIpAddress = widget.newIp;
    final String apiUrl = 'http://$robotIpAddress:$port$path';

    final String taskId = _uuid.v4();
    final String clientToken = _uuid.v4().replaceAll('-', '');
    final String timestamp = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc());

    var url = Uri.parse('http://$robotIpAddress:9001/api/robot_status');
    var zone_list=[];
    var newurl = Uri.parse('http://$robotIpAddress:9001/api/robot_info');
    var zoneurl = Uri.parse('http://$robotIpAddress:18080/api/marker/area/list');
    var upperurl = Uri.parse('http://$robotIpAddress:19001/api/tools/device/info');
    startPollingSafe(context); // start async, don’t await
    try {
        var response = await http.get(url);
        var response2 = await http.get(newurl);
        var upperres = await http.get(upperurl);
        //final zonedata = await zonehelper(zoneurl, robotIpAddress, ["carpet"]);
        final zonedata = await simplezone(zoneurl);
        if (response.statusCode == 200) {
        // The request was successful, and the server sent back a response.
      

        // If you expect a JSON response, you can decode it like this:
        var decodedData = jsonDecode(response.body);
        int currentFloor = decodedData['results']['current_floor'];
        var decodedData1 = jsonDecode(response2.body);
        String robotid = decodedData1['results']['product_id'];
        var decodedupper = jsonDecode(upperres.body);
        print("zones:");
        print(zonedata);
        zones  = groupByFloor(zonedata);
        print("zonegroup:");
        print(zones);
        //zones = [["1F_testing_1", "1F_test2"], ["2F_hallway", "2F_"]];
        String material;
        upper = decodedupper["data"]?["info"]?["relevanceKey"] ?? "";


        for (var zonename in zones[currentFloor-1]) {
            //material = _getMaterial(zonename);
            //if (material == "carpet"){
            final Map<String, dynamic> sweepZone3 = {
            "coordinates": [
            /*{"x": "5.29", "y": "4.07"},
            {"x": "5.39", "y": "-3.03"},
            {"x": "11.05", "y": "-2.95"},
            {"x": "10.95", "y": "4.19"},
            */],
            "creator": robotid,
            "dirtyImgUrls": [],
            "floor": currentFloor,
            "id": "20240514040328107630247857670631",
            "label": "",
            "level": 0,
            //"material": material,
            "material": "carpet",
            "probability": "",
            "zoneName": zonename,
            "zoneType": "SWEEP",
            };
            zone_list.add(sweepZone3);
            //}
        }
        } else {
        // The request failed with a non-200 status code.
        print('Request failed with status: ${response.statusCode}.');
        }
    } catch (e) {
        // An error occurred during the request.
        print('Error caught: $e');
    }
    final Map<String, dynamic> executorObject = {
      "optionId": "1002",
      "executionId": "sweep",
      "params": {
        //"cabinKey": "SCQS00G13C0100349",
        "cabinKey": upper,
        "attach": {
          "storeId": "202412209218662201730709785088",
          "taskId": ["{taskId}"],
        },
        "hcp": 2,
        "hardness": hardness, // FIX: Changed 'L' to use the 'hardness' parameter
        "zones": zone_list,
      }
    };

    var executorList = [];
    for (var singlezone in zone_list){
          final Map<String, dynamic> executorO = {
            "optionId": "1002",
            "executionId": "sweep",
            "params": {
        //"cabinKey": "SCQS00G13C0100349",
            "cabinKey": upper,
            "attach": {
              "storeId": "202412209218662201730709785088",
              "taskId": ["{taskId}"],
            },
            "hcp": 2,
            "hardness": hardness, // FIX: Changed 'L' to use the 'hardness' parameter
            "zones": [singlezone],
      }
    };
    executorList.add(executorO);
    }

    //final String executorsJsonString = jsonEncode([executorObject]); // FIX: executorObject should be in a list
    var requestlist = [];
    for (var newexecutor in executorList){
      final String executor = jsonEncode([newexecutor]);
      final String newtaskId = _uuid.v4();
      final Map<String, dynamic> requestData = {
        "cabinKey": upper,
        "cabinDeviceType": 456,
        "taskType": 0,
        "clientToken": clientToken,
        "executors": executor,
        "forceCancel": false,
        "taskId": newtaskId,
        "versionNumber": "1",
        "timestamp": timestamp,
      };
      requestlist.add(requestData);
    }

    for (dynamic request in requestlist) {
      print('Calling API: $apiUrl');
      print('Request Body: ${jsonEncode(request)}');

      Map<String, dynamic>? jsonRes;

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(request),
        );

        if (response.statusCode != 200) {
          print('API Error: ${response.statusCode}');
          _showFeedback(context, 'Failed to start task: ${response.statusCode}', Colors.red);
          continue; // skip to next request
        }

        jsonRes = jsonDecode(response.body);
        print("API Response: $jsonRes");

      } catch (e) {
        print('Network Error: $e');
        _showFeedback(context, 'Cannot reach robot.', Colors.red);
        continue; // skip to next
      }

      if (jsonRes?["code"] == 101026 || jsonRes?["code"] == 101020) {
        print("Task failed (code 101026). Skipping to next task.");
        _showFeedback(context, 'Task failed – skipping.', Colors.red);
        continue;
      }

    // If code NOT failed → wait for robot idle
      await waitUntilRobotIdle(robotIpAddress);
    }



    /*
    final Map<String, dynamic> requestData = {
      "cabinKey": upper,
      //"cabinKey": "SCQS00G13C0100349",
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
    }*/
  }

  // FIX: Added BuildContext parameter
  Future<void> _startFloorSweeping(BuildContext context, String hardness) async{
   
    const int port = 18080;
    const String path = '/api/v1/task/flow';
    String? robotIpAddress = widget.newIp;
    final String apiUrl = 'http://$robotIpAddress:$port$path';

    final String taskId = _uuid.v4();
    final String clientToken = _uuid.v4().replaceAll('-', '');
    final String timestamp = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc());

    var url = Uri.parse('http://$robotIpAddress:9001/api/robot_status');
    var zone_list=[];
    var newurl = Uri.parse('http://$robotIpAddress:9001/api/robot_info');
    var zoneurl = Uri.parse('http://$robotIpAddress:18080/api/marker/area/list');
    var upperurl = Uri.parse('http://$robotIpAddress:19001/api/tools/device/info');
    startPollingSafe(context); // start async, don’t await
    try {
        var response = await http.get(url);
        var response2 = await http.get(newurl);
        //final zonedata = await zonehelper(zoneurl, robotIpAddress, ["marble"]);
        final zonedata = await simplezone(zoneurl);
        var upperres = await http.get(upperurl);

        if (response.statusCode == 200) {
        // The request was successful, and the server sent back a response.
      

        // If you expect a JSON response, you can decode it like this:
        var decodedData = jsonDecode(response.body);
        int currentFloor = decodedData['results']['current_floor'];
        var decodedData1 = jsonDecode(response2.body);
        String robotid = decodedData1['results']['product_id'];
        var decodedupper = jsonDecode(upperres.body);
  
        print("zones:");
        print(zonedata);

        zones  = groupByFloor(zonedata);
        print("zonegroup:");
        print(zones);
        String material;
        upper = decodedupper["data"]?["info"]?["relevanceKey"] ?? "";
        //zones = [["1F_testing_1", "1F_test2"], ["2F_hallway", "2F_"]];
        for (var zonename in zones[currentFloor-1]) {
          //material = _getMaterial(zonename);
          //if (material == "marble"){
            final Map<String, dynamic> sweepZone3 = {
            "coordinates": [
            /*{"x": "5.29", "y": "4.07"},
            {"x": "5.39", "y": "-3.03"},
            {"x": "11.05", "y": "-2.95"},
            {"x": "10.95", "y": "4.19"},
            */],
            "creator": robotid,
            "dirtyImgUrls": [],
            "floor": currentFloor,
            "id": "20240514040328107630247857670631",
            "label": "",
            "level": 0,
            //"material": material,
            "material": "marble",
            "probability": "",
            "zoneName": zonename,
            "zoneType": "SWEEP",
            };
            zone_list.add(sweepZone3);
            //}
          
        }
        } else {
        // The request failed with a non-200 status code.
        print('Request failed with status: ${response.statusCode}.');
        }
    } catch (e) {
        // An error occurred during the request.
        print('Error caught: $e');
    }
    final Map<String, dynamic> executorObject = {
      "optionId": "1002",
      "executionId": "sweep",
      "params": {
        //"cabinKey": "SCQS00G13C0100349",
        "cabinKey": upper,
        "attach": {
          "storeId": "202412209218662201730709785088",
          "taskId": ["{taskId}"],
        },
        "hcp": 2,
        "hardness": hardness, // FIX: Changed 'L' to use the 'hardness' parameter
        "zones": zone_list,
      }
    };

    var executorList = [];
    for (var singlezone in zone_list){
          final Map<String, dynamic> executorO = {
            "optionId": "1002",
            "executionId": "sweep",
            "params": {
        //"cabinKey": "SCQS00G13C0100349",
            "cabinKey": upper,
            "attach": {
              "storeId": "202412209218662201730709785088",
              "taskId": ["{taskId}"],
            },
            "hcp": 2,
            "hardness": hardness, // FIX: Changed 'L' to use the 'hardness' parameter
            "zones": [singlezone],
      }
    };
    executorList.add(executorO);
    }

    //final String executorsJsonString = jsonEncode([executorObject]); // FIX: executorObject should be in a list
    final String executorsJsonString = jsonEncode(executorList);
    print(executorsJsonString);

    final Map<String, dynamic> requestData = {
      "cabinKey": upper,
      //"cabinKey": "SCQS00G13C0100349",
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
  Future<void> _startMarbleMopping(BuildContext context, String hardness) async{
    
    const int port = 18080;
    const String path = '/api/v1/task/flow';
    String? robotIpAddress = widget.newIp;
    final String apiUrl = 'http://$robotIpAddress:$port$path';

    final String taskId = _uuid.v4();
    final String clientToken = _uuid.v4().replaceAll('-', '');
    final String timestamp = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc());

    var url = Uri.parse('http://$robotIpAddress:9001/api/robot_status');
    var zone_list=[];
    var newurl = Uri.parse('http://$robotIpAddress:9001/api/robot_info');
    var zoneurl = Uri.parse('http://$robotIpAddress:18080/api/marker/area/list');
    var upperurl = Uri.parse('http://$robotIpAddress:19001/api/tools/device/info');
    startPollingSafe(context); // start async, don’t await
    try {
        var response = await http.get(url);
        var response2 = await http.get(newurl);
        //final zonedata = await zonehelper(zoneurl, robotIpAddress, ["marble"]);
        final zonedata = await simplezone(zoneurl);
        var upperres = await http.get(upperurl);

        if (response.statusCode == 200) {
        // The request was successful, and the server sent back a response.
      

        // If you expect a JSON response, you can decode it like this:
        var decodedData = jsonDecode(response.body);
        int currentFloor = decodedData['results']['current_floor'];
        var decodedData1 = jsonDecode(response2.body);
        String robotid = decodedData1['results']['product_id'];
        var decodedupper = jsonDecode(upperres.body);
        print("zones:");
        print(zonedata);
        zones  = groupByFloor(zonedata);
        print("groupzone:");
        print(zones);
        String material;
        upper = decodedupper["data"]?["info"]?["relevanceKey"] ?? "";
        //zones = [["1F_testing_1", "1F_test2"], ["2F_hallway", "2F_"]];
        for (var zonename in zones[currentFloor-1]) {
          //material = _getMaterial(zonename);
          //if (material == "marble"){
            final Map<String, dynamic> sweepZone3 = {
            "coordinates": [
            /*{"x": "5.29", "y": "4.07"},
            {"x": "5.39", "y": "-3.03"},
            {"x": "11.05", "y": "-2.95"},
            {"x": "10.95", "y": "4.19"},
            */],
            "creator": robotid,
            "dirtyImgUrls": [],
            "floor": currentFloor,
            "id": "20240514040328107630247857670631",
            "label": "",
            "level": 0,
            //"material": material,
            "material": "marble",
            "probability": "",
            "zoneName": zonename,
            "zoneType": "SWEEP",
            };
            zone_list.add(sweepZone3);
           //}
        }
        } else {
        // The request failed with a non-200 status code.
        print('Request failed with status: ${response.statusCode}.');
        }
    } catch (e) {
        // An error occurred during the request.
        print('Error caught: $e');
    }
    final Map<String, dynamic> executorObject = {
      "optionId": "1002",
      "executionId": "sweep",
      "params": {
        //"cabinKey": "SCQS00G13C0100349",
        "cabinKey": upper,
        "attach": {
          "storeId": "202412209218662201730709785088",
          "taskId": ["{taskId}"],
        },
        "hcp": 2,
        "hardness": hardness, // FIX: Changed 'L' to use the 'hardness' parameter
        "zones": zone_list,
      }
    };

    var executorList = [];
    for (var singlezone in zone_list){
          final Map<String, dynamic> executorO = {
            "optionId": "1002",
            "executionId": "sweep",
            "params": {
        //"cabinKey": "SCQS00G13C0100349",
            "cabinKey": upper,
            "attach": {
              "storeId": "202412209218662201730709785088",
              "taskId": ["{taskId}"],
            },
            "hcp": 2,
            "hardness": hardness, // FIX: Changed 'L' to use the 'hardness' parameter
            "zones": [singlezone],
      }
    };
    executorList.add(executorO);
    }

    //final String executorsJsonString = jsonEncode([executorObject]); // FIX: executorObject should be in a list
    final String executorsJsonString = jsonEncode(executorList);

    final Map<String, dynamic> requestData = {
      "cabinKey": upper,
      //"cabinKey": "SCQS00G13C0100349",
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

  void _automaticLifting(BuildContext context) async{
    String? robotIpAddress = widget.newIp;
    var url = Uri.parse('http://$robotIpAddress:9001/api/robot_status');
    try{
      var response = await http.get(url);
      var decodedData = jsonDecode(response.body);
      int lift = decodedData['results']['chassis_lift_state'];
      if (lift == 2){
        var upUrl = Uri.parse('http://$robotIpAddress:19001/api/tools/operation/lift/up');
        http.get(upUrl);
        print("up success");
      }
      else if(lift ==1){
        _postApiCall(
          context: context,
          port: 19001,
          path: '/api/tools/operation/lift/down',
          successMessage: 'Robot lifts successfully',
          failureMessage: 'Failed to lift the robot',
        );
      }
      }catch(e){
        print("error");
    }
  }

  String _addNote(String input){
  final parts = input.split('_');
  String? robotIP = widget.newIp;
  if (parts.length == 2 && robotIP != '172.20.24.14') {
    final floorNumber = int.tryParse(parts[1]);
    if (floorNumber != null) {
      final floorNames = ['First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh', 'Eighth', 'Ninth', 'Tenth', 'Eleventh', 'Twelfth', 'Thirteenth', 'Fourteenth', 'Fifteenth', 'Sixteenth', 'Seventeenth', 'Eighteenth', 'Nineteenth', 'Twentieth', 'Twenty-First', 'Twenty-Second', 'Twenty-Third', 'Twenty-Fourth', 'Twenty-Fifth', 'Twenty-Sixth', 'Twenty-Seventh', 'Twenty-Eighth', 'Twenty-Ninth', 'Thirtieth'];
      if (floorNumber <= floorNames.length) {
        return '${floorNames[floorNumber - 1]} floor';
      }
    }
  }
  else if (robotIP == '172.20.24.14'){
    final code = parts[1];
    if (code.length == 2) {
      final buildingNum = int.tryParse(code[0]);
      final floorNum = int.tryParse(code[1]);

      final buildingNames = ['Courtyard', 'Residence Inn'];
      final floorNames = ['First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth'];

      if (buildingNum != null && floorNum != null) {
        final buildingStr = buildingNames[buildingNum - 1];
        final floorStr = floorNames[floorNum - 1];
        return '$floorStr floor $buildingStr';
      }
    }
    else if(code.length == 1){
      return 'First floor';
    }
  }
  return input;
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
                      onPressed: () { Future.microtask(() => _startCarpetVacuuming(context, "M"));
                      },
                    
                    ),
                    _buildActionButton(
                      text: 'Start floor Sweeping',
                      emoji: '👾🧹',
                      onPressed: () { Future.microtask(() => _startFloorSweeping(context, "S"));
                      },
                    ),
                    _buildActionButton(
                      text: 'Marble wet mopping',
                      emoji: '😳🧹',
                      onPressed: () { 
                            CheckBoxDialog.show(context, () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ All boxes checked and processed!')),
                            );
                            Future.microtask(() => _startMarbleMopping(context, "L"));
                          });
                        //Future.microtask(() => _startMarbleMopping(context, "L"));
                      },
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
                    buildZoneSelectorButton(),
                    _buildActionButton(
                      text: "attach to test cabin",
                      onPressed: () => _attachNewChassis(context),
                    ),
                    _buildActionButton(
                      text: "attach to charging cabin",
                      onPressed: () => _attachChargingChassis(context),
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
                                    child: Text(_addNote(value)),
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

class ZoneSelectorDialog extends StatefulWidget {
  final List<List<String>> groupedZones;
  final List<String> initialSelected;

  const ZoneSelectorDialog({
    super.key,
    required this.groupedZones,
    required this.initialSelected,
  });

  @override
  State<ZoneSelectorDialog> createState() => _ZoneSelectorDialogState();
}


class _ZoneSelectorDialogState extends State<ZoneSelectorDialog> {
  late Set<String> selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialSelected.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Zones by Floor'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
children: List.generate(widget.groupedZones.length, (index) {
  final zonesOnFloor = widget.groupedZones[index];

  if (zonesOnFloor.isEmpty) return const SizedBox.shrink();

  // 从 zone 字符串中解析楼层，例如 "2F_zone1" -> "2F"
  final floor = zonesOnFloor.first.split('_').first;

  return _buildFloorSection(floor, zonesOnFloor);
  }),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selected.toList()),
          child: const Text('Submit'),
        ),
      ],
    );
  }

  Widget _buildFloorSection(String floor, List<String> zones) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          floor,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: zones.map(_zoneButton).toList(),
      ),
      const Divider(),
    ],
  );
}

Widget _zoneButton(String zone) {
  final isSelected = selected.contains(zone);

  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: isSelected ? Colors.blue[700] : Colors.grey[300],
      foregroundColor: isSelected ? Colors.white : Colors.black,
    ),
    onPressed: () {
      setState(() {
        if (isSelected) {
          selected.remove(zone);
        } else {
          selected.add(zone);
        }
      });
    },
    child: Text(zone),
  );
}

}