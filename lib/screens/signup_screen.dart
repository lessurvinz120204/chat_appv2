import 'package:flutter/material.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {

  // 3. Create a GlobalKey for the Form
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // 4. Create TextEditingControllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 5. Clean up controllers when the widget is removed
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 3. This is the same: create the user
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );


      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': _emailController.text.trim(),
          'role': 'user', // 6. Set the default role to 'user'
          'createdAt': FieldValue.serverTimestamp(), // For our records
        });
      }

      // 2. AuthWrapper will auto-navigate to HomeScreen.

    } on FirebaseAuthException catch (e) {
      // 3. Handle specific sign-up errors
      String message = 'An error occurred';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      }


    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print(e);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // 1. A Scaffold provides the basic screen structure
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      // 2. SingleChildScrollView prevents the keyboard from
      //    causing a "pixel overflow" error
      body: SingleChildScrollView(
        child: Padding(
          // 3. Add padding around the form
          padding: const EdgeInsets.all(16.0),
          // 4. The Form widget acts as a container for our fields
          child: Form(
            key: _formKey, // 5. Assign our key to the Form
            // 6. A Column arranges its children vertically
            child: Column(
              // 7. Center the contents of the column
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // 2. The Email Text Field
                TextFormField(
                  controller: _emailController,
                  // 3. Link the controller
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(), // 4. Nice border
                  ),
                  keyboardType: TextInputType.emailAddress,
                  // 5. Show '@' on keyboard
                  // 6. Validator function
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null; // 'null' means the input is valid
                  },
                ),

                // 7. A spacer
                const SizedBox(height: 16),

                // 8. The Password Text Field
                TextFormField(
                  controller: _passwordController, // 9. Link the controller
                  obscureText: true, // 10. This hides the password
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  // 11. Validator function
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

                const SizedBox(height: 20),

                // 2. The Login Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50), // 3. Make it wide
                  ),
                  // 4. onPressed is the click handler
                  onPressed: _signUp,

                  child: _isLoading
                      ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : const Text('Sign Up'),
                ),


                // 6. A spacer
                const SizedBox(height: 10),

                // 7. The "Sign Up" toggle button
                TextButton(
                  onPressed: () {
                    // 8. Navigate to the Sign Up screen
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text("Already have an account? Login"),
                ),


              ],

            ),
          ),
        ),
      ),
    );
  }
}

