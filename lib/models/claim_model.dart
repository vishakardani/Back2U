import 'item_model.dart';

class Claim {
  final String id;
  final String itemId;
  final String claimantId;
  final String? message;
  final String status; // 'pending', 'confirmed', 'rejected'
  final String? rejectionReason;
  final String? confirmedAt;
  final String? rejectedAt;
  final String createdAt;
  final UniversityItem? item;
  final User? claimant;

  Claim({
    required this.id,
    required this.itemId,
    required this.claimantId,
    this.message,
    required this.status,
    this.rejectionReason,
    this.confirmedAt,
    this.rejectedAt,
    required this.createdAt,
    this.item,
    this.claimant,
  });

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      id: json['id'] ?? '',
      itemId: json['item_id'] ?? '',
      claimantId: json['claimant_id'] ?? '',
      message: json['message'],
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
      confirmedAt: json['confirmed_at'],
      rejectedAt: json['rejected_at'],
      createdAt: json['created_at'] ?? '',
      item: json['items'] != null ? UniversityItem.fromJson(json['items']) : null,
      claimant: json['claimants'] != null ? User.fromJson(json['claimants']) : null,
    );
  }
}
