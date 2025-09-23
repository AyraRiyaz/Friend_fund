class LoanRepayment {
  final String id;
  final String loanContributionId; // Reference to original loan contribution
  final String repayerId; // User who is repaying the loan
  final double amount;
  final String utr; // UTR number for repayment transaction
  final String paymentScreenshotUrl; // Screenshot of payment confirmation
  final String status; // 'pending', 'verified', 'rejected'
  final DateTime createdAt;
  final DateTime updatedAt;

  LoanRepayment({
    required this.id,
    required this.loanContributionId,
    required this.repayerId,
    required this.amount,
    required this.utr,
    required this.paymentScreenshotUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  LoanRepayment copyWith({
    String? id,
    String? loanContributionId,
    String? repayerId,
    double? amount,
    String? utr,
    String? paymentScreenshotUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanRepayment(
      id: id ?? this.id,
      loanContributionId: loanContributionId ?? this.loanContributionId,
      repayerId: repayerId ?? this.repayerId,
      amount: amount ?? this.amount,
      utr: utr ?? this.utr,
      paymentScreenshotUrl: paymentScreenshotUrl ?? this.paymentScreenshotUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory LoanRepayment.fromJson(Map<String, dynamic> json) {
    return LoanRepayment(
      id: json['id'] ?? json['\$id'] ?? '',
      loanContributionId: json['loanContributionId'] ?? '',
      repayerId: json['repayerId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      utr: json['utr'] ?? '',
      paymentScreenshotUrl: json['paymentScreenshotUrl'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['\$createdAt'] != null
                ? DateTime.parse(json['\$createdAt'])
                : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['\$updatedAt'] != null
                ? DateTime.parse(json['\$updatedAt'])
                : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loanContributionId': loanContributionId,
      'repayerId': repayerId,
      'amount': amount,
      'utr': utr,
      'paymentScreenshotUrl': paymentScreenshotUrl,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
