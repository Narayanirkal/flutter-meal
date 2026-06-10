class ReferralRewardModel {
  final int id;
  final int mealsRewarded;
  final String status;
  final String? allocatedEntityType;
  final String? allocatedEntityId;
  final DateTime? allocatedAt;
  final DateTime createdAt;
  final String referredUsername;

  ReferralRewardModel({
    required this.id,
    required this.mealsRewarded,
    required this.status,
    this.allocatedEntityType,
    this.allocatedEntityId,
    this.allocatedAt,
    required this.createdAt,
    required this.referredUsername,
  });

  factory ReferralRewardModel.fromJson(Map<String, dynamic> json) {
    return ReferralRewardModel(
      id: json['id'] as int,
      mealsRewarded: json['meals_rewarded'] as int,
      status: json['status'] as String,
      allocatedEntityType: json['allocated_entity_type'] as String?,
      allocatedEntityId: json['allocated_entity_id'] as String?,
      allocatedAt: json['allocated_at'] != null
          ? DateTime.parse(json['allocated_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      referredUsername: json['referred_username'] as String? ?? 'User',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'meals_rewarded': mealsRewarded,
        'status': status,
        'allocated_entity_type': allocatedEntityType,
        'allocated_entity_id': allocatedEntityId,
        'allocated_at': allocatedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'referred_username': referredUsername,
      };
}
