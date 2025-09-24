class Campaign {
  final String id;
  final String title;
  final String description;
  final String purpose;
  final double targetAmount;
  final double collectedAmount;
  final String hostId;
  final String hostName;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String status; // 'active', 'closed', 'paused'
  final List<Contribution> contributions;
  final String? upiId; // Host's UPI ID for payments
  final String? qrCodeUrl; // Generated QR code image URL
  final String? shareableUrl; // Shareable campaign URL

  Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.purpose,
    required this.targetAmount,
    required this.collectedAmount,
    required this.hostId,
    required this.hostName,
    required this.createdAt,
    this.dueDate,
    required this.status,
    required this.contributions,
    this.upiId,
    this.qrCodeUrl,
    this.shareableUrl,
  });

  double get progressPercentage =>
      targetAmount > 0 ? (collectedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  Campaign copyWith({
    String? id,
    String? title,
    String? description,
    String? purpose,
    double? targetAmount,
    double? collectedAmount,
    String? hostId,
    String? hostName,
    DateTime? createdAt,
    DateTime? dueDate,
    String? status,
    List<Contribution>? contributions,
    String? upiId,
    String? qrCodeUrl,
    String? shareableUrl,
  }) {
    return Campaign(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      purpose: purpose ?? this.purpose,
      targetAmount: targetAmount ?? this.targetAmount,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      contributions: contributions ?? this.contributions,
      upiId: upiId ?? this.upiId,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      shareableUrl: shareableUrl ?? this.shareableUrl,
    );
  }

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] ?? json['\$id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      purpose: json['purpose'] ?? '',
      targetAmount: (json['targetAmount'] ?? 0).toDouble(),
      collectedAmount: (json['collectedAmount'] ?? 0).toDouble(),
      hostId: json['hostId'] ?? '',
      hostName: json['hostName'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      status: json['status'] ?? 'active',
      contributions: (json['contributions'] as List? ?? [])
          .map((contrib) => Contribution.fromJson(contrib))
          .toList(),
      upiId: json['upiId'],
      qrCodeUrl: json['qrCodeUrl'],
      shareableUrl: json['shareableUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'purpose': purpose,
      'targetAmount': targetAmount,
      'collectedAmount': collectedAmount,
      'hostId': hostId,
      'hostName': hostName,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'status': status,
      'contributions': contributions
          .map((contrib) => contrib.toJson())
          .toList(),
      'upiId': upiId,
      'qrCodeUrl': qrCodeUrl,
      'shareableUrl': shareableUrl,
    };
  }
}

class Contribution {
  final String id;
  final String campaignId;
  final String? contributorId; // Optional for anonymous contributions
  final String contributorName;
  final double amount;
  final String type; // 'gift', 'loan'
  final DateTime date;
  final String? repaymentStatus; // 'pending', 'repaid' (for loans only)
  final DateTime? repaymentDueDate;
  final String utr;
  final String? paymentScreenshotUrl; // Screenshot of payment confirmation
  final String? paymentStatus; // 'pending', 'verified', 'failed'
  final bool isAnonymous; // True if contributor is not logged in

  Contribution({
    required this.id,
    required this.campaignId,
    this.contributorId, // Optional for anonymous contributions
    required this.contributorName,
    required this.amount,
    required this.type,
    required this.date,
    this.repaymentStatus,
    this.repaymentDueDate,
    required this.utr,
    this.paymentScreenshotUrl,
    this.paymentStatus,
    this.isAnonymous = false,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'] ?? json['\$id'] ?? '',
      campaignId: json['campaignId'] ?? '',
      contributorId:
          json['contributorId'], // Can be null for anonymous contributions
      contributorName: json['contributorName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'gift',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : (json['\$createdAt'] != null
                ? DateTime.parse(json['\$createdAt'])
                : (json['createdAt'] != null
                      ? DateTime.parse(json['createdAt'])
                      : DateTime.now())),
      repaymentStatus: json['repaymentStatus'],
      repaymentDueDate: json['repaymentDueDate'] != null
          ? DateTime.parse(json['repaymentDueDate'])
          : null,
      utr:
          json['utr'] ??
          json['utrNumber'] ??
          '', // Support both field names for backward compatibility
      paymentScreenshotUrl: json['paymentScreenshotUrl'],
      paymentStatus: json['paymentStatus'] ?? 'pending',
      isAnonymous: json['isAnonymous'] ?? (json['contributorId'] == null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaignId': campaignId,
      'contributorId': contributorId, // Can be null for anonymous contributions
      'contributorName': contributorName,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'repaymentStatus': repaymentStatus,
      'repaymentDueDate': repaymentDueDate?.toIso8601String(),
      'utr': utr,
      'paymentScreenshotUrl': paymentScreenshotUrl,
      'paymentStatus': paymentStatus,
      'isAnonymous': isAnonymous,
    };
  }
}
