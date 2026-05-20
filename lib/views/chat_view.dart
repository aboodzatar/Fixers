import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_training/controllers/chat_controller.dart';
import 'package:firebase_training/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ChatView extends StatelessWidget {
  final String requestId;
  final String chatTitle;

  ChatView({super.key, required this.requestId, required this.chatTitle});

  final ChatController chatController = Get.put(ChatController());
  final TextEditingController messageCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Future<void> _sendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      Get.snackbar('Uploading', 'Sending your photo...', showProgressIndicator: true, duration: const Duration(seconds: 2));
      final String? url = await chatController.uploadChatImage(image);
      if (url != null) {
        chatController.sendMessage(requestId, imageUrl: url);
      }
    }
  }

  void _showFullImage(String url) {
    Get.to(() => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
      body: Center(child: InteractiveViewer(child: Image.network(url))),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(chatTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatController.getMessages(requestId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUserId;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(4), // Small padding for the bubble
                        constraints: BoxConstraints(maxWidth: Get.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.indigo : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg.imageUrl != null)
                              GestureDetector(
                                onTap: () => _showFullImage(msg.imageUrl!),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    msg.imageUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
                                    },
                                  ),
                                ),
                              ),
                            if (msg.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text(
                                  msg.text,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : const Color(0xFF1E293B),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _sendImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.indigo),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: messageCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      chatController.sendMessage(requestId, text: messageCtrl.text);
                      messageCtrl.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
