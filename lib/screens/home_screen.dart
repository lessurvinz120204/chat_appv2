import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/screens/admin_chat_list_screen.dart';
import 'package:chat_app/screens/user_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'user';
  bool _isLoading = true;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();

      if (mounted) {
        setState(() {
          _userRole = doc.data()?['role'] ?? 'user';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user role: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Loading State
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
      );
    }

    // 2. Admin View
    if (_userRole == 'admin') {
      return const AdminChatListScreen();
    }
    return UserChatScreen(
      currentUser: _currentUser, 
      userRole: _userRole,
    );
   
  }
}