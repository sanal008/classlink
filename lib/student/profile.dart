import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../firebase_service.dart';

class StudentProfilePage extends StatefulWidget {
  final User user;

  const StudentProfilePage({super.key, required this.user});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  
  bool _isEditing = false;
  double attendancePercentage = 0.0;
  int classesAttended = 0;
  int classesMissed = 0;
  final FirebaseService _firebaseService = FirebaseService();
  bool _loadingProfile = true;
  bool _loadingAttendance = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfileFromFirebase();
    _loadAttendanceData();
  }

  void _initializeControllers() {
    // Initialize with empty values - Firebase data will be loaded in _loadProfileFromFirebase
    _nameController.text = '';
    _emailController.text = '';
    _phoneController.text = '';
    _departmentController.text = '';
    _semesterController.text = '';
  }

  Future<void> _loadProfileFromFirebase() async {
    setState(() {
      _loadingProfile = true;
    });

    try {
      final fetched = await _firebaseService.getUser(widget.user.id);
      if (fetched != null) {
        // Update controllers with data from Firebase if available
        setState(() {
          _nameController.text = fetched.name;
          _emailController.text = fetched.email;
          _phoneController.text = fetched.phone ?? '';
          _departmentController.text = fetched.department ?? '';
          _semesterController.text = ''; // Semester not stored in registration
        });
      }
    } catch (e) {
      // ignore errors for now; could show snackbar
    } finally {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
        });
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Save changes
        _saveProfile();
      }
    });
  }

  void _saveProfile() {
    // In real app, save to Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile updated successfully',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      _loadingAttendance = true;
    });

    try {
      _firebaseService.getStudentAttendance(widget.user.id).listen((attendanceList) {
        if (mounted) {
          setState(() {
            classesAttended = attendanceList.where((a) => a.status == 'present').length;
            classesMissed = attendanceList.where((a) => a.status == 'absent').length;
            
            // Calculate percentage
            if (attendanceList.isNotEmpty) {
              attendancePercentage = (classesAttended / attendanceList.length) * 100;
            } else {
              attendancePercentage = 0.0;
            }
            
            _loadingAttendance = false;
          });
        }
      });
    } catch (e) {
      print('Error loading attendance data: $e');
      if (mounted) {
        setState(() {
          _loadingAttendance = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.save : Icons.edit,
              color: _isEditing ? Colors.green : null,
            ),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(),
                  const SizedBox(height: 30),

                  // Attendance Stats
                  _buildAttendanceStats(),
                  const SizedBox(height: 30),

                  // Profile Info
                  _buildProfileInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColorDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                color: Colors.white.withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEditableField(
                  controller: _nameController,
                  label: 'Name',
                  isEditing: _isEditing,
                  icon: Icons.person,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.badge,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.user.enrollmentId,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildEditableField(
                  controller: _emailController,
                  label: 'Email',
                  isEditing: _isEditing,
                  icon: Icons.email,
                  isEmail: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: _loadingAttendance
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attendance Summary',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: attendancePercentage > 75 
                            ? Colors.green[50] 
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: attendancePercentage > 75 
                              ? Colors.green[100]! 
                              : Colors.orange[100]!,
                        ),
                      ),
                      child: Text(
                        attendancePercentage > 75 ? 'Good' : 'Needs Improvement',
                        style: GoogleFonts.poppins(
                          color: attendancePercentage > 75 
                              ? Colors.green[700] 
                              : Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      value: '${attendancePercentage.toStringAsFixed(1)}%',
                      label: 'Overall',
                      icon: Icons.trending_up,
                      color: Theme.of(context).primaryColor,
                    ),
                    _buildStatItem(
                      value: '$classesAttended',
                      label: 'Classes Attended',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    _buildStatItem(
                      value: '$classesMissed',
                      label: 'Missed',
                      icon: Icons.cancel,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            size: 30,
            color: color,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required TextEditingController value,
    required bool isEditing,
    bool isPhone = false,
    bool isDate = false,
    bool isAddress = false,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              isEditing
                  ? TextFormField(
                      controller: value,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    )
                  : Text(
                      value.text,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required bool isEditing,
    required IconData icon,
    bool isEmail = false,
  }) {
    return isEditing
        ? TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: label,
              hintStyle: GoogleFonts.poppins(
                color: Colors.white70,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
            keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
          )
        : Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.text,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
  }

  Widget _buildProfileInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            icon: Icons.person,
            label: 'Name',
            value: _nameController,
            isEditing: _isEditing,
          ),
          const SizedBox(height: 15),
          _buildInfoRow(
            icon: Icons.email,
            label: 'Email',
            value: _emailController,
            isEditing: _isEditing,
          ),
          const SizedBox(height: 15),
          _buildInfoRow(
            icon: Icons.badge,
            label: 'Enrollment ID',
            value: TextEditingController(text: widget.user.enrollmentId),
            isEditing: false, // Enrollment ID is not editable
          ),
          const SizedBox(height: 15),
          _buildInfoRow(
            icon: Icons.apartment,
            label: 'Department',
            value: _departmentController,
            isEditing: _isEditing,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            icon: Icons.school,
            label: 'Department',
            value: _departmentController,
            isEditing: _isEditing,
          ),
          const SizedBox(height: 15),
          _buildInfoRow(
            icon: Icons.class_,
            label: 'Semester',
            value: _semesterController,
            isEditing: _isEditing,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _semesterController.dispose();
    super.dispose();
  }
}