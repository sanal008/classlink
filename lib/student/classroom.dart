import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../zego_service.dart';
import '../attendance_service.dart';

class StudentClassroom extends StatefulWidget {
  final ClassSession classSession;
  final User user;

  const StudentClassroom({
    super.key,
    required this.classSession,
    required this.user,
  });

  @override
  State<StudentClassroom> createState() => _StudentClassroomState();
}

class _StudentClassroomState extends State<StudentClassroom> {
  bool _isJoined = false;
  bool _micMuted = false;
  bool _cameraOff = false;
  bool _handRaised = false;
  Duration _classDuration = Duration.zero;
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _startClass();
  }

  void _startClass() async {
    setState(() {
      _isJoined = true;
    });
    
    // Track attendance when student joins the class
    try {
      await _attendanceService.onStudentJoin(
        classId: widget.classSession.id,
        studentId: widget.user.id,
        studentName: widget.user.name,
      );
    } catch (e) {
      print('Error tracking student join: $e');
    }
    
    // Simulate class timer
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _classDuration = const Duration(minutes: 45);
        });
      }
    });
  }

  void _toggleMic() {
    setState(() {
      _micMuted = !_micMuted;
    });
  }

  void _toggleCamera() {
    setState(() {
      _cameraOff = !_cameraOff;
    });
  }

  void _toggleHandRaise() {
    setState(() {
      _handRaised = !_handRaised;
    });
  }

  void _leaveClass() async {
    // Track attendance when student leaves the class
    try {
      await _attendanceService.onStudentLeave(
        classId: widget.classSession.id,
        studentId: widget.user.id,
        studentName: widget.user.name,
      );
    } catch (e) {
      print('Error tracking student leave: $e');
    }
    
    Navigator.pop(context);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            // Classroom Header
            _buildClassroomHeader(),
            
            // Main Classroom Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Teacher Video and Smart Board
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Teacher Video Feed
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.videocam_off,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Teacher Camera',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[400],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Live feed will appear here',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Smart Board Placeholder
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.smart_screen,
                                    size: 50,
                                    color: Colors.blue[300],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Interactive Smart Board',
                                    style: GoogleFonts.poppins(
                                      color: Colors.blue[300],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Whiteboard and screen sharing',
                                    style: GoogleFonts.poppins(
                                      color: Colors.blue[200],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Right Panel - Student Preview & Controls
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          // Student Self Preview
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _cameraOff ? Icons.videocam_off : Icons.videocam,
                                    size: 50,
                                    color: _cameraOff ? Colors.red[300] : Colors.green[300],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Your Camera',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[300],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _cameraOff ? 'OFF' : 'LIVE',
                                    style: GoogleFonts.poppins(
                                      color: _cameraOff ? Colors.red[300] : Colors.green[300],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Attendance Status
                          _buildAttendanceStatus(),
                          const SizedBox(height: 16),
                          
                          // Classroom Info
                          _buildClassInfo(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Control Bar
            _buildControlBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.classSession.title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.classSession.teacherName,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(_classDuration),
                    style: GoogleFonts.poppins(
                      color: Colors.green[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.info_outline),
                color: Colors.grey[400],
                onPressed: () {
                  _showClassInfo();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance',
                style: GoogleFonts.poppins(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
              ),
              Icon(
                Icons.check_circle,
                color: Colors.green[300],
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.85,
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[300]!),
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '85%',
                style: GoogleFonts.poppins(
                  color: Colors.green[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Marked Present',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Class Info',
            style: GoogleFonts.poppins(
              color: Colors.grey[300],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.code,
            'Class Code',
            widget.classSession.joinCode,
          ),
          _buildInfoRow(
            Icons.book,
            'Subject',
            widget.classSession.subject,
          ),
          _buildInfoRow(
            Icons.group,
            'Students',
            '24 Online',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Controls
          Row(
            children: [
              _buildControlButton(
                icon: _micMuted ? Icons.mic_off : Icons.mic,
                label: _micMuted ? 'Unmute' : 'Mute',
                color: _micMuted ? Colors.red : Colors.grey[300]!,
                onPressed: _toggleMic,
              ),
              const SizedBox(width: 10),
              _buildControlButton(
                icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                label: _cameraOff ? 'Camera On' : 'Camera Off',
                color: _cameraOff ? Colors.red : Colors.grey[300]!,
                onPressed: _toggleCamera,
              ),
              const SizedBox(width: 10),
              _buildControlButton(
                icon: _handRaised ? Icons.back_hand : Icons.front_hand,
                label: _handRaised ? 'Lower Hand' : 'Raise Hand',
                color: _handRaised ? Colors.orange : Colors.grey[300]!,
                onPressed: _toggleHandRaise,
              ),
            ],
          ),
          
          // Center - Connection Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Good Connection',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[300],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Right - Leave Button
          ElevatedButton(
            onPressed: _leaveClass,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
              children: [
                const Icon(Icons.call_end, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Leave Class',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _showClassInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          'Class Information',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogInfoRow('Class:', widget.classSession.title),
            _buildDialogInfoRow('Teacher:', widget.classSession.teacherName),
            _buildDialogInfoRow('Subject:', widget.classSession.subject),
            _buildDialogInfoRow('Class Code:', widget.classSession.joinCode),
            _buildDialogInfoRow('Duration:', '${_classDuration.inMinutes} minutes'),
            _buildDialogInfoRow('Status:', 'Live'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}