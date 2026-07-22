import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../theme/theme_provider.dart';
import 'routing_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  
  String _role = 'User'; 
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _collegeIdController = TextEditingController();
  final TextEditingController _roomNumberController = TextEditingController();
  
  bool _isLoading = false;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        try {
          await _databaseService.saveUserData(
            uid: currentUser.uid,
            role: _role,
            name: _nameController.text.trim(),
            collegeId: _collegeIdController.text.trim(),
            roomNumber: _roomNumberController.text.trim(),
          );
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Onboarding Complete!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoutingScreen()),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save data. Please try again.')),
          );
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found. Please log in again.')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _collegeIdController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDark(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.bgGradient(isDark),
        ),
        child: SafeArea(
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: AppColors.tangerine))
            : Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // DormDrop Logo Title
                        Text(
                          'DormDrop',
                          style: GoogleFonts.righteous(
                            fontSize: 48,
                            color: AppColors.textTitle(isDark),
                            shadows: [
                                  Shadow(color: AppColors.tangerine.withOpacity(0.5), offset: const Offset(3, 3), blurRadius: 10),
                                  Shadow(color: isDark ? Colors.black : Colors.white, offset: const Offset(5, 5), blurRadius: 0),
                                ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        'Complete Your Profile',
                        style: GoogleFonts.pangolin(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain(isDark),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Pearlescent/Neon Blob Form Container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: AppColors.blobGradient(isDark, 0),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(50),
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(60),
                          ),
                          border: Border.all(color: AppColors.borderMain(isDark), width: 3),
                          boxShadow: [
                            BoxShadow(color: AppColors.shadowMain(isDark), blurRadius: 15, offset: const Offset(5, 5)),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select your role:',
                                style: GoogleFonts.pangolin(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain(isDark)),
                              ),
                              const SizedBox(height: 8),
                              _buildDropdownBlob(isDark),
                              const SizedBox(height: 20),
                              _buildInputBlob(controller: _nameController, label: 'Full Name', isDark: isDark),
                              const SizedBox(height: 20),
                              _buildInputBlob(controller: _collegeIdController, label: 'College ID', isDark: isDark),
                              const SizedBox(height: 20),
                              _buildInputBlob(controller: _roomNumberController, label: 'Room Number', isDark: isDark),
                              const SizedBox(height: 30),
                              
                              // Submit Brutalist Button
                              GestureDetector(
                                onTap: _submitForm,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryButtonGradient(isDark),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(40),
                                      bottomLeft: Radius.circular(30),
                                      bottomRight: Radius.circular(15),
                                    ),
                                    border: Border.all(color: AppColors.borderButton(isDark), width: 3),
                                    boxShadow: [
                                      BoxShadow(color: AppColors.brutalistShadow(isDark), offset: const Offset(5, 5), blurRadius: 0),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Save Profile',
                                      style: GoogleFonts.pangolin(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textButton(isDark),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildDropdownBlob(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderMain(isDark), width: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: _role,
          icon: const Icon(Icons.arrow_drop_down_circle, color: AppColors.tangerine),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          dropdownColor: isDark ? AppColors.navyLighter : Colors.white,
          items: ['User', 'Delivery Boy'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: GoogleFonts.pangolin(fontSize: 18, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _role = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildInputBlob({required TextEditingController controller, required String label, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderMain(isDark), width: 2),
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.pangolin(fontSize: 18, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.pangolin(color: AppColors.textSecondary(isDark)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
