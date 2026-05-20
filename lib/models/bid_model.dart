import 'package:cloud_firestore/cloud_firestore.dart';

class BidModel {
  final String? id;
  final String fixerId;
  final String fixerName;
  final double price;
  final String message;
  final bool canComeToYou;
  final DateTime createdAt;
  final String status; // 'pending', 'accepted', 'rejected'

  BidModel({
    this.id,
    required this.fixerId,
    required this.fixerName,
    required this.price,
    required this.message,
    required this.canComeToYou,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'fixerId': fixerId,
      'fixerName': fixerName,
      'price': price,
      'message': message,
      'canComeToYou': canComeToYou,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory BidModel.fromMap(Map<String, dynamic> map, String id) {
    return BidModel(
      id: id,
      fixerId: map['fixerId'] ?? '',
      fixerName: map['fixerName'] ?? 'Unknown Fixer',
      price: (map['price'] ?? 0.0).toDouble(),
      message: map['message'] ?? '',
      canComeToYou: map['canComeToYou'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
    );
  }
}
