class BulkOrderConfig {
  final int minQuantity;
  final int minLeadDays;
  final int tierThreshold;
  final double pricePerMealUnderThreshold;
  final int varietyMenuLookaheadDays;
  final int maxVarietyTypes;
  final bool allowMultipleVarietyMeals;
  final int minQuantityPerVarietyMeal;
  final bool isActive;
  final String earliestDeliveryDate;
  final List<BulkVarietyPrice> varietyPrices;

  BulkOrderConfig({
    required this.minQuantity,
    required this.minLeadDays,
    required this.tierThreshold,
    required this.pricePerMealUnderThreshold,
    required this.varietyMenuLookaheadDays,
    required this.maxVarietyTypes,
    required this.allowMultipleVarietyMeals,
    required this.minQuantityPerVarietyMeal,
    required this.isActive,
    required this.earliestDeliveryDate,
    required this.varietyPrices,
  });

  factory BulkOrderConfig.fromJson(Map<String, dynamic> json) {
    final prices = json['variety_prices'];
    return BulkOrderConfig(
      minQuantity: int.tryParse('${json['min_quantity'] ?? 10}') ?? 10,
      minLeadDays: int.tryParse('${json['min_lead_days'] ?? 3}') ?? 3,
      tierThreshold: int.tryParse('${json['tier_threshold'] ?? 50}') ?? 50,
      pricePerMealUnderThreshold:
          double.tryParse('${json['price_per_meal_under_threshold'] ?? 0}') ?? 0,
      varietyMenuLookaheadDays:
          int.tryParse('${json['variety_menu_lookahead_days'] ?? 14}') ?? 14,
      maxVarietyTypes: int.tryParse('${json['max_variety_types'] ?? 5}') ?? 5,
      allowMultipleVarietyMeals: json['allow_multiple_variety_meals'] != false,
      minQuantityPerVarietyMeal:
          int.tryParse('${json['min_quantity_per_variety_meal'] ?? 1}') ?? 1,
      isActive: json['is_active'] != false,
      earliestDeliveryDate: '${json['earliest_delivery_date'] ?? ''}',
      varietyPrices: prices is List
          ? prices
              .map((e) => BulkVarietyPrice.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
    );
  }
}

class BulkVarietyPrice {
  final int slotNumber;
  final double pricePerMeal;

  BulkVarietyPrice({required this.slotNumber, required this.pricePerMeal});

  factory BulkVarietyPrice.fromJson(Map<String, dynamic> json) {
    return BulkVarietyPrice(
      slotNumber: int.tryParse('${json['slot_number'] ?? 0}') ?? 0,
      pricePerMeal: double.tryParse('${json['price_per_meal'] ?? 0}') ?? 0,
    );
  }
}

class BulkMenuOption {
  final String id;
  final String menuDate;
  final String items;
  final String? imageUrl;
  final double? pricePerMeal;
  final int minOrderQuantity;

  BulkMenuOption({
    required this.id,
    required this.menuDate,
    required this.items,
    this.imageUrl,
    this.pricePerMeal,
    this.minOrderQuantity = 1,
  });

  factory BulkMenuOption.fromJson(Map<String, dynamic> json) {
    final price = json['price_per_meal'];
    return BulkMenuOption(
      id: '${json['id']}',
      menuDate: '${json['menu_date'] ?? ''}',
      items: '${json['name'] ?? json['items'] ?? ''}',
      imageUrl: json['image_url'] as String?,
      pricePerMeal: price == null ? null : double.tryParse('$price'),
      minOrderQuantity:
          int.tryParse('${json['min_order_quantity'] ?? 1}') ?? 1,
    );
  }
}
