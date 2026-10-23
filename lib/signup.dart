import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models.dart';
import 'firebase_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _enrollmentCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  String? _selectedDepartment;

  bool _isTeacher = false;
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _enrollmentCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final role = _isTeacher ? 'teacher' : 'student';
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final user = User(
      id: id,
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      role: role,
      enrollmentId: _enrollmentCtrl.text.trim(),
      department: _selectedDepartment ?? '',
      profileImage: null,
    );

    final success = await _firebaseService.registerUser(user, _passwordCtrl.text);

    setState(() => _loading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Try again.'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool showPassword,
    required Function(bool) onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !showPassword,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(Icons.lock, color: Theme.of(context).primaryColor),
        suffixIcon: IconButton(
          icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
          color: Theme.of(context).primaryColor,
          onPressed: () => onToggle(!showPassword),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter password';
        if (v.length < 6) return 'Password must be 6+ characters';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Spacer(),
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
                  'Create Your Account',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Role Selection with improved styling
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                padding: const EdgeInsets.all(8),
                child: ToggleButtons(
                  isSelected: [!_isTeacher, _isTeacher],
                  onPressed: (index) {
                    setState(() {
                      _isTeacher = index == 1;
                      _departmentCtrl.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: Theme.of(context).primaryColor,
                  splashColor: Theme.of(context).primaryColor.withOpacity(0.3),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text(
                        'Student',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text(
                        'Teacher',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Common Fields Section
              Text(
                'Personal Information',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailCtrl,
                label: 'Email Address',
                hint: 'Enter your email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(v)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone number is required';
                  if (v.trim().length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ID Field (Dynamic label)
              _buildTextField(
                controller: _enrollmentCtrl,
                label: _isTeacher ? 'Teacher ID' : 'Enrollment ID',
                hint: _isTeacher ? 'Enter your teacher ID' : 'Enter your enrollment ID',
                icon: Icons.badge,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? (_isTeacher ? 'Teacher ID is required' : 'Enrollment ID is required')
                    : null,
              ),
              const SizedBox(height: 16),

              // Role-Specific Field
              if (_isTeacher)
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: InputDecoration(
                          labelText: 'Department',
                          hintText: 'Select your department',
                          prefixIcon: Icon(Icons.apartment, color: Theme.of(context).primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Computer Science', child: Text('Computer Science')),
                          DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
                          DropdownMenuItem(value: 'EEE', child: Text('EEE')),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            _selectedDepartment = value;
                          });
                        },
                        validator: (value) => value == null ? 'Department is required' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                )
              else
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: InputDecoration(
                          labelText: 'Department',
                          hintText: 'Select your department',
                          prefixIcon: Icon(Icons.apartment, color: Theme.of(context).primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Computer Science', child: Text('Computer Science')),
                          DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
                          DropdownMenuItem(value: 'EEE', child: Text('EEE')),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            _selectedDepartment = value;
                          });
                        },
                        validator: (value) => value == null ? 'Department is required' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Security Section
              Text(
                'Security',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                controller: _passwordCtrl,
                label: 'Password',
                hint: 'Create a strong password',
                showPassword: _showPassword,
                onToggle: (value) => setState(() => _showPassword = value),
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                controller: _confirmCtrl,
                label: 'Confirm Password',
                hint: 'Re-enter your password',
                showPassword: _showConfirmPassword,
                onToggle: (value) => setState(() => _showConfirmPassword = value),
              ),
              const SizedBox(height: 24),

              // Terms & Conditions
              Row(
                children: [
                  Checkbox(
                    value: true,
                    onChanged: (_) {},
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  Expanded(
                    child: Text(
                      'I agree to Terms & Conditions',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sign Up Button
              _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: Text(
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
              const SizedBox(height: 16),

              // Login Link
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                    children: [
                      TextSpan(
                        text: 'Login here',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                        recognizer: TapGestureRecognizer(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
