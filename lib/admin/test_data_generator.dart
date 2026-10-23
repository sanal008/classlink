import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models.dart';
import '../firebase_service.dart';

class TestDataGenerator {
  static final FirebaseService _firebaseService = FirebaseService();

  // Test student data
  static final List<Map<String, String>> _testStudents = [
    {
      'name': 'John Smith',
      'email': 'john.smith@university.edu',
      'phone': '+1234567890',
      'enrollmentId': 'CS2024001',
      'department': 'Computer Science',
      'password': 'student123',
    },
    {
      'name': 'Emily Johnson',
      'email': 'emily.johnson@university.edu',
      'phone': '+1234567891',
      'enrollmentId': 'IT2024002',
      'department': 'Information Technology',
      'password': 'student123',
    },
    {
      'name': 'Michael Chen',
      'email': 'michael.chen@university.edu',
      'phone': '+1234567892',
      'enrollmentId': 'EE2024003',
      'department': 'Electronics Engineering',
      'password': 'student123',
    },
    {
      'name': 'Sarah Williams',
      'email': 'sarah.williams@university.edu',
      'phone': '+1234567893',
      'enrollmentId': 'ME2024004',
      'department': 'Mechanical Engineering',
      'password': 'student123',
    },
    {
      'name': 'David Brown',
      'email': 'david.brown@university.edu',
      'phone': '+1234567894',
      'enrollmentId': 'CE2024005',
      'department': 'Civil Engineering',
      'password': 'student123',
    },
  ];

  // Test teacher data
  static final List<Map<String, String>> _testTeachers = [
    {
      'name': 'Dr. Robert Anderson',
      'email': 'r.anderson@university.edu',
      'phone': '+1234567880',
      'enrollmentId': 'TCHR001',
      'department': 'Computer Science',
      'password': 'teacher123',
    },
    {
      'name': 'Prof. Maria Garcia',
      'email': 'm.garcia@university.edu',
      'phone': '+1234567881',
      'enrollmentId': 'TCHR002',
      'department': 'Information Technology',
      'password': 'teacher123',
    },
    {
      'name': 'Dr. James Wilson',
      'email': 'j.wilson@university.edu',
      'phone': '+1234567882',
      'enrollmentId': 'TCHR003',
      'department': 'Electronics Engineering',
      'password': 'teacher123',
    },
    {
      'name': 'Prof. Lisa Martinez',
      'email': 'l.martinez@university.edu',
      'phone': '+1234567883',
      'enrollmentId': 'TCHR004',
      'department': 'Mathematics',
      'password': 'teacher123',
    },
  ];

  static Future<void> addAllTestData(BuildContext context) async {
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
              Text('Adding test data...'),
            ],
          ),
        ),
      );

      // Add students
      for (final student in _testStudents) {
        await _addStudent(student);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Add teachers
      for (final teacher in _testTeachers) {
        await _addTeacher(teacher);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success dialog with credentials
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Test Data Added Successfully!'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Student Credentials:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  ..._testStudents.map((student) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${student['name']} (${student['enrollmentId']})', 
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Email: ${student['email']}'),
                          Text('Password: ${student['password']}'),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 20),
                  const Text('Teacher Credentials:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  ..._testTeachers.map((teacher) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${teacher['name']} (${teacher['enrollmentId']})', 
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Email: ${teacher['email']}'),
                          Text('Password: ${teacher['password']}'),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
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
          SnackBar(content: Text('Error adding test data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> _addStudent(Map<String, String> studentData) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final user = User(
      id: id,
      name: studentData['name']!,
      email: studentData['email']!,
      role: 'student',
      enrollmentId: studentData['enrollmentId']!,
      department: studentData['department']!,
      phone: studentData['phone']!,
      profileImage: null,
    );

    await _firebaseService.registerUser(user, studentData['password']!);
    print('Added student: ${studentData['name']}');
  }

  static Future<void> _addTeacher(Map<String, String> teacherData) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final user = User(
      id: id,
      name: teacherData['name']!,
      email: teacherData['email']!,
      role: 'teacher',
      enrollmentId: teacherData['enrollmentId']!,
      department: teacherData['department']!,
      phone: teacherData['phone']!,
      profileImage: null,
    );

    await _firebaseService.registerUser(user, teacherData['password']!);
    print('Added teacher: ${teacherData['name']}');
  }

  static void showTestDataInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Data Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This will add the following test data:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const Text('Students (5):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ..._testStudents.map((student) => Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 4),
                child: Text('• ${student['name']} (${student['enrollmentId']})'),
              )),
              const SizedBox(height: 15),
              const Text('Teachers (4):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ..._testTeachers.map((teacher) => Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 4),
                child: Text('• ${teacher['name']} (${teacher['enrollmentId']})'),
              )),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Default Passwords:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Students: student123'),
                    Text('Teachers: teacher123'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              addAllTestData(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Add Test Data'),
          ),
        ],
      ),
    );
  }
}
