import 'package:flutter/material.dart';
class FunctionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Functions'),
        backgroundColor: const Color.fromARGB(255, 93, 59, 215), // Same purple color
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text('This is the Functions Page'),
      ),
    );
  }
}