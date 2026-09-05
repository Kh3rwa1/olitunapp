// ============== PURCHASE MODEL ==============
class PurchaseModel {
  final String id;
  final String userId;
  final String categoryId;
  final String unlockMethod;
  final int amountPaidInr;
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final String? razorpaySignature;
  final String? reviewCompletedAt;
  final String? reviewPlatform;
  final String status;
  final String purchasedAt;
  final String? verifiedAt;

  PurchaseModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.unlockMethod,
    required this.amountPaidInr,
    this.razorpayPaymentId,
    this.razorpayOrderId,
    this.razorpaySignature,
    this.reviewCompletedAt,
    this.reviewPlatform,
    required this.status,
    required this.purchasedAt,
    this.verifiedAt,
  });

  static int _wholeInr(Object? value, String field) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    if (value is String && RegExp(r'^-?\d+$').hasMatch(value.trim())) {
      return int.parse(value.trim());
    }
    throw FormatException('$field must be a whole INR amount');
  }

  factory PurchaseModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    final canonicalAmountPresent = data.containsKey('paidAmount');
    return PurchaseModel(
      id: docId ?? data['\$id'] as String? ?? data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      unlockMethod: data['provider'] as String? ?? data['unlockMethod'] as String? ?? 'razorpay',
      amountPaidInr: _wholeInr(
        canonicalAmountPresent ? data['paidAmount'] : data['amountPaidInr'],
        canonicalAmountPresent ? 'paidAmount' : 'amountPaidInr',
      ),
      razorpayPaymentId: data['providerPaymentId'] as String? ?? data['razorpayPaymentId'] as String?,
      razorpayOrderId: data['providerOrderId'] as String? ?? data['razorpayOrderId'] as String?,
      razorpaySignature: data['razorpaySignature'] as String?,
      reviewCompletedAt: data['reviewCompletedAt'] as String?,
      reviewPlatform: data['reviewPlatform'] as String?,
      status: data['status'] as String? ?? 'pending',
      purchasedAt: data['paidAt'] as String? ?? data['purchasedAt'] as String? ?? data['\$createdAt'] as String? ?? '',
      verifiedAt: data['verifiedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'categoryId': categoryId,
    'provider': unlockMethod,
    'providerPaymentId': razorpayPaymentId,
    'providerOrderId': razorpayOrderId,
    'paidAmount': amountPaidInr,
    'paidAt': purchasedAt,
    'unlockMethod': unlockMethod,
    'amountPaidInr': amountPaidInr,
    'razorpayPaymentId': razorpayPaymentId,
    'razorpayOrderId': razorpayOrderId,
    'razorpaySignature': razorpaySignature,
    'reviewCompletedAt': reviewCompletedAt,
    'reviewPlatform': reviewPlatform,
    'status': status,
    'purchasedAt': purchasedAt,
    'verifiedAt': verifiedAt,
  };

  PurchaseModel copyWith({
    String? id, String? userId, String? categoryId, String? unlockMethod,
    int? amountPaidInr, String? razorpayPaymentId, String? razorpayOrderId,
    String? razorpaySignature, String? reviewCompletedAt, String? reviewPlatform,
    String? status, String? purchasedAt, String? verifiedAt,
  }) => PurchaseModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    categoryId: categoryId ?? this.categoryId,
    unlockMethod: unlockMethod ?? this.unlockMethod,
    amountPaidInr: amountPaidInr ?? this.amountPaidInr,
    razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
    razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
    razorpaySignature: razorpaySignature ?? this.razorpaySignature,
    reviewCompletedAt: reviewCompletedAt ?? this.reviewCompletedAt,
    reviewPlatform: reviewPlatform ?? this.reviewPlatform,
    status: status ?? this.status,
    purchasedAt: purchasedAt ?? this.purchasedAt,
    verifiedAt: verifiedAt ?? this.verifiedAt,
  );
}
