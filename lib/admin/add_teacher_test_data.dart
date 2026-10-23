import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TeacherTestDataGenerator {
  static Future<void> addTeacherTestData(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Adding teacher test data...'),
            ],
          ),
        ),
      );

      // Add test attendance data for teacher TCHR002 (Prof. Maria Garcia)
      final now = DateTime.now();
      final attendanceData = {
        // Present students for today
        'attendance_TCHR002_CS2024001_${now.millisecondsSinceEpoch}_1': {
          'id': 'attendance_TCHR002_CS2024001_${now.millisecondsSinceEpoch}_1',
          'studentId': 'CS2024001',
          'classId': 'class_TCHR002_${now.millisecondsSinceEpoch}',
          'classTitle': 'Introduction to Programming',
          'classDescription': 'Basic programming concepts',
          'date': now.toIso8601String(),
          'status': 'present',
          'duration': 2,
          'joinTime': now.subtract(const Duration(minutes: 2)).toIso8601String(),
          'leaveTime': now.toIso8601String(),
          'teacherName': 'Prof. Maria Garcia',
          'teacherId': 'TCHR002',
        },
        'attendance_TCHR002_IT2024002_${now.millisecondsSinceEpoch}_1': {
          'id': 'attendance_TCHR002_IT2024002_${now.millisecondsSinceEpoch}_1',
          'studentId': 'IT2024002',
          'classId': 'class_TCHR002_${now.millisecondsSinceEpoch}',
          'classTitle': 'Introduction to Programming',
          'classDescription': 'Basic programming concepts',
          'date': now.toIso8601String(),
          'status': 'present',
          'duration': 2,
          'joinTime': now.subtract(const Duration(minutes: 2)).toIso8601String(),
          'leaveTime': now.toIso8601String(),
          'teacherName': 'Prof. Maria Garcia',
          'teacherId': 'TCHR002',
        },
        'attendance_TCHR002_EE2024003_${now.millisecondsSinceEpoch}_1': {
          'id': 'attendance_TCHR002_EE2024003_${now.millisecondsSinceEpoch}_1',
          'studentId': 'EE2024003',
          'classId': 'class_TCHR002_${now.millisecondsSinceEpoch}',
          'classTitle': 'Introduction to Programming',
          'classDescription': 'Basic programming concepts',
          'date': now.toIso8601String(),
          'status': 'present',
          'duration': 2,
          'joinTime': now.subtract(const Duration(minutes: 2)).toIso8601String(),
          'leaveTime': now.toIso8601String(),
          'teacherName': 'Prof. Maria Garcia',
          'teacherId': 'TCHR002',
        },
        // Absent students
        'attendance_TCHR002_ME2024004_${now.millisecondsSinceEpoch}_1': {
          'id': 'attendance_TCHR002_ME2024004_${now.millisecondsSinceEpoch}_1',
          'studentId': 'ME2024004',
          'classId': 'class_TCHR002_${now.millisecondsSinceEpoch}',
          'classTitle': 'Introduction to Programming',
          'classDescription': 'Basic programming concepts',
          'date': now.toIso8601String(),
          'status': 'absent',
          'duration': 0,
          'joinTime': now.subtract(const Duration(minutes: 1)).toIso8601String(),
          'leaveTime': now.subtract(const Duration(minutes: 1)).toIso8601String(),
          'teacherName': 'Prof. Maria Garcia',
          'teacherId': 'TCHR002',
        },
        'attendance_TCHR002_CE2024005_${now.millisecondsSinceEpoch}_1': {
          'id': 'attendance_TCHR002_CE2024005_${now.millisecondsSinceEpoch}_1',
          'studentId': 'CE2024005',
          'classId': 'class_TCHR002_${now.millisecondsSinceEpoch}',
          'classTitle': 'Introduction to Programming',
          'classDescription': 'Basic programming concepts',
          'date': now.toIso8601String(),
          'status': 'absent',
          'duration': 0,
          'joinTime': now.subtract(const Duration(minutes: 1)).toIso8601String(),
          'leaveTime': now.subtract(const Duration(minutes: 1)).toIso8601String(),
          'teacherName': 'Prof. Maria Garcia',
          'teacherId': 'TCHR002',
        },
      };

      // Add attendance data to Firebase
      final attendanceRef = FirebaseDatabase.instance.ref('attendance');
      for (final entry in attendanceData.entries) {
        await attendanceRef.child(entry.key).set(entry.value);
      }

      // Add an active session for real-time testing
      final activeSessionData = {
        'title': 'Introduction to Programming',
        'teacherId': 'TCHR002',
        'teacherName': 'Prof. Maria Garcia',
        'subject': 'Information Technology',
        'timestamp': now.millisecondsSinceEpoch,
        'status': 'active',
        'participants': {
          'CS2024001': {
            'studentId': 'CS2024001',
            'studentName': 'John Smith',
            'joinTime': now.subtract(const Duration(minutes: 5)).toIso8601String(),
            'status': 'active',
          },
          'IT2024002': {
            'studentId': 'IT2024002',
            'studentName': 'Emily Johnson',
            'joinTime': now.subtract(const Duration(minutes: 5)).toIso8601String(),
            'status': 'active',
          },
          'EE2024003': {
            'studentId': 'EE2024003',
            'studentName': 'Michael Chen',
            'joinTime': now.subtract(const Duration(minutes: 5)).toIso8601String(),
            'status': 'active',
          },
        },
      };

      await FirebaseDatabase.instance.ref('active_sessions/session_TCHR002_${now.millisecondsSinceEpoch}').set(activeSessionData);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Teacher Test Data Added!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Added test data for Prof. Maria Garcia (TCHR002):'),
                const SizedBox(height: 10),
                const Text('• 3 Present Students'),
                const Text('• 2 Absent Students'),
                const Text('• 1 Active Session with 3 participants'),
                const SizedBox(height: 10),
                const Text('Analytics should now show:'),
                const Text('• Present Today: 3'),
                const Text('• Absent Today: 2'),
                const Text('• Active Now: 3'),
                const Text('• Attendance Rate: 60%'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding teacher test data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static void showAddTeacherTestDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Teacher Test Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will add test data for Prof. Maria Garcia (TCHR002):'),
            SizedBox(height: 10),
            Text('• 3 Present students'),
            Text('• 2 Absent students'),
            Text('• 1 Active session with 3 participants'),
            Text('• Attendance rate: 60%'),
            SizedBox(height: 10),
            Text('This will fix the analytics dashboard showing 0 values.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              addTeacherTestData(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Add Data'),
          ),
        ],
      ),
    );
  }
}
