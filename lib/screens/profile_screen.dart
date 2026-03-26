import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _currentUser!.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _formKey.currentState!.reset();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    await _auth.signOut();
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.black87],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // 🔹 User Icon & Email
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  _currentUser?.email ?? 'No email found',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                
                // 🔹 Glass-morphism Card for Password Change
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update Security',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _newPasswordController,
                          label: 'New Password',
                          icon: Icons.lock_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm New Password',
                          icon: Icons.lock_reset,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _isLoading ? null : _changePassword,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // 🔹 Logout Button
                TextButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for styled text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white38),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (label.contains('Confirm') && value != _newPasswordController.text) return 'Mismatch';
        if (value.length < 6) return 'Too short';
        return null;
      },
    );
  }
}