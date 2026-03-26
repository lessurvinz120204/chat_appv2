import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/widgets/chat_bubble.dart';
import 'package:chat_app/services/notification_service.dart'; // NEW IMPORT
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId; 
  final String? userName;

  const ChatScreen({super.key, required this.chatRoomId, this.userName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  String? _backgroundUrl;
  List<Color> _currentGradient = [Colors.white, Colors.grey[200]!];
  bool _isDarkTheme = false;
  
  String? _pickedImageBase64;
  bool _isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _listenToChatSettings();
    
    // ✅ GET TOKEN FOR APK TESTING
    if (!kIsWeb) {
      NotificationService.getDeviceToken().then((token) {
        print("--- DEVICE NOTIFICATION TOKEN ---");
        print(token);
        print("---------------------------------");
      });
    }
  }

  void _listenToChatSettings() {
    _firestore.collection('chats').doc(widget.chatRoomId).snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _backgroundUrl = data['themeImageUrl'];
          _isDarkTheme = data['isDarkTheme'] ?? false;
          if (data['themeColors'] != null) {
            List<dynamic> colorValues = data['themeColors'];
            _currentGradient = colorValues.map((c) => Color(c as int)).toList();
          }
        });
      }
    });
  }

  Future<void> _markMessagesAsRead() async {
    final String myId = _auth.currentUser!.uid;
    String fieldToReset = (myId == widget.chatRoomId) ? 'unreadByUserCount' : 'unreadByAdminCount';
    await _firestore.collection('chats').doc(widget.chatRoomId).set({
      fieldToReset: 0
    }, SetOptions(merge: true));
  }

  Future<void> _updateUnreadCountsOnSend(String lastMsg) async {
    final String myId = _auth.currentUser!.uid;
    String fieldToIncrement = (myId == widget.chatRoomId) ? 'unreadByAdminCount' : 'unreadByUserCount';
    await _firestore.collection('chats').doc(widget.chatRoomId).set({
      'lastMessage': lastMsg,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'userEmail': _auth.currentUser!.email,
      fieldToIncrement: FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty && _pickedImageBase64 == null) return;

    String? mediaToUpload = _pickedImageBase64;
    String displayMsg = mediaToUpload != null ? '📷 Photo' : text;

    _messageController.clear();
    setState(() => _pickedImageBase64 = null);

    try {
      await _firestore.collection('chats').doc(widget.chatRoomId).collection('messages').add({
        'text': (text.isEmpty && mediaToUpload != null) ? '📷 Photo' : text,
        'mediaUrl': mediaToUpload,
        'mediaType': mediaToUpload != null ? 'image' : null,
        'createdAt': FieldValue.serverTimestamp(),
        'senderId': _auth.currentUser!.uid,
      });
      await _updateUnreadCountsOnSend(displayMsg);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Image might be too large for database.")),
        );
      }
    }
  }

  Future<void> _handleImagePick() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 20 
    );
    
    if (file == null) return;

    setState(() => _isProcessingImage = true);

    try {
      final bytes = await file.readAsBytes();
      String base64String = base64Encode(bytes);
      
      setState(() {
        _pickedImageBase64 = 'data:image/jpeg;base64,$base64String';
        _isProcessingImage = false;
      });
    } catch (e) {
      setState(() => _isProcessingImage = false);
    }
  }

  Future<void> _updateThemeInFirestore({List<Color>? colors, String? imageUrl, required bool isDark}) async {
    Map<String, dynamic> updateData = {'isDarkTheme': isDark};
    if (colors != null) { updateData['themeColors'] = colors.map((c) => c.value).toList(); updateData['themeImageUrl'] = null; }
    if (imageUrl != null) { updateData['themeImageUrl'] = imageUrl; updateData['themeColors'] = null; }
    await _firestore.collection('chats').doc(widget.chatRoomId).set(updateData, SetOptions(merge: true));
  }

  Future<void> _pickChatBackground() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    String base64Image = base64Encode(bytes);
    String dataUrl = 'data:image/jpeg;base64,$base64Image';
    await _updateThemeInFirestore(imageUrl: dataUrl, isDark: true);
    if (mounted) Navigator.pop(context);
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: 280, padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Chat Theme", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _themeCircle([const Color(0xFFFF85A1), const Color(0xFF750D37)], true),
                _themeCircle([Colors.blueAccent, Colors.purpleAccent], true),
                _themeCircle([Colors.white, Colors.grey[300]!], false),
              ],
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.deepPurple),
              title: const Text("Select Background from Gallery"),
              onTap: _pickChatBackground,
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeCircle(List<Color> colors, bool isDark) {
    return GestureDetector(
      onTap: () => _updateThemeInFirestore(colors: colors, isDark: isDark).then((_) => Navigator.pop(context)),
      child: Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: colors))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black12,
        elevation: 0,
        title: Text(widget.userName ?? 'Chat', style: TextStyle(color: _isDarkTheme ? Colors.white : Colors.black)),
        iconTheme: IconThemeData(color: _isDarkTheme ? Colors.white : Colors.black),
        actions: [IconButton(icon: const Icon(Icons.palette), onPressed: _showThemePicker)],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: _backgroundUrl != null 
              ? DecorationImage(
                  image: _backgroundUrl!.startsWith('data:image') 
                      ? MemoryImage(base64Decode(_backgroundUrl!.split(',').last)) as ImageProvider
                      : NetworkImage(_backgroundUrl!), 
                  fit: BoxFit.cover) 
              : null,
          gradient: _backgroundUrl == null ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _currentGradient) : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('chats').doc(widget.chatRoomId).collection('messages').orderBy('createdAt', descending: false).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 100, bottom: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return ChatBubble(
                        message: data['text'] ?? '',
                        mediaUrl: data['mediaUrl'],
                        isCurrentUser: data['senderId'] == _auth.currentUser!.uid,
                        timestamp: (data['createdAt'] as Timestamp?)?.toDate(),
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: _isDarkTheme ? Colors.black87 : Colors.white,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isProcessingImage)
              const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)),
            if (_pickedImageBase64 != null)
              Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 10),
                child: Stack(
                  children: [
                    Container(
                      height: 100, width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue, width: 2),
                        image: DecorationImage(
                          image: MemoryImage(base64Decode(_pickedImageBase64!.split(',').last)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -5, top: -5,
                      child: GestureDetector(
                        onTap: () => setState(() => _pickedImageBase64 = null),
                        child: const CircleAvatar(
                          radius: 12, backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.add_a_photo, color: Colors.blue), onPressed: _handleImagePick),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: _isDarkTheme ? Colors.white : Colors.black),
                    textInputAction: TextInputAction.send, 
                    onSubmitted: (value) => _sendMessage(), 
                    decoration: const InputDecoration(hintText: "Message...", border: InputBorder.none),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _sendMessage),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }
}