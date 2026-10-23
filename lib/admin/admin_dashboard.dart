import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../firebase_service.dart';
import 'test_data_generator.dart';
import 'add_teacher_test_data.dart';

class AdminDashboard extends StatefulWidget {
  final User user;

  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedIndex = 0;
  List<User> _students = [];
  List<User> _teachers = [];
  List<ClassSession> _allClasses = [];
  List<ClassSession> _pastSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load students
      _firebaseService.getAllStudents().listen((students) {
        if (mounted) {
          setState(() => _students = students);
        }
      });

      // Load teachers
      _firebaseService.database
          .child('users')
          .orderByChild('role')
          .equalTo('teacher')
          .onValue
          .listen((event) {
        if (event.snapshot.value != null && mounted) {
          final Map<dynamic, dynamic> teachersData = 
              event.snapshot.value as Map<dynamic, dynamic>;
          _teachers = teachersData.values
              .map((t) => User.fromMap(Map<String, dynamic>.from(t as Map<dynamic, dynamic>)))
              .toList();
          setState(() {});
        }
      });

      // Load all classes (both scheduled and past)
      _firebaseService.database
          .child('scheduled_classes')
          .onValue
          .listen((event) {
        if (event.snapshot.value != null && mounted) {
          try {
            final Map<dynamic, dynamic> classesData = 
                event.snapshot.value as Map<dynamic, dynamic>;
            final List<ClassSession> allClasses = [];
            
            classesData.forEach((key, value) {
              try {
                final map = Map<String, dynamic>.from(value as Map<dynamic, dynamic>);
                
                // Parse start and end times
                DateTime? startTime;
                DateTime? endTime;
                
                if (map['startTime'] != null && map['endTime'] != null) {
                  startTime = DateTime.parse(map['startTime']);
                  endTime = DateTime.parse(map['endTime']);
                } else if (map['scheduledDateTime'] != null) {
                  final ms = map['scheduledDateTime'];
                  final scheduledMs = ms is int ? ms : int.tryParse(ms.toString());
                  if (scheduledMs != null) {
                    startTime = DateTime.fromMillisecondsSinceEpoch(scheduledMs);
                    final durationMins = map['duration'] ?? map['lengthMinutes'] ?? 2;
                    final mins = durationMins is int ? durationMins : int.tryParse(durationMins.toString()) ?? 2;
                    endTime = startTime.add(Duration(minutes: mins));
                  }
                }
                
                if (startTime != null && endTime != null) {
                  final classSession = ClassSession(
                    id: map['id'] ?? key.toString(),
                    title: map['title'] ?? 'Untitled Class',
                    teacherId: map['teacherId'] ?? '',
                    teacherName: map['teacherName'] ?? '',
                    subject: map['subject'] ?? '',
                    startTime: startTime,
                    endTime: endTime,
                    status: map['status'] ?? 'scheduled',
                    joinCode: map['joinCode'] ?? map['join_code'] ?? '',
                  );
                  allClasses.add(classSession);
                }
              } catch (e) {
                print('Error parsing class $key: $e');
              }
            });
            
            // Sort by start time (newest first)
            allClasses.sort((a, b) => b.startTime.compareTo(a.startTime));
            
            final now = DateTime.now();
            if (mounted) {
              setState(() {
                // Scheduled classes are those that haven't ended yet
                _allClasses = allClasses.where((c) => c.endTime.isAfter(now)).toList();
                // Past sessions are those that have already ended
                _pastSessions = allClasses.where((c) => c.endTime.isBefore(now) || c.endTime.isAtSameMomentAs(now)).toList();
              });
            }
          } catch (e) {
            print('Error processing classes data: $e');
          }
        }
      });
    } catch (e) {
      print('Error loading admin data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await _showConfirmDialog(
      'Delete User',
      'Are you sure you want to delete ${user.name}? This action cannot be undone.',
    );
    
    if (confirmed == true) {
      try {
        await _firebaseService.database.child('users/${user.id}').remove();
        _showSnackBar('User deleted successfully', Colors.green);
        _loadData();
      } catch (e) {
        _showSnackBar('Error deleting user: $e', Colors.red);
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
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
                  'Admin Dashboard',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
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
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: 'Classes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    // Show notifications dialog or panel
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'No new notifications',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildUsersManagement();
      case 2:
        return _buildClassesManagement();
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Overview',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard('Total Students', _students.length.toString(), Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard('Total Teachers', _teachers.length.toString(), Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Scheduled Classes', _allClasses.length.toString(), Colors.orange),
              const SizedBox(width: 16),
              _buildStatCard('Past Sessions', _pastSessions.length.toString(), Colors.purple),
            ],
          ),
          const SizedBox(height: 24),
          
          Text(
            'Recent Activity',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: Text('System Status: Active'),
              subtitle: Text('All services are running normally'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                _getIconForTitle(title),
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    if (title.contains('Students')) return Icons.school;
    if (title.contains('Teachers')) return Icons.person;
    if (title.contains('Scheduled')) return Icons.schedule;
    if (title.contains('Past')) return Icons.history;
    return Icons.dashboard;
  }

  Widget _buildUsersManagement() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Students'),
              Tab(text: 'Teachers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUsersList(_students, 'Students'),
                _buildUsersList(_teachers, 'Teachers'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<User> users, String userType) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          'No $userType found',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: userType == 'Students' ? Colors.blue : Colors.green,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              user.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                if (user.department != null) Text('Dept: ${user.department}'),
                Text('ID: ${user.enrollmentId}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteUser(user);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassesManagement() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Scheduled Classes'),
              Tab(text: 'Past Sessions'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildClassesList(_allClasses, 'Scheduled'),
                _buildClassesList(_pastSessions, 'Past'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesList(List<ClassSession> classes, String type) {
    if (classes.isEmpty) {
      return Center(
        child: Text(
          'No $type classes found',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classSession = classes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: type == 'Scheduled' ? Colors.orange : Colors.purple,
              child: Icon(
                type == 'Scheduled' ? Icons.schedule : Icons.history,
                color: Colors.white,
              ),
            ),
            title: Text(
              classSession.title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Teacher: ${classSession.teacherName}'),
                Text('Subject: ${classSession.subject}'),
                Text('Start: ${_formatDateTime(classSession.startTime)}'),
                Text('End: ${_formatDateTime(classSession.endTime)}'),
                Text('Status: ${classSession.status}'),
                Text('Join Code: ${classSession.joinCode}'),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
