import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../theme/theme_provider.dart';

class ChatScreen extends StatefulWidget {
  final String orderId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _databaseService.sendMessage(
        widget.orderId,
        _messageController.text.trim(),
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDark(context);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('pending_orders').doc(widget.orderId).get(),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: isDark ? AppColors.navyDarkest : const Color(0xFFF4F6F9),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!orderSnapshot.hasData || !orderSnapshot.data!.exists) {
          return Scaffold(
            body: Center(child: Text("Order not found", style: GoogleFonts.dmSans())),
          );
        }

        final orderData = orderSnapshot.data!.data() as Map<String, dynamic>;
        final String userId = orderData['userId'] ?? '';
        final String deliveryBoyId = orderData['deliveryBoyId'] ?? '';

        // Security check: Only involved parties can see the chat
        if (_currentUserId != userId && _currentUserId != deliveryBoyId) {
          return Scaffold(
            body: Center(child: Text("Unauthorized Access", style: GoogleFonts.dmSans())),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? AppColors.navyDarkest : const Color(0xFFF4F6F9),
          appBar: AppBar(
            title: Text(
              widget.otherUserName,
              style: GoogleFonts.pangolin(fontWeight: FontWeight.bold),
            ),
            backgroundColor: isDark ? AppColors.navyLighter : Colors.white,
            foregroundColor: AppColors.textTitle(isDark),
            elevation: 0,
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _databaseService.getMessagesStream(widget.orderId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No messages yet. Say hi!',
                          style: GoogleFonts.dmSans(color: AppColors.textSecondary(isDark)),
                        ),
                      );
                    }

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final messageData = messages[index].data() as Map<String, dynamic>;
                        final bool isMe = messageData['senderId'] == _currentUserId;
                        final String text = messageData['text'] ?? '';

                        return _buildMessageBubble(text, isMe, isDark);
                      },
                    );
                  },
                ),
              ),
              _buildMessageInput(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, bool isDark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
            ? AppColors.tangerine
            : (isDark ? AppColors.navyLighter : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            color: isMe ? Colors.white : AppColors.textMain(isDark),
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyLighter : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.navyDarkest : const Color(0xFFF4F6F9),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  style: GoogleFonts.dmSans(color: AppColors.textMain(isDark)),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.dmSans(color: AppColors.textSecondary(isDark)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.tangerine,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
