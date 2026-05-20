import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String? id;
  final String userId;
  final String userEmail;
  final String fixerId;
  final String requestId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    this.id,
    required this.userId,
    required this.userEmail,
    required this.fixerId,
    required this.requestId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'fixerId': fixerId,
      'requestId': requestId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      fixerId: map['fixerId'] ?? '',
      requestId: map['requestId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
