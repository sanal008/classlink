import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../firebase_analyzer.dart';
import '../models.dart';
import '../zego_service.dart';
import '../firebase_service.dart';
import '../whiteboard_service.dart';

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
      floatingActionButton: null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 4) {
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
            icon: Icon(Icons.note),
            label: 'Lecture Notes',
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
        return _buildLectureNotesContent();
      case 4:
        return _buildDashboardContent();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          _buildWelcomeHeader(),
          const SizedBox(height: 30),

          // Quick Stats
          _buildQuickStats(),
          const SizedBox(height: 30),

          // Action Cards
          _buildActionCards(),
          const SizedBox(height: 30),

          // Firebase Analysis Button (Debug)
          _buildFirebaseAnalysisButton(),
          const SizedBox(height: 30),

          // Recent Classes
          _buildRecentClasses(),
          const SizedBox(height: 30),

          // Upcoming Classes
          _buildUpcomingClasses(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${widget.user.name}!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Ready for today\'s classes?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('active_sessions').onValue,
      builder: (context, snapshot) {
        int activeClasses = 0;
        int totalStudents = 0;

        if (snapshot.data?.snapshot.value != null) {
          final sessions = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          activeClasses = sessions.length;
          sessions.forEach((key, value) {
            if (value['participants'] != null) {
              totalStudents += (value['participants'] as Map).length;
            }
          });
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Classes',
                activeClasses.toString(),
                Icons.class_,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                'Total Students',
                totalStudents.toString(),
                Icons.group,
                Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
    );
  }

  Widget _buildFirebaseAnalysisButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          print('\n🔍 STARTING COMPLETE FIREBASE DATABASE ANALYSIS...');
          final analyzer = FirebaseAnalyzer();
          await analyzer.analyzeCompleteDatabase();
        },
        icon: const Icon(Icons.search, color: Colors.white),
        label: Text(
          '🔍 Analyze Firebase Database',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCards() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('scheduled_classes').onValue,
      builder: (context, snapshot) {
        bool hasStartableClass = false;
        
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final scheduledClasses = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final now = DateTime.now().millisecondsSinceEpoch;
          
          hasStartableClass = scheduledClasses.entries.any((entry) {
            final classData = Map<String, dynamic>.from(entry.value);
            final scheduledTime = classData['scheduledDateTime'] as int;
            final teacherId = classData['teacherId'] as String?;
            final status = classData['status'] as String?;
            final title = classData['title'] as String?;
            
            return scheduledTime > now &&
                status == 'scheduled' &&
                teacherId == widget.user.id &&
                title != null && 
                title.isNotEmpty && 
                title != 'Untitled Class' &&
                _canStartClass(scheduledTime);
          });
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.2,
              children: [
                if (hasStartableClass)
                  _buildActionCard(
                    'Start Class',
                    'Begin a new video conference',
                    Icons.video_call,
                    Colors.blue,
                    () {
                      final classId = 'class_${DateTime.now().millisecondsSinceEpoch}';
                      ZegoService.startVideoConference(
                        context: context,
                        conferenceID: classId,
                        userName: widget.user.name,
                        userID: widget.user.id,
                        role: widget.user.role,
                        userEmail: widget.user.email,
                      );
                    },
                  ),
                _buildActionCard(
                  'View Analytics',
                  'Check attendance and performance',
                  Icons.analytics,
                  Colors.green,
                  () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
                _buildActionCard(
                  'View Students',
                  'View student list',
                  Icons.group,
                  Colors.orange,
                  () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                ),
                _buildActionCard(
                  'Schedule Class',
                  'Plan upcoming sessions',
                  Icons.schedule,
                  Colors.purple,
                  () {
                    _showScheduleDialog();
                  },
                ),
              ].where((card) => card != null).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentClasses() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('active_sessions').limitToLast(5).onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Classes',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'No recent classes',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final sessions = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final sessionsList = sessions.entries.map((entry) {
          final sessionData = Map<String, dynamic>.from(entry.value);
          final title = sessionData['title'] as String?;
          // Skip classes without proper titles
          if (title == null || title.isEmpty || title == 'Untitled Class') {
            return null;
          }
          return {
            'id': entry.key,
            'title': title,
            'timestamp': sessionData['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
            'participants': sessionData['participants']?.length ?? 0,
          };
        }).where((session) => session != null).cast<Map<String, dynamic>>().toList()
          ..sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

        if (sessionsList.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Classes',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'No recent classes',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Classes',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              ...sessionsList.take(3).map((session) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.class_,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session['title'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${session['participants']} participants',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatTimestamp(session['timestamp']),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcomingClasses() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('scheduled_classes').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Classes',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No upcoming classes scheduled',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _showScheduleDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Schedule Class'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final scheduledClasses = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final now = DateTime.now().millisecondsSinceEpoch;

        print('Teacher ID: ${widget.user.id}');
        print('Total scheduled classes: ${scheduledClasses.length}');

        final upcomingClasses = scheduledClasses.entries.where((entry) {
          final classData = Map<String, dynamic>.from(entry.value);
          final scheduledTime = classData['scheduledDateTime'] as int;
          final teacherId = classData['teacherId'] as String?;
          final status = classData['status'] as String?;
          final title = classData['title'] as String?;

          print('Class: ${classData['title']}, Teacher: $teacherId, Status: $status, Time: $scheduledTime');

          return scheduledTime > now &&
              status == 'scheduled' &&
              teacherId == widget.user.id &&
              title != null &&
              title.isNotEmpty &&
              title != 'Untitled Class';
        }).map((entry) {
          final classData = Map<String, dynamic>.from(entry.value);
          return {
            'id': entry.key,
            'title': classData['title'],
            'description': classData['description'] ?? '',
            'scheduledDateTime': classData['scheduledDateTime'],
          };
        }).toList()
          ..sort((a, b) => (a['scheduledDateTime'] as int).compareTo(b['scheduledDateTime'] as int));

        print('Upcoming classes for this teacher: ${upcomingClasses.length}');

        final allClasses = scheduledClasses.entries.map((entry) {
          final classData = Map<String, dynamic>.from(entry.value);
          final title = classData['title'] as String?;
          // Skip classes without proper titles
          if (title == null || title.isEmpty || title == 'Untitled Class') {
            return null;
          }
          return {
            'id': entry.key,
            'title': title,
            'description': classData['description'] ?? '',
            'scheduledDateTime': classData['scheduledDateTime'],
            'teacherId': classData['teacherId'] ?? 'unknown',
            'status': classData['status'] ?? 'unknown',
            'isCurrentTeacher': classData['teacherId'] == widget.user.id,
          };
        }).where((classInfo) => classInfo != null).cast<Map<String, dynamic>>().toList()
          ..sort((a, b) => (a['scheduledDateTime'] as int).compareTo(b['scheduledDateTime'] as int));

        print('All classes: ${allClasses.length}');

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Classes',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (allClasses.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No classes found',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...allClasses.map((classInfo) => Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: InkWell(
                        onTap: () {
                          print('Card tapped: ${classInfo['id']}');
                          _showClassDetailsDialog(classInfo);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(
                              color: classInfo['isCurrentTeacher']
                                  ? Colors.blue.withOpacity(0.12)
                                  : Colors.grey.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: classInfo['isCurrentTeacher']
                                      ? LinearGradient(colors: [Colors.blue.withOpacity(0.14), Colors.blue.withOpacity(0.06)])
                                      : LinearGradient(colors: [Colors.grey.withOpacity(0.08), Colors.grey.withOpacity(0.04)]),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3)),
                                  ],
                                ),
                                child: Icon(
                                  Icons.schedule,
                                  color: classInfo['isCurrentTeacher'] ? Colors.blue : Colors.grey,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      classInfo['title'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (classInfo['status'] != null && classInfo['status'] != 'unknown')
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (classInfo['status'] == 'scheduled') ? Colors.blue.withOpacity(0.08) : Colors.orange.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              (classInfo['status'] ?? '').toString().toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: (classInfo['status'] == 'scheduled') ? Colors.blue : Colors.orange,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _getTimeUntilClass(classInfo['scheduledDateTime']),
                                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (classInfo['description'].isNotEmpty)
                                      Text(
                                        classInfo['description'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _formatScheduledDateTime(classInfo['scheduledDateTime']),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: classInfo['isCurrentTeacher'] ? Colors.blue : Colors.grey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (classInfo['isCurrentTeacher'])
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 120),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Compact start icon (with tooltip). Disabled when outside start window.
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _canStartClass(classInfo['scheduledDateTime']) ? Colors.green : Colors.grey[200],
                                        ),
                                        child: IconButton(
                                          onPressed: _canStartClass(classInfo['scheduledDateTime'])
                                              ? () => _startScheduledClass(classInfo['id'], classInfo['title'])
                                              : null,
                                          icon: const Icon(Icons.video_call, size: 18),
                                          color: Colors.white,
                                          tooltip: 'Start Class',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Compact reschedule icon shown for past sessions (teacher-only)
                                      if ((classInfo['scheduledDateTime'] as int) < DateTime.now().millisecondsSinceEpoch)
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                          child: IconButton(
                                            onPressed: () => _showRescheduleDialog(
                                              classInfo['id'],
                                              classInfo['scheduledDateTime'],
                                            ),
                                            icon: const Icon(Icons.edit_calendar, size: 18),
                                            color: Colors.white,
                                            tooltip: 'Reschedule',
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'cancel') {
                                            _cancelScheduledClass(classInfo['id']);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'cancel',
                                            child: Text('Cancel Class'),
                                          ),
                                        ],
                                        child: Icon(
                                          Icons.more_vert,
                                          color: Colors.grey[600],
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }

  String _formatScheduledDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final classDate = DateTime(date.year, date.month, date.day);

    if (classDate.isAtSameMomentAs(today)) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (classDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return 'Tomorrow at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  bool _canStartClass(int scheduledDateTime) {
    final now = DateTime.now();
    final classTime = DateTime.fromMillisecondsSinceEpoch(scheduledDateTime);

    final startWindowStart = classTime.subtract(const Duration(minutes: 5));
    final startWindowEnd = classTime.add(const Duration(hours: 1));

    // Start allowed only between (start - 5min) and (start + 1hr)
    return now.isAfter(startWindowStart) && now.isBefore(startWindowEnd);
  }

  String _getTimeUntilClass(int scheduledDateTime) {
    final classTime = DateTime.fromMillisecondsSinceEpoch(scheduledDateTime);
    final now = DateTime.now();
    final endWindow = classTime.add(const Duration(hours: 1));
    final difference = classTime.difference(now);

    if (now.isAfter(endWindow)) {
      return 'Expired';
    } else if (difference.isNegative) {
      return 'Ready to start';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    }
  }

  void _startScheduledClass(String classId, String classTitle) {
    // Fetch the scheduled class details to get the end time
    FirebaseDatabase.instance.ref('scheduled_classes').child(classId).once().then((snapshot) {
      DateTime? scheduledEndTime;
      
      if (snapshot.snapshot.exists) {
        final classData = Map<String, dynamic>.from(snapshot.snapshot.value as Map<dynamic, dynamic>);
        
        // Parse the end time from the class data
        if (classData['endTime'] != null) {
          scheduledEndTime = DateTime.parse(classData['endTime']);
        } else if (classData['scheduledDateTime'] != null) {
          final ms = classData['scheduledDateTime'];
          final scheduledMs = ms is int ? ms : int.tryParse(ms.toString());
          if (scheduledMs != null) {
            final durationMins = classData['duration'] ?? classData['lengthMinutes'] ?? 2;
            final mins = durationMins is int ? durationMins : int.tryParse(durationMins.toString()) ?? 2;
            final startTime = DateTime.fromMillisecondsSinceEpoch(scheduledMs);
            scheduledEndTime = startTime.add(Duration(minutes: mins));
          }
        }
      }
      
      // Create a new active session from the scheduled class
      final sessionData = {
        'title': classTitle,
        'teacherId': widget.user.id,
        'teacherName': widget.user.name,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'active',
        'participants': {},
        'scheduledClassId': classId,
      };

      // Save to active sessions
      FirebaseDatabase.instance.ref('active_sessions').push().set(sessionData).then((_) {
        // Update the scheduled class status to 'ongoing'
        FirebaseDatabase.instance.ref('scheduled_classes').child(classId).update({
          'status': 'ongoing',
          'startedAt': DateTime.now().millisecondsSinceEpoch,
        }).then((_) {
          // Start the video conference - use the classId as conferenceId so students can join the same room
          ZegoService.startVideoConference(
            context: context,
            conferenceID: classId,
            userName: widget.user.name,
            userID: widget.user.id,
            role: widget.user.role,
            userEmail: widget.user.email,
            scheduledEndTime: scheduledEndTime,
          );
        });
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error starting class: $error',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error fetching class details: $error',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _debugScheduledClasses() async {
    print('=== DEBUG: Checking Scheduled Classes ===');
    print('Current Teacher ID: ${widget.user.id}');
    print('Current Teacher Name: ${widget.user.name}');

    try {
      final snapshot = await FirebaseDatabase.instance.ref('scheduled_classes').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        print('Total scheduled classes in Firebase: ${data.length}');

        data.forEach((key, value) {
          final classData = Map<String, dynamic>.from(value);
          print('Class $key:');
          print('  Title: ${classData['title']}');
          print('  Teacher ID: ${classData['teacherId']}');
          print('  Teacher Name: ${classData['teacherName']}');
          print('  Status: ${classData['status']}');
          print('  Scheduled Time: ${classData['scheduledDateTime']}');
          print('  Matches current teacher: ${classData['teacherId'] == widget.user.id}');
          print('---');
        });
      } else {
        print('No scheduled classes found in Firebase');
      }
    } catch (e) {
      print('Error reading scheduled classes: $e');
    }

    // Also test saving a sample class
    print('\n=== Testing Save Function ===');
    final testClassData = {
      'title': 'Test Class ${DateTime.now().millisecondsSinceEpoch}',
      'description': 'This is a test class',
      'scheduledDateTime': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
      'teacherId': widget.user.id,
      'teacherName': widget.user.name,
      'status': 'scheduled',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final result = await FirebaseDatabase.instance.ref('scheduled_classes').push().set(testClassData);
      print('Test class saved successfully');
      print('Test class data: $testClassData');
    } catch (e) {
      print('Error saving test class: $e');
    }
  }

  void _cancelScheduledClass(String classId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Cancel Class',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel this scheduled class?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'No',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseDatabase.instance.ref('scheduled_classes').child(classId).remove().then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Class cancelled successfully',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error cancelling class: $error',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Yes, Cancel',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  void _showScheduleDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Schedule Class',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Class Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 3,
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[600]),
                            const SizedBox(width: 10),
                            Text(
                              selectedDate != null
                                  ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                  : 'Select Date',
                              style: GoogleFonts.poppins(
                                color: selectedDate != null ? Colors.black : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            selectedTime = time;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.grey[600]),
                            const SizedBox(width: 10),
                            Text(
                              selectedTime != null
                                  ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                                  : 'Select Time',
                              style: GoogleFonts.poppins(
                                color: selectedTime != null ? Colors.black : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty && selectedDate != null && selectedTime != null) {
                      _saveScheduledClass(
                        titleController.text,
                        descriptionController.text,
                        selectedDate!,
                        selectedTime!,
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please fill in all required fields',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Schedule',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveScheduledClass(String title, String description, DateTime date, TimeOfDay time) {
    final scheduledDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final classData = {
      'title': title,
      'description': description,
      'scheduledDateTime': scheduledDateTime.millisecondsSinceEpoch,
      'teacherId': widget.user.id,
      'teacherName': widget.user.name,
      'status': 'scheduled',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    print('Saving class data: $classData');

    FirebaseDatabase.instance.ref('scheduled_classes').push().set(classData).then((_) {
      print('Class saved successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Class scheduled successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error scheduling class: $error',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // Show a simple dialog to reschedule an existing class (date + time only)
  void _showRescheduleDialog(String classId, int currentTimestamp) {
    DateTime selectedDate = DateTime.fromMillisecondsSinceEpoch(currentTimestamp);
    TimeOfDay selectedTime = TimeOfDay(hour: selectedDate.hour, minute: selectedDate.minute);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Reschedule Class',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[600]),
                            const SizedBox(width: 10),
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() {
                            selectedTime = time;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.grey[600]),
                            const SizedBox(width: 10),
                            Text(
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
                ElevatedButton(
                  onPressed: () async {
                    final updatedDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    final updatedMillis = updatedDateTime.millisecondsSinceEpoch;

                    try {
                      await FirebaseDatabase.instance
                          .ref('scheduled_classes')
                          .child(classId)
                          .update({
                        'scheduledDateTime': updatedMillis,
                        'status': 'scheduled',
                      });

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Class rescheduled',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error rescheduling class: $e',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Update',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show a detailed popup for a scheduled class (tap the card)
  void _showClassDetailsDialog(Map<String, dynamic> classInfo) {
    print('Opening details for: ${classInfo['id']}');
    showDialog(
      context: context,
      builder: (context) {
        final isCurrentTeacher = classInfo['isCurrentTeacher'] == true;
        final scheduledTs = classInfo['scheduledDateTime'] as int;
        return AlertDialog(
          title: Text(
            classInfo['title'] ?? 'Class Details',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((classInfo['description'] ?? '').isNotEmpty) ...[
                  Text(
                    classInfo['description'],
                    style: GoogleFonts.poppins(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatScheduledDateTime(scheduledTs),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Teacher: ${classInfo['teacherId']}',
                  style: GoogleFonts.poppins(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${classInfo['status'] ?? 'unknown'}',
                  style: GoogleFonts.poppins(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          actions: [
            if (isCurrentTeacher && scheduledTs > DateTime.now().millisecondsSinceEpoch)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _startScheduledClass(classInfo['id'], classInfo['title']);
                },
                icon: const Icon(Icons.video_call, size: 16),
                label: const Text('Start', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            if (isCurrentTeacher)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showRescheduleDialog(classInfo['id'], scheduledTs);
                },
                icon: const Icon(Icons.edit_calendar, size: 16),
                label: const Text('Reschedule', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            if (isCurrentTeacher)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelScheduledClass(classInfo['id']);
                },
                child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildDetailedReportsSection(),
    );
  }

  Widget _buildDetailedReportsSection() {
    return FutureBuilder(
      future: _firebaseService.getSessionReports(widget.user.id, widget.user.name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || (snapshot.data! as List).isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.assessment,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Session Reports Available',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start conducting classes to see detailed attendance reports here.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final sessionReports = snapshot.data! as List<Map<String, dynamic>>;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detailed Session Reports',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _generateDetailedPDF(sessionReports),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: Text(
                      'Generate PDF',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Summary Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat(
                      'Total Sessions',
                      sessionReports.length.toString(),
                      Icons.class_,
                      Colors.blue,
                    ),
                    _buildSummaryStat(
                      'Avg Attendance',
                      '${(sessionReports.fold<double>(0, (sum, session) => sum + (double.tryParse(session['attendanceRate']?.toString().replaceAll('%', '') ?? '0') ?? 0)) / sessionReports.length).toStringAsFixed(1)}%',
                      Icons.people,
                      Colors.green,
                    ),
                    _buildSummaryStat(
                      'Active Sessions',
                      sessionReports.where((session) => session['isActive'] == true).length.toString(),
                      Icons.video_call,
                      Colors.red,
                    ),
                  ],
                ),
              ),
              
              // Detailed Session List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sessionReports.length,
                itemBuilder: (context, index) {
                  final session = sessionReports[index];
                  final isActive = session['isActive'] == true;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isActive ? Colors.green[300]! : Colors.grey[200]!,
                        width: isActive ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green[100] : Colors.blue[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isActive ? Icons.video_call : Icons.class_,
                          color: isActive ? Colors.green : Colors.blue,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        session['className']?.toString() ?? 'Unknown Class',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session['subject']?.toString() ?? 'Unknown Subject',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green[100] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isActive ? 'LIVE' : _formatDate(session['date']?.toString() ?? ''),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? Colors.green[800] : Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${session['presentCount']}/${session['totalStudents']} Present',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getAttendanceColor(session['attendanceRate'].toString()).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  session['attendanceRate']?.toString() ?? '0%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _getAttendanceColor(session['attendanceRate'].toString()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student Details',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Student List
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: (session['studentDetails'] as List).length,
                                itemBuilder: (context, studentIndex) {
                                  final student = (session['studentDetails'] as List)[studentIndex] as Map<String, dynamic>;
                                  final studentName = student['studentName']?.toString() ?? 'Unknown';
                                  final status = student['status']?.toString() ?? 'unknown';
                                  final joinTime = student['joinTime']?.toString() ?? '';
                                  final leaveTime = student['leaveTime']?.toString() ?? '';
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: status == 'present' || status == 'active' 
                                          ? Colors.green[50]
                                          : Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: status == 'present' || status == 'active'
                                            ? Colors.green[200]!
                                            : Colors.red[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: status == 'present' || status == 'active'
                                                ? Colors.green
                                                : Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                studentName,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              if (joinTime.isNotEmpty)
                                                Text(
                                                  'Joined: ${_formatTime(joinTime)}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: status == 'present' || status == 'active'
                                                ? Colors.green
                                                : Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryStat(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String timeString) {
    try {
      final time = DateTime.parse(timeString);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeString;
    }
  }

  Color _getAttendanceColor(String attendanceRate) {
    try {
      final rate = double.tryParse(attendanceRate.replaceAll('%', '')) ?? 0;
      if (rate >= 80) return Colors.green;
      if (rate >= 60) return Colors.orange;
      return Colors.red;
    } catch (e) {
      return Colors.grey;
    }
  }

  Future<void> _generateDetailedPDF(List<Map<String, dynamic>> sessionReports) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Detailed Session Reports',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              
              pw.Text(
                'Teacher: ${widget.user.name} (${widget.user.enrollmentId})',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Generated: ${DateTime.now().toString()}',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 30),
              
              // Summary Statistics
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
                          child: pw.Text('Total Sessions: ${sessionReports.length}'),
                        ),
                        pw.Expanded(
                          child: pw.Text('Total Students: ${sessionReports.fold<int>(0, (sum, session) => sum + (session['totalStudents'] as int))}'),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text('Present: ${sessionReports.fold<int>(0, (sum, session) => sum + (session['presentCount'] as int))}'),
                        ),
                        pw.Expanded(
                          child: pw.Text('Absent: ${sessionReports.fold<int>(0, (sum, session) => sum + (session['absentCount'] as int))}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Session Details
              pw.Text(
                'Session Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              
              ...sessionReports.map((session) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      session['className']?.toString() ?? 'Unknown Class',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Subject: ${session['subject']?.toString() ?? 'Unknown Subject'}',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Date: ${_formatDate(session['date']?.toString() ?? '')}',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Attendance: ${session['presentCount']}/${session['totalStudents']} (${session['attendanceRate']})',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 8),
                    
                    // Student List
                    pw.Text(
                      'Students:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    
                    ...((session['studentDetails'] as List?) ?? []).map((student) {
                      final studentData = student as Map<String, dynamic>;
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(left: 10, bottom: 3),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                studentData['studentName']?.toString() ?? 'Unknown',
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            pw.Container(
                              width: 40,
                              child: pw.Text(
                                studentData['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              )).toList(),
            ],
          );
        },
      ),
    );

    try {
      // Use printing package to save to Downloads folder
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'detailed_session_reports_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Detailed PDF report generated. Choose your download location.'),
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

  Widget _buildStudentsContent() {
    return SingleChildScrollView(
      child: FutureBuilder(
        future: FirebaseDatabase.instance.ref('users').orderByChild('role').equalTo('student').once(),
        builder: (context, snapshot) {
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
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                          offset: const Offset(0, 2),
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildLectureNotesContent() {
    return SingleChildScrollView(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: WhiteboardService.getTeacherWhiteboards(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading lecture notes',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final whiteboards = snapshot.data ?? [];

          if (whiteboards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Lecture Notes Found',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your whiteboard notes will appear here',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: whiteboards.length,
              itemBuilder: (context, index) {
                final whiteboard = whiteboards[index];
                return _buildWhiteboardCard(whiteboard);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildWhiteboardCard(Map<String, dynamic> whiteboard) {
    final studentId = whiteboard['studentId'] as String? ?? 'Unknown';
    final studentName = whiteboard['studentName'] as String? ?? 'Unknown Student';
    final sessionName = whiteboard['sessionName'] as String? ?? 'Untitled Session';
    final sessionId = whiteboard['sessionId'] as String? ?? 'Unknown';
    final extractedText = whiteboard['extractedText'] as String? ?? 'No text available';
    final timestamp = whiteboard['timestamp'] as int? ?? 0;
    final createdAt = whiteboard['createdAt'] as String? ?? '';

    DateTime? createdDate;
    try {
      createdDate = DateTime.parse(createdAt);
    } catch (e) {
      createdDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    // Use the studentName directly from the data
    // No need to check if it's teacher since the data already contains the correct student name
    final displayName = studentName;

    return _buildWhiteboardCardContent(
      studentId: studentId,
      studentName: displayName,
      sessionName: sessionName,
      sessionId: sessionId,
      extractedText: extractedText,
      timestamp: timestamp,
      createdDate: createdDate,
    );
  }

  Future<String> _fetchStudentName(String studentId) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$studentId/name')
          .once();
      
      if (snapshot.snapshot.exists) {
        return snapshot.snapshot.value?.toString() ?? 'Unknown Student';
      }
      return 'Unknown Student';
    } catch (e) {
      print('Error fetching student name: $e');
      return 'Unknown Student';
    }
  }

  Widget _buildWhiteboardCardContent({
    required String studentId,
    required String studentName,
    required String sessionName,
    required String sessionId,
    required String extractedText,
    required int timestamp,
    required DateTime? createdDate,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.note_alt,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          sessionName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    studentName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateForPDF(createdDate),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Extracted Content:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    extractedText,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _copyToClipboard(extractedText);
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text(
                        'Copy',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        _downloadWhiteboard(extractedText, sessionName);
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: Text(
                        'Download',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        _deleteWhiteboard(studentId, sessionId, timestamp);
                      },
                      icon: const Icon(Icons.delete, size: 16),
                      label: Text(
                        'Delete',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateForPDF(DateTime? date) {
    if (date == null) return 'Unknown date';
    
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Text copied to clipboard',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteWhiteboard(String studentId, String sessionId, int timestamp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Lecture Note',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this lecture note? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await WhiteboardService.deleteWhiteboard(
                studentId,
                sessionId,
                timestamp.toString(),
              );
              
              if (!mounted) return; // Check if widget is still mounted
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Lecture note deleted successfully',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() {});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to delete lecture note',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadWhiteboard(String content, String sessionName) async {
    try {
      // Get the directory for downloads
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        _showSnackBar('Downloads directory not accessible', Colors.red);
        return;
      }

      // Create filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'whiteboard_${sessionName.replaceAll(' ', '_')}_$timestamp.txt';
      final filePath = '${directory.path}/$fileName';

      // Write content to file
      final file = File(filePath);
      await file.writeAsString(content);

      _showSnackBar('Whiteboard content downloaded to $fileName', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to download: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
