import '../models/campaign.dart';
import '../models/user.dart';

class DummyData {
  static final User currentUser = User(
    id: 'user_1',
    name: 'Rahul Sharma',
    email: 'rahul.sharma@example.com',
    phoneNumber: '+91 98765 43210',
    upiId: 'rahul.sharma@okaxis',
    joinedAt: DateTime.now().subtract(const Duration(days: 120)),
  );

  static final List<Campaign> allCampaigns = [
    Campaign(
      id: 'camp_1',
      title: 'Help Priya for Surgery',
      description:
          'My friend Priya needs urgent surgery for her heart condition. She\'s a bright student who can\'t afford the medical expenses. Any help would mean the world to her.',
      purpose: 'Medical',
      targetAmount: 75000,
      collectedAmount: 45000,
      hostId: 'user_2',
      hostName: 'Amit Kumar',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      status: 'active',
      contributions: [
        Contribution(
          id: 'cont_1',
          campaignId: 'camp_1',
          contributorId: 'user_1',
          contributorName: 'Rahul Sharma',
          amount: 5000,
          type: 'gift',
          date: DateTime.now().subtract(const Duration(days: 5)),
          utrNumber: 'UTR123456789',
        ),
        Contribution(
          id: 'cont_2',
          campaignId: 'camp_1',
          contributorId: 'user_3',
          contributorName: 'Sneha Patel',
          amount: 10000,
          type: 'loan',
          date: DateTime.now().subtract(const Duration(days: 4)),
          repaymentStatus: 'pending',
          repaymentDueDate: DateTime.now().add(const Duration(days: 90)),
          utrNumber: 'UTR987654321',
        ),
        Contribution(
          id: 'cont_3',
          campaignId: 'camp_1',
          contributorId: 'user_4',
          contributorName: 'Anonymous',
          amount: 30000,
          type: 'gift',
          date: DateTime.now().subtract(const Duration(days: 2)),
          utrNumber: 'UTR456789123',
        ),
      ],
    ),
    Campaign(
      id: 'camp_2',
      title: 'Books for Rural School',
      description:
          'Our village school needs new books and educational materials. Help us provide quality education to 200+ children who dream of a better future.',
      purpose: 'Education',
      targetAmount: 25000,
      collectedAmount: 18500,
      hostId: 'user_5',
      hostName: 'Kavya Singh',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      status: 'active',
      contributions: [
        Contribution(
          id: 'cont_4',
          campaignId: 'camp_2',
          contributorId: 'user_1',
          contributorName: 'Rahul Sharma',
          amount: 2500,
          type: 'gift',
          date: DateTime.now().subtract(const Duration(days: 10)),
          utrNumber: 'UTR789123456',
        ),
        Contribution(
          id: 'cont_5',
          campaignId: 'camp_2',
          contributorId: 'user_6',
          contributorName: 'Vikas Gupta',
          amount: 16000,
          type: 'gift',
          date: DateTime.now().subtract(const Duration(days: 8)),
          utrNumber: 'UTR654321987',
        ),
      ],
    ),
    Campaign(
      id: 'camp_3',
      title: 'Startup Fund for Tech Innovation',
      description:
          'Building an AI-powered healthcare app to help rural communities access quality medical advice. Looking for initial funding to build MVP.',
      purpose: 'Business',
      targetAmount: 100000,
      collectedAmount: 35000,
      hostId: 'user_1',
      hostName: 'Rahul Sharma',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      status: 'active',
      contributions: [
        Contribution(
          id: 'cont_6',
          campaignId: 'camp_3',
          contributorId: 'user_7',
          contributorName: 'Ravi Menon',
          amount: 25000,
          type: 'loan',
          date: DateTime.now().subtract(const Duration(days: 18)),
          repaymentStatus: 'pending',
          repaymentDueDate: DateTime.now().add(const Duration(days: 180)),
          utrNumber: 'UTR321987654',
        ),
        Contribution(
          id: 'cont_7',
          campaignId: 'camp_3',
          contributorId: 'user_8',
          contributorName: 'Neha Joshi',
          amount: 10000,
          type: 'gift',
          date: DateTime.now().subtract(const Duration(days: 15)),
          utrNumber: 'UTR147258369',
        ),
      ],
    ),
    Campaign(
      id: 'camp_4',
      title: 'Emergency Fund for Flood Relief',
      description:
          'Recent floods have affected many families in our area. They need immediate help for food, shelter, and basic necessities.',
      purpose: 'Emergency',
      targetAmount: 150000,
      collectedAmount: 89000,
      hostId: 'user_9',
      hostName: 'Deepak Yadav',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      status: 'active',
      contributions: [
        Contribution(
          id: 'cont_8',
          campaignId: 'camp_4',
          contributorId: 'user_1',
          contributorName: 'Rahul Sharma',
          amount: 15000,
          type: 'gift',
          date: DateTime.now().subtract(const Duration(days: 2)),
          utrNumber: 'UTR963852741',
        ),
      ],
    ),
  ];

  static List<Campaign> getMyCampaigns() {
    return allCampaigns
        .where((campaign) => campaign.hostId == currentUser.id)
        .toList();
  }

  static List<Contribution> getMyContributions() {
    List<Contribution> myContributions = [];
    for (var campaign in allCampaigns) {
      myContributions.addAll(
        campaign.contributions.where(
          (contrib) => contrib.contributorId == currentUser.id,
        ),
      );
    }
    return myContributions;
  }

  static List<Contribution> getLoansToRepay() {
    List<Contribution> loansToRepay = [];
    for (var campaign in allCampaigns) {
      if (campaign.hostId == currentUser.id) {
        loansToRepay.addAll(
          campaign.contributions.where(
            (contrib) =>
                contrib.type == 'loan' && contrib.repaymentStatus == 'pending',
          ),
        );
      }
    }
    return loansToRepay;
  }

  static final List<String> purposeOptions = [
    'Medical',
    'Education',
    'Emergency',
    'Business',
    'Personal',
    'Community',
    'Sports',
    'Travel',
  ];
}
