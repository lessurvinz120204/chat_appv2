import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/screens/profile_screen.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.black87],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Active Conversations',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .orderBy('lastMessageAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No active chats found.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    final chatDocs = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: chatDocs.length,
                      itemBuilder: (context, index) {
                        final chatData = chatDocs[index].data() as Map<String, dynamic>;
                        final String userId = chatDocs[index].id;
                        final String userEmail = chatData['userEmail'] ?? 'User: $userId';
                        final String lastMsg = chatData['lastMessage'] ?? 'No messages yet';
                        final int unreadCount = chatData['unreadByAdminCount'] ?? 0;
                        
                        // LOGIC: Check if there are unread messages
                        final bool hasUnread = unreadCount > 0;

                        return Card(
                          // HIGHLIGHT: Change color and elevation if unread
                          color: hasUnread 
                              ? Colors.white.withOpacity(0.2) 
                              : Colors.white.withOpacity(0.1),
                          elevation: hasUnread ? 4 : 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            // HIGHLIGHT: Add a subtle border for unread chats
                            side: BorderSide(
                              color: hasUnread ? Colors.blueAccent : Colors.white.withOpacity(0.1),
                              width: hasUnread ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                            leading: CircleAvatar(
                              backgroundColor: hasUnread ? Colors.blueAccent : Colors.white24,
                              child: Text(
                                userEmail[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              userEmail,
                              style: TextStyle(
                                color: Colors.white,
                                // HIGHLIGHT: Use Black weight for unread titles
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              lastMsg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                // HIGHLIGHT: Subtitle is brighter if unread
                                color: hasUnread ? Colors.white : Colors.white70,
                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            trailing: hasUnread
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Colors.blueAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Icon(Icons.arrow_forward_ios,
                                    color: Colors.white38, size: 16),
                            onTap: () async {
                              // LOGIC: Reset unread count when admin opens the chat
                              if (hasUnread) {
                                await FirebaseFirestore.instance
                                    .collection('chats')
                                    .doc(userId)
                                    .update({'unreadByAdminCount': 0});
                              }

                              if (context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatRoomId: userId,
                                      userName: userEmail,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}