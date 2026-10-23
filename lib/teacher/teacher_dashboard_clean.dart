import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models.dart';
import '../zego_service.dart';
import '../firebase_service.dart';

class TeacherDashboard extends StatefulWidget {
  final User user;

  const TeacherDashboard({super.key, required this.user});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;
  late FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColorDark,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      _showNotifications();
                    },
                  ),
                ],
              ),
              Center(
                child: Text(
                  'ClassLink+',
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Teacher Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: _selectedIndex == 0 ? _buildDashboardContent() : _getPageForIndex(),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton.extended(
        onPressed: () {
          // Generate a quick class session ID and start video conference
          final quickClassId = 'quick_class_${DateTime.now().millisecondsSinceEpoch}';
          ZegoService.startVideoConference(
            context: context,
            conferenceID: quickClassId,
            userName: widget.user.name,
            userID: widget.user.id,
            role: widget.user.role,
            userEmail: widget.user.email,
          );
        },
        icon: const Icon(Icons.video_call),
        label: Text(
          'Start Class',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 5,
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 3) {
            // Logout action
            _showLogoutDialog();
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _getPageForIndex() {
    switch (_selectedIndex) {
      case 1:
        return _buildAnalyticsContent();
      case 2:
        return _buildStudentsContent();
      case 3:
        return _buildDashboardContent();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('attendance').onValue,
      builder: (context, attendanceSnapshot) {
        return StreamBuilder(
          stream: FirebaseDatabase.instance.ref('active_sessions').onValue,
          builder: (context, sessionsSnapshot) {
            return StreamBuilder(
              stream: FirebaseDatabase.instance.ref('users').orderByChild('role').equalTo('student').onValue,
              builder: (context, studentsSnapshot) {
                // Calculate analytics data
                int totalSessions = 0;
                int totalStudents = 0;
                int presentCount = 0;
                int absentCount = 0;
                int activeStudentsCount = 0;

                // Process attendance data
                if (attendanceSnapshot.data?.snapshot.value != null) {
                  final attendance = Map<String, dynamic>.from(attendanceSnapshot.data!.snapshot.value as Map);
                  attendance.forEach((key, value) {
                    if (value['teacherId'] == widget.user.id) {
                      totalSessions++;
                      if (value['status'] == 'present') {
                        presentCount++;
                      } else {
                        absentCount++;
                      }
                    }
                  });
                }

                // Process active sessions
                if (sessionsSnapshot.data?.snapshot.value != null) {
                  final activeSessions = Map<String, dynamic>.from(sessionsSnapshot.data!.snapshot.value as Map);
                  activeSessions.forEach((sessionId, sessionData) {
                    if (sessionData['participants'] != null) {
                      final participants = Map<String, dynamic>.from(sessionData['participants']);
                      participants.forEach((studentId, participantData) {
                        if (participantData['status'] == 'active') {
                          activeStudentsCount++;
                        }
                      });
                    }
                  });
                }

                // Process total students
                if (studentsSnapshot.data?.snapshot.value != null) {
                  final students = Map<String, dynamic>.from(studentsSnapshot.data!.snapshot.value as Map);
                  totalStudents = students.length;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with PDF Export
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Analytics Dashboard',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _generateAnalyticsPDF(
                              totalSessions,
                              totalStudents,
                              presentCount,
                              absentCount,
                              activeStudentsCount,
                            ),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Export PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Analytics Cards
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height - 200,
                        ),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.3,
                          children: [
                            _buildAnalyticsCard(
                              'Total Sessions',
                              totalSessions.toString(),
                              Icons.class_,
                              Colors.blue,
                            ),
                            _buildAnalyticsCard(
                              'Total Students',
                              totalStudents.toString(),
                              Icons.group,
                              Colors.green,
                            ),
                            _buildAnalyticsCard(
                              'Present Today',
                              presentCount.toString(),
                              Icons.check_circle,
                              Colors.orange,
                            ),
                            _buildAnalyticsCard(
                              'Absent Today',
                              absentCount.toString(),
                              Icons.cancel,
                              Colors.red,
                            ),
                            _buildAnalyticsCard(
                              'Active Now',
                              activeStudentsCount.toString(),
                              Icons.online_prediction,
                              Colors.purple,
                            ),
                            _buildAnalyticsCard(
                              'Attendance Rate',
                              totalSessions > 0 
                                  ? '${((presentCount / totalSessions) * 100).toStringAsFixed(1)}%'
                                  : '0%',
                              Icons.trending_up,
                              Colors.teal,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStudentsContent() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('users').orderByChild('role').equalTo('student').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Center(
            child: Text(
              'No students found',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          );
        }

        final students = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final studentsList = students.entries.map((entry) {
          final studentData = Map<String, dynamic>.from(entry.value);
          return {
            'id': entry.key,
            'name': studentData['name'] ?? 'Unknown',
            'email': studentData['email'] ?? 'No email',
            'enrollmentId': studentData['enrollmentId'] ?? 'N/A',
            'role': studentData['role'] ?? 'student',
          };
        }).toList();

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registered Students',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${studentsList.length} Total',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Students List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: studentsList.length,
                itemBuilder: (context, index) {
                  final student = studentsList[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              Icons.person,
                              color: Theme.of(context).primaryColor,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          
                          // Student Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student['name'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'ID: ${student['enrollmentId']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  student['email'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Active',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateAnalyticsPDF(
    int totalSessions,
    int totalStudents,
    int presentCount,
    int absentCount,
    int activeStudentsCount,
  ) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Teacher Analytics Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated on: ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Teacher: ${widget.user.name} (${widget.user.enrollmentId})',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 30),
              
              // Analytics Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary Statistics',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text('Total Sessions: $totalSessions'),
                        ),
                        pw.Expanded(
                          child: pw.Text('Total Students: $totalStudents'),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text('Present Today: $presentCount'),
                        ),
                        pw.Expanded(
                          child: pw.Text('Absent Today: $absentCount'),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('Active Now: $activeStudentsCount'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    try {
      // Use printing package to save to Downloads folder
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'analytics_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF report generated. Choose your download location.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              },
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    final notifications = [
                      {
                        'title': 'Class Reminder',
                        'message': 'Your Mathematics class starts in 15 minutes',
                        'time': '10 min ago',
                        'icon': Icons.alarm,
                        'color': Colors.blue,
                      },
                      {
                        'title': 'Attendance Updated',
                        'message': 'John Doe marked present in Physics class',
                        'time': '1 hour ago',
                        'icon': Icons.check_circle,
                        'color': Colors.green,
                      },
                      {
                        'title': 'New Student Joined',
                        'message': 'Alice Brown joined your Computer Science class',
                        'time': '2 hours ago',
                        'icon': Icons.person_add,
                        'color': Colors.purple,
                      },
                    ];
                    final notification = notifications[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: (notification['color'] as Color?)?.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              notification['icon'] as IconData,
                              color: notification['color'] as Color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['title'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  notification['message'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            notification['time'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
