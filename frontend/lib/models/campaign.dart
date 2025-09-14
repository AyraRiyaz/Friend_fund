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
  });

  double get progressPercentage =>
      targetAmount > 0 ? (collectedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

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
    };
  }
}

class Contribution {
  final String id;
  final String campaignId;
  final String contributorId;
  final String contributorName;
  final double amount;
  final String type; // 'gift', 'loan'
  final DateTime date;
  final String? repaymentStatus; // 'pending', 'repaid' (for loans only)
  final DateTime? repaymentDueDate;
  final String utrNumber;

  Contribution({
    required this.id,
    required this.campaignId,
    required this.contributorId,
    required this.contributorName,
    required this.amount,
    required this.type,
    required this.date,
    this.repaymentStatus,
    this.repaymentDueDate,
    required this.utrNumber,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'] ?? json['\$id'] ?? '',
      campaignId: json['campaignId'] ?? '',
      contributorId: json['contributorId'] ?? '',
      contributorName: json['contributorName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'gift',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      repaymentStatus: json['repaymentStatus'],
      repaymentDueDate: json['repaymentDueDate'] != null
          ? DateTime.parse(json['repaymentDueDate'])
          : null,
      utrNumber: json['utrNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaignId': campaignId,
      'contributorId': contributorId,
      'contributorName': contributorName,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'repaymentStatus': repaymentStatus,
      'repaymentDueDate': repaymentDueDate?.toIso8601String(),
      'utrNumber': utrNumber,
    };
  }
}
