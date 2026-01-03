import 'package:flutter/material.dart';

class CheckBoxDialog {
  static Future<void> show(BuildContext context, VoidCallback onAllChecked) async {
    List<bool> checkValues = [false, false, false, false];
    List<String> checkText = ["Is the mop clean?","Is there water in water tank?","Is the dust bag and trash bag empty?","Are the wheels clean?"];

    await showDialog(
      context: context,
      barrierDismissible: false, // force user to finish or cancel
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool allChecked = checkValues.every((v) => v);

            return AlertDialog(
              title: const Text('Please check all items'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < 4; i++)
                    CheckboxListTile(
                      title: Text(checkText[i]),
                      value: checkValues[i],
                      onChanged: (value) {
                        setState(() {
                          checkValues[i] = value ?? false;
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // cancel
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: allChecked
                      ? () {
                          Navigator.of(context).pop(); // close dialog
                          onAllChecked(); // callback
                        }
                      : null,
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
