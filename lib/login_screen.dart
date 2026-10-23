import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models.dart';
import 'firebase_service.dart';
import 'student/dashboard.dart';
import 'teacher/teacher_dashboard.dart' as teacher_dashboard;
import 'admin/admin_dashboard.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _enrollmentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final FirebaseService _firebaseService = FirebaseService();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      User? user;
      
      if (widget.role == 'admin') {
        // Admin authentication with dummy credentials
        if (_enrollmentIdController.text.trim() == 'admin' && 
            _passwordController.text.trim() == 'admin123') {
          user = User(
            id: 'admin',
            name: 'Administrator',
            email: 'admin@classlink+.app',
            role: 'admin',
            enrollmentId: 'admin',
          );
        }
      } else {
        // Regular user authentication
        user = await _firebaseService.authenticate(
          _enrollmentIdController.text.trim(),
          _passwordController.text.trim(),
          widget.role,
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (user != null) {
          if (widget.role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDashboard(user: user!),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => widget.role == 'student'
                    ? StudentDashboard(user: user!)
                    : teacher_dashboard.TeacherDashboard(user: user!),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invalid credentials or role mismatch'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
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
            children: [
              // Header Section
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.role == 'student' 
                              ? Icons.school 
                              : widget.role == 'admin'
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                          size: 60,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.role == 'student'
                            ? 'Student Login'
                            : widget.role == 'admin'
                                ? 'Administrator Login'
                                : 'Teacher Login',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Login Form Section
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            'Sign In',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Enrollment ID Field
                          TextFormField(
                            controller: _enrollmentIdController,
                            decoration: InputDecoration(
                              labelText: widget.role == 'student' 
                                  ? 'Enrollment ID' 
                                  : widget.role == 'admin'
                                      ? 'Admin ID'
                                      : 'Teacher ID',
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey[600],
                              ),
                              prefixIcon: Icon(
                                Icons.badge,
                                color: Theme.of(context).primaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your ID';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey[600],
                              ),
                              prefixIcon: Icon(
                                Icons.lock,
                                color: Theme.of(context).primaryColor,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: widget.role != 'admin'
                                ? TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ForgotPasswordScreen(role: widget.role),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.poppins(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(), // No forgot password for admin
                          ),
                          const SizedBox(height: 30),

                          // Login Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Login',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _enrollmentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}