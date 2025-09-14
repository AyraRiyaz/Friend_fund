import 'package:flutter/material.dart';

class ContributionCard extends StatelessWidget {
  final String contributor;
  final double amount;
  final String type; // 'Gift' or 'Loan'
  final String date;
  final String? repaymentStatus; // 'Pending' or 'Repaid', only for loans
  final VoidCallback? onMarkRepaid;
  const ContributionCard({
    Key? key,
    required this.contributor,
    required this.amount,
    required this.type,
    required this.date,
    this.repaymentStatus,
    this.onMarkRepaid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              type == 'Loan' ? Icons.handshake : Icons.card_giftcard,
              color: Colors.teal,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contributor,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    type,
                    style: TextStyle(
                      color: type == 'Loan' ? Colors.orange : Colors.green,
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  if (type == 'Loan' && repaymentStatus != null)
                    Row(
                      children: [
                        Text('Status: ', style: const TextStyle(fontSize: 12)),
                        Text(
                          repaymentStatus!,
                          style: TextStyle(
                            color: repaymentStatus == 'Repaid'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (repaymentStatus == 'Pending' &&
                            onMarkRepaid != null)
                          TextButton(
                            onPressed: onMarkRepaid,
                            child: const Text('Mark as Repaid'),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
