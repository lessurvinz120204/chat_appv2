import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/screens/chat_screen.dart';

class UserChatScreen extends StatelessWidget {
  final User? currentUser;
  final String userRole;

  const UserChatScreen({
    super.key,
    required this.currentUser,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF85A1), Color(0xFF750D37)], 
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                currentUser?.email ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  userRole.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              Expanded(
                child: Center(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int unreadCount = 0;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        unreadCount = data?['unreadByUserCount'] ?? 0;
                      }

                      // LOGIC: Check if we should highlight
                      final bool isHighlighted = unreadCount > 0;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () async {
                                if (currentUser != null) {
                                  if (unreadCount > 0) {
                                    await FirebaseFirestore.instance
                                        .collection('chats')
                                        .doc(currentUser!.uid)
                                        .update({'unreadByUserCount': 0});
                                  }

                                  if (context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          chatRoomId: currentUser!.uid,
                                          userName: "Admin",
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  // --- HIGHLIGHTED OUTER RING ---
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        // Change color to Amber when there's a message
                                        color: isHighlighted ? Colors.amberAccent : Colors.white38, 
                                        width: isHighlighted ? 4 : 2,
                                      ),
                                      // Add a glow effect when highlighted
                                      boxShadow: isHighlighted ? [
                                        const BoxShadow(
                                          color: Colors.amberAccent,
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        )
                                      ] : [],
                                    ),
                                  ),
                                  
                                  // White Bubble
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 20,
                                          offset: Offset(0, 10),
                                        )
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.favorite_rounded,
                                      size: 40,
                                      // Icon also changes color to match highlight
                                      color: isHighlighted ? const Color(0xFF750D37) : const Color(0xFFFF4D6D),
                                    ),
                                  ),

                                  // --- BADGE POSITIONED ON ICON ---
                                  if (unreadCount > 0)
                                    Positioned(
                                      top: -5, // Slightly above the ring
                                      right: -5, // Slightly to the side
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.amberAccent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF750D37), width: 2),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black45, blurRadius: 4)
                                          ]
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 35, 
                                          minHeight: 35
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$unreadCount',
                                            style: const TextStyle(
                                              color: Color(0xFF750D37),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isHighlighted ? 'New Message from Boyfriend!' : 'Tap to Message Your Handsome Boyfriend',
                            style: TextStyle(
                              color: isHighlighted ? Colors.amberAccent : Colors.white70, 
                              fontSize: 16,
                              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                              fontStyle: FontStyle.italic,
                              shadows: const [
                                Shadow(blurRadius: 10, color: Colors.black26, offset: Offset(0, 2))
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}