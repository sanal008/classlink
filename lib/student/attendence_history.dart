import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../firebase_service.dart';

class AttendanceHistoryPage extends StatefulWidget {
  final User user;

  const AttendanceHistoryPage({super.key, required this.user});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _loading = true;
  List<Attendance> _attendanceList = [];
  Map<String, ClassSession> _classSessions = {};

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
  }

  Future<void> _loadAttendanceHistory() async {
    try {
      // Load attendance records
      _firebaseService.getStudentAttendance(widget.user.id).listen((attendanceList) {
        if (mounted) {
          setState(() {
            _attendanceList = attendanceList;
            _loading = false;
          });
          // Load class session details for each attendance record
          _loadClassSessionDetails(attendanceList);
        }
      });
    } catch (e) {
      print('Error loading attendance history: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadClassSessionDetails(List<Attendance> attendanceList) async {
    for (var attendance in attendanceList) {
      if (attendance.classId.isNotEmpty && !_classSessions.containsKey(attendance.classId)) {
        print('Loading session details for classId: ${attendance.classId}'); // Debug
        try {
          // Get class session details from Firebase
          final classSession = await _firebaseService.getClassSession(attendance.classId);
          print('Found session: ${classSession?.title}'); // Debug
          if (classSession != null && mounted) {
            setState(() {
              _classSessions[attendance.classId] = classSession!;
            });
          }
        } catch (e) {
          print('Error loading class session ${attendance.classId}: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Attendance History', style: GoogleFonts.poppins()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _attendanceList.isEmpty
              ? _buildEmptyState()
              : _buildAttendanceList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No attendance history available',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Attendance records will appear here when available.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    // Group attendance records by classId to show one card per session
    Map<String, List<Attendance>> groupedAttendance = {};
    for (var attendance in _attendanceList) {
      if (!groupedAttendance.containsKey(attendance.classId)) {
        groupedAttendance[attendance.classId] = [];
      }
      groupedAttendance[attendance.classId]!.add(attendance);
    }
    
    // Sort groups by most recent date
    final sortedEntries = groupedAttendance.entries.toList()
      ..sort((a, b) {
        final dateA = a.value.isNotEmpty ? a.value.first.date : DateTime(2000);
        final dateB = b.value.isNotEmpty ? b.value.first.date : DateTime(2000);
        return dateB.compareTo(dateA);
      });
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final classId = entry.key;
        final attendanceRecords = entry.value;
        
        // Get the most recent attendance record for this session
        final latestAttendance = attendanceRecords.first;
        
        return _buildSessionCard(classId, latestAttendance);
      },
    );
  }

  Widget _buildSessionCard(String classId, Attendance attendance) {
    // Get class session details if available
    final classSession = _classSessions[attendance.classId];
    final sessionTitle = classSession?.title ?? 'Class Session';
    final sessionDescription = classSession?.subject ?? '';
    final teacherName = classSession?.teacherName ?? 'Teacher';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
        border: Border(
          left: BorderSide(
            color: attendance.status == 'present'
                ? Colors.green
                : Colors.red,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sessionTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sessionDescription.isNotEmpty ? sessionDescription : 'Class Session',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: attendance.status == 'present'
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    attendance.status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: attendance.status == 'present'
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Session details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    Icons.person,
                    'Teacher',
                    teacherName,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Date',
                    _formatDate(attendance.date),
                  ),
                  if (attendance.joinTime != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.login,
                      'Joined',
                      _formatTime(attendance.joinTime!),
                    ),
                  ],
                  if (attendance.leaveTime != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.logout,
                      'Left',
                      _formatTime(attendance.leaveTime!),
                    ),
                  ],
                  if (attendance.duration.inMinutes > 0) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.schedule,
                      'Duration',
                      _formatDuration(attendance.duration),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours h ${minutes} m';
    }
    return '$minutes minutes';
  }
}

