import 'package:flutter/material.dart';
import 'functionspage.dart';
import 'summonpage.dart';
import 'subsite.dart';
import 'secondsite.dart';
import 'update.dart';
//import 'navigation.dart';
import 'navitest.dart';
import 'overlay.dart';
import 'dart:convert';
//import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';


/// 全局唯一的机器人 IP 真源
final ValueNotifier<String?> currentRobotIp = ValueNotifier<String?>(null);
List<String> debugLogs = [];

void overridePrintAndRunApp() {
  ZoneSpecification spec = ZoneSpecification(
    print: (self, parent, zone, line) {
      debugLogs.add(line);
      parent.print(zone, line);
    },
  );

  runZonedGuarded(() {
    runApp(MyApp());
  }, (error, stack) {
    debugLogs.add("ERROR: $error\n$stack");
    print("ERROR: $error\n$stack");
  }, zoneSpecification: spec);
}
//void main() => runApp(MyApp());
void main() => overridePrintAndRunApp();

void logPrint(Object? object) {
  debugLogs.add(object.toString());
  print(object); // still prints to console
}

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

class _HomePageState extends State<HomePage>  with WidgetsBindingObserver {
  String? selectedIp; // 初始无选中
  String? selectedPoint;
  final TextEditingController _controller = TextEditingController();
  final List<String> ipList = [
    '',
    '172.20.24.3-Ontario',
    '172.20.24.5-Ontario',
    '192.168.200.146-NY',
    '192.168.0.110-Monrovia',
    '172.20.24.14-Marina Del Rey',
    '192.168.10.10-Connect to Robot',
    '10.1.16.127-Qbay1',
    '10.1.16.41-Qbay2',
    '192.168.4.13-Sunward'
    
  ];
  bool? isEstopOn; // null = loading
  String _version = '';


    final UpdateService _updateService = UpdateService();
  @override
  void initState() {
    
    super.initState();
    _loadVersion();
    WidgetsBinding.instance.addObserver(this);
    _loadLastIp();
    Future.delayed(Duration(seconds: 2), () {
     
      if (mounted) { // Ensure widget is still in the tree
        
        _updateService.checkForUpdate(context);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalControlOverlay.show(context);
    });
  }


  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${info.version}+${info.buildNumber}';
    });
  }


@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    // 🟢 App navigated back to this screen or resumed from background
    if (selectedIp != null && selectedIp!.isNotEmpty) {
      fetchEstopState();
    }
  }
}

Future<void> _loadLastIp() async {
  final prefs = await SharedPreferences.getInstance();
  final lastIp = prefs.getString('last_ip') ?? '';

  setState(() {
    selectedIp = lastIp;
    _controller.text = lastIp;
  });

  if (!ipList.contains(selectedIp)) {
    selectedIp = '';
  }

  // ⭐ 关键：同步到全局
  currentRobotIp.value =
      (lastIp.contains('-')) ? lastIp.split('-').first : lastIp;

  if (lastIp.isNotEmpty) {
    fetchEstopState();
  }
}
  
  Future<void> _saveLastIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_ip', ip);
  }

  String? newIP;

  Future<void> fetchEstopState() async {
  if (selectedIp == null || selectedIp!.isEmpty) return;

  final url = "http://${selectedIp!.split('-').first}:9001/api/robot_status";

  try {
    final res = await http.get(Uri.parse(url));
    final json = jsonDecode(res.body);

    setState(() {
      isEstopOn = json["results"]["soft_estop_state"] ?? false;
    });
  } catch (e) {
    print("GET estop error: $e");
    setState(() => isEstopOn = false);
  }
}

Future<void> toggleEstopState() async {
  if (isEstopOn == null) return; // still loading

  final newState = !isEstopOn!;
  final previous = isEstopOn;

  setState(() => isEstopOn = newState);

  final url = "http://${selectedIp!.split('-').first}:9001/api/estop?flag=$newState";

  try {
    final res = await http.post(Uri.parse(url));
    if (res.statusCode != 200) throw Exception("POST failed");
  } catch (e) {
    print("POST toggle error: $e");
    setState(() => isEstopOn = previous); // revert if failure
  }
}

void showLogDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text("Debug Logs"),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              debugLogs.join("\n"),
              style: TextStyle(fontFamily: "monospace"),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text("Copy All"),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: debugLogs.join("\n")));
            },
          ),
          TextButton(
            child: Text("Clear Logs"),
            onPressed: () {
              debugLogs.clear();
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text("Close"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
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
        final scale = MediaQuery.of(context).textScaler;
        final basebuttonTextSize = constraints.maxHeight * 0.04;
        final buttonTextSize = scale.scale(basebuttonTextSize);
        final actualButtonTextSize =
            isPortrait ? buttonTextSize * 0.6 : buttonTextSize;

        return Scaffold(
          body: Column(
            children: [
              // 顶部蓝色按钮栏
              Container(
                height: topHeight,
                width: double.infinity,
                color: const Color.fromARGB(255, 93, 59, 215),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: 16, // horizontal space
                  runSpacing: 8, // vertical space
                  children: [
                    _buildButton('estop', actualButtonTextSize, context),
                    _buildButton('Summon', actualButtonTextSize, context),
                    _buildButton('Functions', actualButtonTextSize, context),
                    _buildButton('More', actualButtonTextSize, context),
                    _buildButton('Func-old', actualButtonTextSize, context),
                    _buildButton('log', actualButtonTextSize, context),
                    _buildButton('Navi', actualButtonTextSize, context),
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
                            String afterDash = (value.contains('-'))
                              ? value.split('-')[1]
                              : value;
                            return DropdownMenuItem<String>(
                              value: value,/*.isEmpty ? null : value,*/
                              child: Text(
                                afterDash,
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 24,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              String beforeDash = (newValue != null && newValue.contains('-'))
                              ? newValue.split('-').first
                              : (newValue ?? '');
                              newIP = beforeDash;
                              selectedIp = newValue;
                              currentRobotIp.value = beforeDash;
                              String ip = selectedIp ?? "";
                              _saveLastIp(ip);
                              fetchEstopState();
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
                      Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 93, 59, 215),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'v$_version',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
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
    String beforeDash = (selectedIp?.contains('-') ?? false)
        ? selectedIp!.split('-').first
        : (selectedIp ?? '');
        newIP = beforeDash;
    switch (label) {
      case 'estop':
        /*onPressed = () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => naviPage(newIp: newIP)),
          );
        };*/
        onPressed = (selectedIp?.isNotEmpty == true && isEstopOn != null)
          ? () => toggleEstopState()
          : null;
        break;
      case 'Summon':
        onPressed = () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SummonPage(newIp: newIP)),
          );
        };
        break;
      case 'Functions':
        onPressed = () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => FunctionsPage(newIp: newIP)),
          );
        };
        break;
      case 'More':
        onPressed = () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => WebViewPage()),
          );
        };
        break;
      case 'Func-old':
        onPressed = () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => IpWebViewPage(ipAddress: newIP)),
          );
        };
        break;
      case 'Navi':
        onPressed = () {
          Navigator.of(context).push(
            //MaterialPageRoute(builder: (_) => naviPage(newIp: newIP)),
            MaterialPageRoute(builder: (_) => SingleHandJoystickPage(robotIp: newIP)),
          );
        };
        break;
      case 'log':
        onPressed = () => showLogDialog(context);
        break;
      default:
        onPressed = null;
    }
    if (label == 'estop') {
  // ✅ Special color-changing button
  return TextButton(
    onPressed: onPressed,
    style: ButtonStyle(
      backgroundColor: (isEstopOn == true)
          ? WidgetStateProperty.all(Colors.red)
          : WidgetStateProperty.all(Colors.white),
    ),
    child: Text(
      (isEstopOn == null) ? "Loading..." : label,
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontFamily: 'Georgia',
      ),
    ),
  );
}

// ✅ Restore default style for all other buttons
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

