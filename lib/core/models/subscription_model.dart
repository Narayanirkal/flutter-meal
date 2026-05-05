class SubscriptionModel {
  final String id;
  final String planName;
  final String price;
  final String billingCycle;
  final int durationDays;
  final int trialDays;
  final List<String> features;
  final int displayOrder;
  final bool? isActive;
  final int? mealSizeId;

  SubscriptionModel({
    required this.id,
    required this.planName,
    required this.price,
    required this.billingCycle,
    required this.durationDays,
    required this.trialDays,
    required this.features,
    required this.displayOrder,
    this.isActive,
    this.mealSizeId,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'],
      planName: json['plan_name'],
      price: json['price'],
      billingCycle: json['billing_cycle'],
      durationDays: int.tryParse('${json['duration_days'] ?? 0}') ?? 0,
      trialDays: int.tryParse('${json['trial_days'] ?? 0}') ?? 0,
      features: ((json['features'] as List?) ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      displayOrder: int.tryParse('${json['display_order'] ?? 0}') ?? 0,
      isActive: json['is_active'],
      mealSizeId: json['meal_size_id'],
    );
  }
}
