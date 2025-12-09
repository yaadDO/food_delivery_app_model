// payment_settings.dart - Updated
class PaymentSettings {
  final bool allowCashOnDelivery;
  final bool allowPaystack;
  final bool deliveryFeeEnabled;
  final double deliveryFeeAmount;
  final bool allowPickup;
  final DateTime lastUpdated;

  PaymentSettings({
    required this.allowCashOnDelivery,
    required this.allowPaystack,
    required this.deliveryFeeEnabled,
    required this.deliveryFeeAmount,
    required this.allowPickup,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'allowCashOnDelivery': allowCashOnDelivery,
      'allowPaystack': allowPaystack,
      'deliveryFeeEnabled': deliveryFeeEnabled,
      'deliveryFeeAmount': deliveryFeeAmount,
      'allowPickup': allowPickup,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory PaymentSettings.fromMap(Map<String, dynamic> map) {
    return PaymentSettings(
      allowCashOnDelivery: map['allowCashOnDelivery'] as bool? ?? true,
      allowPaystack: map['allowPaystack'] as bool? ?? true,
      deliveryFeeEnabled: map['deliveryFeeEnabled'] as bool? ?? false,
      deliveryFeeAmount: (map['deliveryFeeAmount'] as num?)?.toDouble() ?? 5.0,
      allowPickup: map['allowPickup'] as bool? ?? true,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  PaymentSettings copyWith({
    bool? allowCashOnDelivery,
    bool? allowPaystack,
    bool? deliveryFeeEnabled,
    double? deliveryFeeAmount,
    bool? allowPickup,
    DateTime? lastUpdated,
  }) {
    return PaymentSettings(
      allowCashOnDelivery: allowCashOnDelivery ?? this.allowCashOnDelivery,
      allowPaystack: allowPaystack ?? this.allowPaystack,
      deliveryFeeEnabled: deliveryFeeEnabled ?? this.deliveryFeeEnabled,
      deliveryFeeAmount: deliveryFeeAmount ?? this.deliveryFeeAmount,
      allowPickup: allowPickup ?? this.allowPickup,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}