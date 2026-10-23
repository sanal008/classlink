import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../firebase_service.dart';
import 'classroom.dart';

class JoinClassPage extends StatefulWidget {
  final User user;

  const JoinClassPage({super.key, required this.user});

  @override
  State<JoinClassPage> createState() => _JoinClassPageState();
}

class _JoinClassPageState extends State<JoinClassPage> {
  final TextEditingController _classCodeController = TextEditingController();
  bool _showCodeInput = false;
  late FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService();
  }

  String _getTimeRemaining(DateTime startTime) {
    final now = DateTime.now();
    final difference = startTime.difference(now);
    
    if (difference.inMinutes < 0) {
      return 'Started';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else {
      return '${difference.inHours} hr ${difference.inMinutes.remainder(60)} min';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Join Class',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Code Input Section
            _buildClassCodeSection(),
            const SizedBox(height: 30),

                  // Available Classes
                  _buildAvailableClasses(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCodeSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.video_call,
                  size: 30,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Join',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Enter class code provided by your teacher',
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
          const SizedBox(height: 20),

          if (!_showCodeInput)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showCodeInput = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                elevation: 5,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Enter Class Code',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                TextField(
                  controller: _classCodeController,
                  decoration: InputDecoration(
                    hintText: 'Enter class code (e.g., MATH101)',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[500],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    prefixIcon: Icon(
                      Icons.code,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showCodeInput = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_classCodeController.text.isNotEmpty) {
                            _joinClassWithCode(_classCodeController.text);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 5,
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
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAvailableClasses() {
    return StreamBuilder<List<ClassSession>>(
      stream: _firebaseService.getUpcomingScheduledClasses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Classes',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          );
        }

        final classes = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Classes',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Join scheduled classes',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            if (classes.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Center(
                  child: Text(
                    'No scheduled classes available',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            else
              ...classes.map((classSession) => _buildClassCard(classSession)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildClassCard(ClassSession classSession) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColorDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.class_,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classSession.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          classSession.teacherName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Icon(
                          Icons.book,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          classSession.subject,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Starts in ${_getTimeRemaining(classSession.startTime)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.code,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 5),
                  Text(
                    classSession.joinCode,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _joinClass(classSession);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_call, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Enter Classroom',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _joinClassWithCode(String code) {
    // Query class by join code from Firebase
    _firebaseService.getScheduledClassByJoinCode(code).then((classSession) {
      if (classSession != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentClassroom(
              classSession: classSession,
              user: widget.user,
            ),
          ),
        );
      } else {
        // Show not found demo fallback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No class found for code: $code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _joinClass(ClassSession classSession) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentClassroom(
          classSession: classSession,
          user: widget.user,
        ),
      ),
    );
  }
}