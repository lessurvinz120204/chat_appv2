import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatefulWidget {
  final String message;
  final String? mediaUrl; 
  final bool isCurrentUser;
  final DateTime? timestamp;
  final bool showCenteredTimestamp;

  const ChatBubble({
    super.key,
    required this.message,
    this.mediaUrl, 
    required this.isCurrentUser,
    this.timestamp,
    this.showCenteredTimestamp = false,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showTimestamp = false;

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays == 0) return DateFormat('h:mm a').format(dateTime);
    if (difference.inDays == 1) return 'Yesterday ${DateFormat('h:mm a').format(dateTime)}';
    return DateFormat('MMM d, h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showCenteredTimestamp && widget.timestamp != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
              child: Text(_formatTimestamp(widget.timestamp), style: const TextStyle(fontSize: 12, color: Colors.white)),
            ),
          ),
        GestureDetector(
          onTap: () {
            setState(() => _showTimestamp = !_showTimestamp);
            Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _showTimestamp = false); });
          },
          child: Container(
            alignment: widget.isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: widget.isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  decoration: BoxDecoration(
                    color: widget.isCurrentUser ? Colors.blueAccent : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      children: [
                        if (widget.mediaUrl != null)
                          Builder(builder: (context) {
                            if (widget.mediaUrl!.startsWith('data:image')) {
                              return Image.memory(base64Decode(widget.mediaUrl!.split(',').last), fit: BoxFit.cover);
                            } else {
                              return Image.network(widget.mediaUrl!, fit: BoxFit.cover);
                            }
                          }),
                        if (widget.message.isNotEmpty && widget.message != '📷 Photo')
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Text(widget.message, style: TextStyle(color: widget.isCurrentUser ? Colors.white : Colors.black87, fontSize: 16)),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_showTimestamp && widget.timestamp != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(_formatTimestamp(widget.timestamp), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}