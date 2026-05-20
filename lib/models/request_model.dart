import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String? id;
  final String deviceType;
  final String issueDescription;
  final String userId;
  final String userEmail;
  final DateTime createdAt;
  final String status; // 'pending' (waiting for bids), 'accepted' (bid chosen), 'in_progress', 'completed'
  final String? acceptedBidId;
  final String? acceptedFixerId;
  final String? acceptedFixerName;
  final double? finalPrice;
  final List<String> imageUrls;

  RequestModel({
    this.id,
    required this.deviceType,
    required this.issueDescription,
    required this.userId,
    required this.userEmail,
    required this.createdAt,
    this.status = 'pending',
    this.acceptedBidId,
    this.acceptedFixerId,
    this.acceptedFixerName,
    this.finalPrice,
    this.imageUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceType': deviceType,
      'issueDescription': issueDescription,
      'userId': userId,
      'userEmail': userEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'acceptedBidId': acceptedBidId,
      'acceptedFixerId': acceptedFixerId,
      'acceptedFixerName': acceptedFixerName,
      'finalPrice': finalPrice,
      'imageUrls': imageUrls,
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return RequestModel(
      id: id,
      deviceType: map['deviceType'] ?? 'Unknown Device',
      issueDescription: map['issueDescription'] ?? 'No description provided',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? 'No Email',
      createdAt: parseDate(map['createdAt']),
      status: map['status'] ?? 'pending',
      acceptedBidId: map['acceptedBidId'],
      acceptedFixerId: map['acceptedFixerId'],
      acceptedFixerName: map['acceptedFixerName'],
      finalPrice: (map['finalPrice'] ?? 0.0).toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }
}
