class PaymentSettings {
  final bool allowCashOnDelivery;
  final bool allowPaystack;
  final DateTime lastUpdated;

  PaymentSettings({
    required this.allowCashOnDelivery,
    required this.allowPaystack,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'allowCashOnDelivery': allowCashOnDelivery,
      'allowPaystack': allowPaystack,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory PaymentSettings.fromMap(Map<String, dynamic> map) {
    return PaymentSettings(
      allowCashOnDelivery: map['allowCashOnDelivery'] as bool? ?? true,
      allowPaystack: map['allowPaystack'] as bool? ?? true,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  PaymentSettings copyWith({
    bool? allowCashOnDelivery,
    bool? allowPaystack,
    DateTime? lastUpdated,
  }) {
    return PaymentSettings(
      allowCashOnDelivery: allowCashOnDelivery ?? this.allowCashOnDelivery,
      allowPaystack: allowPaystack ?? this.allowPaystack,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
