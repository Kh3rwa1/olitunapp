// ============== PURCHASE MODEL ==============
class PurchaseModel {
  final String id;
  final String userId;
  final String categoryId;
  final String unlockMethod; // 'razorpay', 'play_store_review'
  final int amountPaidInr;
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final String? razorpaySignature;
  final String? reviewCompletedAt;
  final String? reviewPlatform;
  final String status; // 'pending', 'verified', 'failed', 'refunded'
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

  factory PurchaseModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return PurchaseModel(
      id: docId ?? data['\$id'] as String? ?? data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      unlockMethod: data['unlockMethod'] as String? ?? 'razorpay',
      amountPaidInr: data['amountPaidInr'] as int? ?? 0,
      razorpayPaymentId: data['razorpayPaymentId'] as String?,
      razorpayOrderId: data['razorpayOrderId'] as String?,
      razorpaySignature: data['razorpaySignature'] as String?,
      reviewCompletedAt: data['reviewCompletedAt'] as String?,
      reviewPlatform: data['reviewPlatform'] as String?,
      status: data['status'] as String? ?? 'pending',
      purchasedAt: data['purchasedAt'] as String? ?? '',
      verifiedAt: data['verifiedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
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
  }

  PurchaseModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? unlockMethod,
    int? amountPaidInr,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
    String? reviewCompletedAt,
    String? reviewPlatform,
    String? status,
    String? purchasedAt,
    String? verifiedAt,
  }) {
    return PurchaseModel(
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
}
