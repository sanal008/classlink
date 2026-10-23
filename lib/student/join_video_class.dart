import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import 'student_video_classroom.dart';

class JoinVideoClassPage extends StatefulWidget {
  final User user;

  const JoinVideoClassPage({super.key, required this.user});

  @override
  State<JoinVideoClassPage> createState() => _JoinVideoClassPageState();
}

class _JoinVideoClassPageState extends State<JoinVideoClassPage> {
  final _classIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _classIdController.dispose();
    super.dispose();
  }

  void _joinClass() {
    final classId = _classIdController.text.trim();
    
    if (classId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a class ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to the classroom with video and whiteboard features
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudentVideoClassRoom(
          user: widget.user,
          conferenceID: classId,
          className: 'Class Session',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Join Class',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.video_call,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 30),

            // Title
            Text(
              'Enter Class ID',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Subtitle
            Text(
              'Ask your teacher for the class ID to join the video conference',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Class ID Input
            TextFormField(
              controller: _classIdController,
              decoration: InputDecoration(
                labelText: 'Class ID',
                hintText: 'e.g., quick_class_1234567890',
                prefixIcon: Icon(
                  Icons.code,
                  color: Theme.of(context).primaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 30),

            // Join Button
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : ElevatedButton(
                    onPressed: _joinClass,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Join Class',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
            const SizedBox(height: 20),

            // Info Box
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'How to join:',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '1. Request the class ID from your teacher\n'
                    '2. Enter the ID above\n'
                    '3. Tap "Join Class" to start the video conference\n'
                    '4. Allow camera and microphone permissions when prompted',
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
      ),
    );
  }
}
