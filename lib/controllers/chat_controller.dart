import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_training/models/chat_message.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Stream messages for a specific request
  Stream<List<ChatMessage>> getMessages(String requestId) {
    return _firestore
        .collection('requests')
        .doc(requestId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Upload Image for Chat
  Future<String?> uploadChatImage(XFile file) async {
    try {
      final ref = _storage.ref().child('chat_images/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      await ref.putFile(File(file.path));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading chat image: $e');
      return null;
    }
  }

  // Send a new message
  Future<void> sendMessage(String requestId, {String? text, String? imageUrl}) async {
    if ((text?.trim().isEmpty ?? true) && imageUrl == null) return;
    
    final user = _auth.currentUser;
    if (user == null) return;

    final message = ChatMessage(
      senderId: user.uid,
      text: text?.trim() ?? '',
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    try {
      await _firestore
          .collection('requests')
          .doc(requestId)
          .collection('messages')
          .add(message.toMap());
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message: $e');
    }
  }
}
