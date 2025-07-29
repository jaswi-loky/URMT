import 'package:flutter/material.dart';

class FunctionsPage extends StatelessWidget {

     void _attachChassis() {
    // TODO: Add your logic to attach the chassis
    print('Executing: Attach Chassis to Cleaning Module');
  }

  void _startCarpetVacuuming() {
    // TODO: Add your logic for carpet vacuuming
    print('Executing: Start Carpet Vacuuming');
  }

  void _startFloorSweeping() {
    // TODO: Add your logic for floor sweeping
    print('Executing: Start floor Sweeping');
  }

  void _startMarbleMopping() {
    // TODO: Add your logic for marble mopping
    print('Executing: Marble wet mopping');
  }

  void _cancelCleaning() {
    // TODO: Add your logic to cancel the current cleaning task
    print('Executing: Cancel Cleaning');
  }

  void _returnToCharging() {
    // TODO: Add your logic to send the robot back to its charging station
    print('Executing: Return to Charging');
  }

  void _automaticLifting() {
    // TODO: Add your logic for automatic lifting
    print('Executing: Automatic lifting');
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
            // --- Content for the first tab: "Robot behavior" ---
            Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                // Wrap is used to lay out the buttons and allow them to wrap to the next line on smaller screens.
                child: Wrap(
                  spacing: 12.0, // Horizontal space between buttons
                  runSpacing: 12.0, // Vertical space between button rows
                  children: [
                    _buildActionButton(
                      text: 'Attach Chassis to Cleaning Module',
                      onPressed: _attachChassis,
                    ),
                    _buildActionButton(
                      text: 'Start Carpet Vacuuming',
                      emoji: '👾🧹',
                      onPressed: _startCarpetVacuuming,
                    ),
                    _buildActionButton(
                      text: 'Start floor Sweeping',
                      emoji: '👾🧹',
                      onPressed: _startFloorSweeping,
                    ),
                    _buildActionButton(
                      text: 'Marble wet mopping',
                      emoji: '😳🧹',
                      onPressed: _startMarbleMopping,
                    ),
                    _buildActionButton(
                      text: 'Cancel Cleaning',
                      onPressed: _cancelCleaning,
                    ),
                    _buildActionButton(
                      text: 'Return to Charging',
                      onPressed: _returnToCharging,
                    ),
                    _buildActionButton(
                      text: 'Automatic lifting',
                      emoji: '🎃',
                      onPressed: _automaticLifting,
                    ),
                  ],
                ),
              ),
            ),

            // --- Content for the second tab: "Select location" ---
            Card(
              margin: const EdgeInsets.all(16.0),
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
                        Text(
                          '切换底盘位置到一个\n特定点位',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
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
        backgroundColor: Colors.grey[100],
      ),
    );
  }

  // Helper widget to create styled action buttons, reducing code duplication.
  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    String? emoji,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent, // Button color
        foregroundColor: Colors.white, // Text and icon color
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Row takes minimum space
        children: [
          // If an emoji is provided, display it.
          if (emoji != null) ...[
            Text(
              emoji,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8), // Space between emoji and text
          ],
          Text(text),
        ],
      ),
    );
  }
}