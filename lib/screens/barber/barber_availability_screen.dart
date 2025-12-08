import 'package:flutter/material.dart';

class BarberAvailabilityScreen extends StatefulWidget {
  const BarberAvailabilityScreen({super.key});

  @override
  State<BarberAvailabilityScreen> createState() =>
      _BarberAvailabilityScreenState();
}

class _BarberAvailabilityScreenState extends State<BarberAvailabilityScreen> {
  final Map<String, Map<String, dynamic>> _schedule = {
    'Monday': {'isOpen': true, 'startTime': '09:00', 'endTime': '18:00'},
    'Tuesday': {'isOpen': true, 'startTime': '09:00', 'endTime': '18:00'},
    'Wednesday': {'isOpen': true, 'startTime': '09:00', 'endTime': '18:00'},
    'Thursday': {'isOpen': true, 'startTime': '09:00', 'endTime': '18:00'},
    'Friday': {'isOpen': true, 'startTime': '09:00', 'endTime': '20:00'},
    'Saturday': {'isOpen': true, 'startTime': '09:00', 'endTime': '18:00'},
    'Sunday': {'isOpen': false, 'startTime': '09:00', 'endTime': '18:00'},
  };

  bool _isOnline = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability & Hours'),
        elevation: 0,
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Online Status Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isOnline
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.grey.shade400, Colors.grey.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (_isOnline ? Colors.green : Colors.grey).withAlpha(
                      (0.3 * 255).round(),
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isOnline ? 'ONLINE' : 'OFFLINE',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isOnline
                            ? 'Accepting new bookings'
                            : 'Not accepting bookings',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isOnline,
                    onChanged: (value) {
                      setState(() => _isOnline = value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'You are now online 🟢'
                                : 'You are now offline 🔴',
                          ),
                          backgroundColor: value ? Colors.green : Colors.grey,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.white.withAlpha(
                      (0.4 * 255).round(),
                    ),
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: Colors.white.withAlpha(
                      (0.2 * 255).round(),
                    ),
                  ),
                ],
              ),
            ),

            // Working Hours Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Working Hours',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._schedule.entries.map((entry) {
                    final day = entry.key;
                    final data = entry.value;
                    return _buildDaySchedule(
                      day: day,
                      isOpen: data['isOpen'],
                      startTime: data['startTime'],
                      endTime: data['endTime'],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Save Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Schedule saved successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySchedule({
    required String day,
    required bool isOpen,
    required String startTime,
    required String endTime,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOpen
              ? Colors.blue.withAlpha((0.2 * 255).round())
              : Colors.red.withAlpha((0.2 * 255).round()),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.08 * 255).round()),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                if (isOpen)
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        '$startTime - $endTime',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.block, size: 14, color: Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        'Closed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Switch(
            value: isOpen,
            onChanged: (value) {
              setState(() {
                _schedule[day]!['isOpen'] = value;
              });
            },
            activeThumbColor: Colors.green,
            activeTrackColor: Colors.green.withAlpha((0.4 * 255).round()),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withAlpha((0.2 * 255).round()),
          ),
        ],
      ),
    );
  }
}
