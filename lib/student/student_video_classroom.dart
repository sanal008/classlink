import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../zego_service.dart';
import '../common/whiteboard.dart';

class StudentVideoClassRoom extends StatefulWidget {
  final User user;
  final String conferenceID;
  final String className;

  const StudentVideoClassRoom({
    super.key,
    required this.user,
    required this.conferenceID,
    required this.className,
  });

  @override
  State<StudentVideoClassRoom> createState() => _StudentVideoClassRoomState();
}

class _StudentVideoClassRoomState extends State<StudentVideoClassRoom> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _startVideoConference() {
    // Start the video conference
    ZegoService.startVideoConference(
      context: context,
      conferenceID: widget.conferenceID,
      userName: widget.user.name,
      userID: widget.user.id,
      role: widget.user.role,
      userEmail: widget.user.email,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text(
          widget.className,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        children: [
          // Video Conference Page
          _buildVideoConferencePage(),
          
          // Whiteboard Page
          SimpleWhiteboard(
            whiteboardTitle: 'Class Whiteboard',
            isReadOnly: false,
            studentId: widget.user.id,
            studentName: widget.user.name,
            conferenceId: widget.conferenceID,
          ),
        ],
      ),
      floatingActionButton: _currentPage == 0 
        ? FloatingActionButton.extended(
            onPressed: () {
              // Navigate to whiteboard tab
              _pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Whiteboard', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.indigo,
            tooltip: 'Open Whiteboard',
          )
        : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPage,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam),
            label: 'Video',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Whiteboard',
          ),
        ],
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }

  Widget _buildVideoConferencePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Class Info Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class Information',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.code,
                        size: 20,
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Conference ID',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            widget.conferenceID,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 20,
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Name',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            widget.user.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Features
          Text(
            'Available Features',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Button to join video conference on demand
          Center(
            child: ElevatedButton.icon(
              onPressed: _startVideoConference,
              icon: const Icon(Icons.videocam),
              label: const Text('Join Video Conference'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _featureCard(
            icon: Icons.videocam,
            title: 'Video Conference',
            description: 'Join the live video class with teacher and other students',
          ),
          const SizedBox(height: 10),
          
          _featureCard(
            icon: Icons.edit,
            title: 'Whiteboard',
            description: 'Draw and take notes during the class (Swipe to Whiteboard tab)',
          ),
          const SizedBox(height: 10),
          
          _featureCard(
            icon: Icons.mic,
            title: 'Audio',
            description: 'Communicate with crystal clear audio',
          ),
          const SizedBox(height: 10),
          
          _featureCard(
            icon: Icons.save,
            title: 'Save Notes',
            description: 'Save your whiteboard drawings and notes for later review',
          ),

          const SizedBox(height: 24),

          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pro Tips',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Allow camera and microphone permissions\n'
                  '• Use whiteboard tab for note-taking\n'
                  '• Save your drawings before leaving the class\n'
                  '• You can type text or draw on the whiteboard',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.indigo,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
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
}
