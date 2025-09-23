/**
 * FriendFund Appwrite Function Entry Point
 * This is the main entry point for the Appwrite Function deployment
 * Author: Ayra Riyaz
 */

import {
  Client,
  Databases,
  Storage,
  Users,
  ID,
  Query,
  Permission,
  Role,
} from "node-appwrite";
import QRCode from "qrcode";
import { createWorker } from "tesseract.js";

/**
 * @class FriendFundAPI
 * @description Main class for handling FriendFund operations via Appwrite Function
 */
class FriendFundAPI {
  constructor() {
    this.client = new Client();
    this.databases = new Databases(this.client);
    this.storage = new Storage(this.client);
    this.users = new Users(this.client);

    // Initialize Appwrite client - for functions, these are automatically available
    this.client
      .setEndpoint(
        process.env.APPWRITE_FUNCTION_ENDPOINT ||
          "https://fra.cloud.appwrite.io/v1"
      )
      .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
      .setKey(process.env.APPWRITE_API_KEY);

    this.databaseId =
      process.env.APPWRITE_DATABASE_ID || "68b5433d0004cadff5ff";
    this.campaignsCollectionId =
      process.env.CAMPAIGNS_COLLECTION_ID || "68b54652001a8a757571";
    this.contributionsCollectionId =
      process.env.CONTRIBUTIONS_COLLECTION_ID || "68b54a0700208ba7fdaa";
    this.loanRepaymentsCollectionId =
      process.env.LOAN_REPAYMENTS_COLLECTION_ID || "68d2c85b000062e1be7b";
    this.screenshotsBucketId =
      process.env.SCREENSHOTS_BUCKET_ID || "68c66749001ad2d77cfa";
  }

  // Campaign Operations
  async getAllCampaigns(queries = []) {
    try {
      const response = await this.databases.listDocuments(
        this.databaseId,
        this.campaignsCollectionId,
        queries
      );

      return {
        success: true,
        data: response.documents,
        total: response.total,
      };
    } catch (error) {
      console.error("Error getting campaigns:", error);
      return {
        success: false,
        error: error.message || "Failed to get campaigns",
      };
    }
  }

  async getCampaign(campaignId) {
    try {
      const campaign = await this.databases.getDocument(
        this.databaseId,
        this.campaignsCollectionId,
        campaignId
      );

      // Get contributions for this campaign
      const contributions = await this.databases.listDocuments(
        this.databaseId,
        this.contributionsCollectionId,
        [Query.equal("campaignId", campaignId)]
      );

      return {
        success: true,
        data: {
          ...campaign,
          contributions: contributions.documents,
        },
      };
    } catch (error) {
      console.error("Error getting campaign:", error);
      return {
        success: false,
        error: error.message || "Campaign not found",
      };
    }
  }

  async createCampaign(campaignData) {
    try {
      // Generate unique campaign ID
      const campaignId = ID.unique();

      // Generate shareable URL for the campaign
      const shareableUrl = `${
        process.env.FRONTEND_URL || "http://localhost:8080"
      }/contribute/${campaignId}`;

      // Generate QR code for the shareable URL
      let qrCodeDataUrl = null;
      try {
        qrCodeDataUrl = await QRCode.toDataURL(shareableUrl, {
          width: 300,
          margin: 2,
          color: {
            dark: "#000000",
            light: "#FFFFFF",
          },
        });
      } catch (qrError) {
        console.warn("QR code generation failed:", qrError);
      }

      const campaign = await this.databases.createDocument(
        this.databaseId,
        this.campaignsCollectionId,
        campaignId,
        {
          ...campaignData,
          status: campaignData.status || "active",
          collectedAmount: 0,
          contributions: [],
          shareableUrl: shareableUrl,
          qrCodeUrl: qrCodeDataUrl,
        },
        [Permission.read(Role.any())]
      );

      return {
        success: true,
        data: campaign,
      };
    } catch (error) {
      console.error("Error creating campaign:", error);
      return {
        success: false,
        error: error.message || "Failed to create campaign",
      };
    }
  }

  async updateCampaign(campaignId, updateData) {
    try {
      const campaign = await this.databases.updateDocument(
        this.databaseId,
        this.campaignsCollectionId,
        campaignId,
        updateData
      );

      return {
        success: true,
        data: campaign,
      };
    } catch (error) {
      console.error("Error updating campaign:", error);
      return {
        success: false,
        error: error.message || "Failed to update campaign",
      };
    }
  }

  async deleteCampaign(campaignId) {
    try {
      await this.databases.deleteDocument(
        this.databaseId,
        this.campaignsCollectionId,
        campaignId
      );

      return {
        success: true,
        message: "Campaign deleted successfully",
      };
    } catch (error) {
      console.error("Error deleting campaign:", error);
      return {
        success: false,
        error: error.message || "Failed to delete campaign",
      };
    }
  }

  async getCampaignForContribution(campaignId) {
    try {
      const campaign = await this.databases.getDocument(
        this.databaseId,
        this.campaignsCollectionId,
        campaignId
      );

      // Return only necessary fields for contribution form
      return {
        success: true,
        data: {
          id: campaign.$id,
          title: campaign.title,
          description: campaign.description,
          purpose: campaign.purpose,
          targetAmount: campaign.targetAmount,
          collectedAmount: campaign.collectedAmount,
          hostName: campaign.hostName,
          upiId: campaign.upiId,
          status: campaign.status,
        },
      };
    } catch (error) {
      console.error("Error getting campaign for contribution:", error);
      return {
        success: false,
        error: error.message || "Campaign not found",
      };
    }
  }

  // Contribution Operations
  async getCampaignContributions(campaignId) {
    try {
      const contributions = await this.databases.listDocuments(
        this.databaseId,
        this.contributionsCollectionId,
        [Query.equal("campaignId", campaignId)]
      );

      return {
        success: true,
        data: contributions.documents,
        total: contributions.total,
      };
    } catch (error) {
      console.error("Error getting contributions:", error);
      return {
        success: false,
        error: error.message || "Failed to get contributions",
      };
    }
  }

  async getUserContributions(userId) {
    try {
      const contributions = await this.databases.listDocuments(
        this.databaseId,
        this.contributionsCollectionId,
        [Query.equal("contributorId", userId)]
      );

      return {
        success: true,
        data: contributions.documents,
        total: contributions.total,
      };
    } catch (error) {
      console.error("Error getting user contributions:", error);
      return {
        success: false,
        error: error.message || "Failed to get user contributions",
      };
    }
  }

  async createContribution(contributionData) {
    try {
      // Create contribution record
      const contribution = await this.databases.createDocument(
        this.databaseId,
        this.contributionsCollectionId,
        ID.unique(),
        {
          ...contributionData,
          repaymentStatus: contributionData.repaymentStatus || "pending",
          type: contributionData.type || "donation",
          isAnonymous: contributionData.isAnonymous || false,
          paymentStatus: contributionData.paymentStatus || "pending",
        },
        [Permission.read(Role.any())]
      );

      // Only update campaign collected amount if payment is verified
      if (contributionData.paymentStatus === "verified") {
        const campaign = await this.databases.getDocument(
          this.databaseId,
          this.campaignsCollectionId,
          contributionData.campaignId
        );

        await this.databases.updateDocument(
          this.databaseId,
          this.campaignsCollectionId,
          contributionData.campaignId,
          {
            collectedAmount:
              (parseFloat(campaign.collectedAmount) || 0) +
              parseFloat(contributionData.amount),
          }
        );
      }

      return {
        success: true,
        data: contribution,
      };
    } catch (error) {
      console.error("Error creating contribution:", error);
      return {
        success: false,
        error: error.message || "Failed to create contribution",
      };
    }
  }

  async updateContribution(contributionId, updateData) {
    try {
      const contribution = await this.databases.updateDocument(
        this.databaseId,
        this.contributionsCollectionId,
        contributionId,
        updateData
      );

      return {
        success: true,
        data: contribution,
      };
    } catch (error) {
      console.error("Error updating contribution:", error);
      return {
        success: false,
        error: error.message || "Failed to update contribution",
      };
    }
  }

  // UTR Duplication Check
  async checkUtrDuplication(utrNumber, campaignId) {
    try {
      // Query contributions with the same UTR number in the same campaign
      const existingContributions = await this.databases.listDocuments(
        this.databaseId,
        this.contributionsCollectionId,
        [Query.equal("campaignId", campaignId), Query.equal("utr", utrNumber)]
      );

      const isDuplicate = existingContributions.total > 0;

      return {
        success: true,
        data: {
          isDuplicate: isDuplicate,
          utrNumber: utrNumber,
          campaignId: campaignId,
          existingContributionsCount: existingContributions.total,
        },
      };
    } catch (error) {
      console.error("Error checking UTR duplication:", error);
      return {
        success: false,
        error: error.message || "Failed to check UTR duplication",
      };
    }
  }

  // QR Code Generation for UPI Payment
  async generatePaymentQRCode(campaignId, upiId, amount = null) {
    try {
      // Get campaign details
      const campaign = await this.databases.getDocument(
        this.databaseId,
        this.campaignsCollectionId,
        campaignId
      );

      if (!campaign) {
        throw new Error("Campaign not found");
      }

      // Create UPI payment URL
      const upiPaymentUrl = `upi://pay?pa=${upiId}&pn=${encodeURIComponent(
        campaign.title
      )}&mc=0000&tid=${campaignId}&tr=${campaignId}${Date.now()}&tn=${encodeURIComponent(
        `Contribution to ${campaign.title}`
      )}${amount ? `&am=${amount}` : ""}&cu=INR`;

      // Generate QR code for UPI payment
      const qrCodeDataURL = await QRCode.toDataURL(upiPaymentUrl, {
        width: 400,
        margin: 2,
        color: {
          dark: "#000000",
          light: "#FFFFFF",
        },
      });

      // Also create a campaign URL for sharing
      const campaignUrl = `${
        process.env.FRONTEND_BASE_URL || "https://friendfund.pro26.in"
      }/campaign/${campaignId}`;

      return {
        success: true,
        data: {
          qrCode: qrCodeDataURL,
          upiPaymentUrl: upiPaymentUrl,
          campaignUrl: campaignUrl,
          upiId: upiId,
        },
      };
    } catch (error) {
      console.error("Error generating payment QR code:", error);
      return {
        success: false,
        error: error.message || "Failed to generate payment QR code",
      };
    }
  }

  // Legacy QR Code Generation (for campaign sharing)
  async generateQRCode(campaignId) {
    try {
      const campaignUrl = `${
        process.env.FRONTEND_BASE_URL || "https://friendfund.pro26.in"
      }/campaign/${campaignId}`;
      const qrCodeDataURL = await QRCode.toDataURL(campaignUrl);

      return {
        success: true,
        data: {
          qrCode: qrCodeDataURL,
          url: campaignUrl,
        },
      };
    } catch (error) {
      console.error("Error generating QR code:", error);
      return {
        success: false,
        error: error.message || "Failed to generate QR code",
      };
    }
  }

  // OCR-based Payment Processing
  async processPaymentScreenshot(
    imageBuffer,
    expectedAmount,
    contributorName,
    campaignId
  ) {
    try {
      // Initialize Tesseract worker
      const worker = await createWorker("eng");

      // Perform OCR on the image
      const {
        data: { text },
      } = await worker.recognize(imageBuffer);
      await worker.terminate();

      // Extract payment information from text
      const paymentInfo = this.extractPaymentInfo(text, expectedAmount);

      // Create contribution with OCR extracted data
      const contribution = await this.databases.createDocument(
        this.databaseId,
        this.contributionsCollectionId,
        ID.unique(),
        {
          campaignId: campaignId,
          contributorName: contributorName,
          amount: expectedAmount.toString(),
          paymentStatus: paymentInfo.isValid ? "verified" : "pending_review",
          extractedText: text,
          extractedAmount: paymentInfo.extractedAmount,
          transactionId: paymentInfo.transactionId,
          ocrConfidence: paymentInfo.confidence,
        },
        [Permission.read(Role.any())]
      );

      // Update campaign collected amount if payment is verified
      if (paymentInfo.isValid) {
        const campaign = await this.databases.getDocument(
          this.databaseId,
          this.campaignsCollectionId,
          campaignId
        );

        await this.databases.updateDocument(
          this.databaseId,
          this.campaignsCollectionId,
          campaignId,
          {
            collectedAmount:
              (parseFloat(campaign.collectedAmount) || 0) +
              parseFloat(expectedAmount),
          }
        );
      }

      return {
        success: true,
        data: {
          contribution: contribution,
          paymentInfo: paymentInfo,
          autoVerified: paymentInfo.isValid,
        },
      };
    } catch (error) {
      console.error("Error processing payment screenshot:", error);
      return {
        success: false,
        error: error.message || "Failed to process payment screenshot",
      };
    }
  }

  extractPaymentInfo(text, expectedAmount) {
    // Common UPI payment patterns
    const amountPatterns = [
      /₹\s*(\d+(?:,\d+)*(?:\.\d{2})?)/g,
      /INR\s*(\d+(?:,\d+)*(?:\.\d{2})?)/g,
      /Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)/g,
      /Amount.*?(\d+(?:,\d+)*(?:\.\d{2})?)/gi,
    ];

    // Transaction ID patterns
    const transactionPatterns = [
      /(?:Transaction|Txn|Trans|UPI|ID|Ref)\s*(?:ID|No|Number)?\s*:?\s*([A-Z0-9]+)/gi,
      /([0-9]{12,16})/g, // Common transaction ID length
      /([A-Z]{2,4}\d{10,14})/g, // Bank specific patterns
    ];

    // Success indicators
    const successIndicators = [
      /success/i,
      /completed/i,
      /paid/i,
      /transferred/i,
      /sent/i,
      /debited/i,
    ];

    let extractedAmount = null;
    let transactionId = null;
    let hasSuccessIndicator = false;

    // Extract amount
    for (const pattern of amountPatterns) {
      const matches = text.matchAll(pattern);
      for (const match of matches) {
        const amount = parseFloat(match[1].replace(/,/g, ""));
        if (amount > 0) {
          extractedAmount = amount;
          break;
        }
      }
      if (extractedAmount) break;
    }

    // Extract transaction ID
    for (const pattern of transactionPatterns) {
      const matches = text.matchAll(pattern);
      for (const match of matches) {
        if (match[1] && match[1].length >= 8) {
          transactionId = match[1];
          break;
        }
      }
      if (transactionId) break;
    }

    // Check for success indicators
    hasSuccessIndicator = successIndicators.some((pattern) =>
      pattern.test(text)
    );

    // Calculate confidence and validity
    let confidence = 0;
    if (extractedAmount) confidence += 40;
    if (transactionId) confidence += 30;
    if (hasSuccessIndicator) confidence += 30;

    const amountMatches =
      extractedAmount && Math.abs(extractedAmount - expectedAmount) <= 1; // Allow ₹1 difference for fees

    const isValid = confidence >= 70 && amountMatches && hasSuccessIndicator;

    return {
      extractedAmount,
      transactionId,
      hasSuccessIndicator,
      confidence,
      isValid,
      amountMatches,
    };
  }

  async uploadPaymentScreenshot(fileBuffer, fileName, contributionId) {
    try {
      console.log("Starting file upload:", {
        fileName,
        bufferSize: fileBuffer.length,
        contributionId,
      });

      // For Appwrite Functions, we might need to use a different approach
      // Let's try saving the base64 as a document instead of using storage
      const screenshotDocument = await this.databases.createDocument(
        this.databaseId,
        this.loanRepaymentsCollectionId, // Use loan repayments collection for screenshots
        ID.unique(),
        {
          type: "payment_screenshot",
          loanContributionId: contributionId,
          fileName: fileName,
          fileData: fileBuffer.toString("base64"), // Store as base64 string
          uploadDate: new Date().toISOString(),
        },
        [Permission.read(Role.any())]
      );

      // Create a pseudo file URL
      const fileUrl = `data:image/jpeg;base64,${fileBuffer.toString("base64")}`;

      console.log("Screenshot saved as document:", {
        documentId: screenshotDocument.$id,
      });

      return {
        success: true,
        data: {
          fileId: screenshotDocument.$id,
          fileName: fileName,
          fileUrl: fileUrl,
        },
      };
    } catch (error) {
      console.error("Error uploading payment screenshot:", error);
      console.error("Error details:", JSON.stringify(error, null, 2));
      return {
        success: false,
        error: error.message || "Failed to upload screenshot",
      };
    }
  }

  /**
   * Get user information
   */
  async getUser(userId) {
    try {
      const user = await this.users.get(userId);
      return {
        success: true,
        data: {
          id: user.$id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          prefs: user.prefs,
        },
      };
    } catch (error) {
      console.error("Error getting user:", error);
      return {
        success: false,
        error: error.message || "User not found",
      };
    }
  }

  // Enhanced Campaign Operations
  async getCampaignSummary() {
    try {
      const campaigns = await this.databases.listDocuments(
        this.databaseId,
        this.campaignsCollectionId,
        [Query.equal("status", "active"), Query.limit(20)]
      );

      const contributions = await this.databases.listDocuments(
        this.databaseId,
        this.contributionsCollectionId,
        [Query.limit(100)]
      );

      const totalCampaigns = campaigns.total;
      const totalRaised = campaigns.documents.reduce(
        (sum, campaign) => sum + (campaign.collectedAmount || 0),
        0
      );
      const totalContributions = contributions.total;

      return {
        success: true,
        data: {
          totalActiveCampaigns: totalCampaigns,
          totalAmountRaised: totalRaised,
          totalContributions: totalContributions,
          recentCampaigns: campaigns.documents.slice(0, 6),
          urgentCampaigns: campaigns.documents.filter((campaign) => {
            if (!campaign.dueDate) return false;
            const dueDate = new Date(campaign.dueDate);
            const now = new Date();
            const daysDiff = Math.ceil((dueDate - now) / (1000 * 60 * 60 * 24));
            return daysDiff <= 7 && daysDiff >= 0;
          }),
        },
      };
    } catch (error) {
      console.error("Error getting campaign summary:", error);
      return {
        success: false,
        error: error.message || "Failed to get campaign summary",
      };
    }
  }

  async getUserDashboard(userId) {
    try {
      // Get user's campaigns
      const userCampaigns = await this.databases.listDocuments(
        this.databaseId,
        this.campaignsCollectionId,
        [Query.equal("hostId", userId)]
      );

      // Get user's contributions
      const userContributions = await this.databases.listDocuments(
        this.databaseId,
        this.contributionsCollectionId,
        [Query.equal("contributorId", userId)]
      );

      // Get loans user needs to repay (contributions others made to user's campaigns that are loans)
      const loansToRepay = [];
      for (const campaign of userCampaigns.documents) {
        const campaignContributions = await this.databases.listDocuments(
          this.databaseId,
          this.contributionsCollectionId,
          [
            Query.equal("campaignId", campaign.$id),
            Query.equal("type", "loan"),
            Query.equal("repaymentStatus", "pending"),
          ]
        );
        loansToRepay.push(...campaignContributions.documents);
      }

      const totalRaised = userCampaigns.documents.reduce(
        (sum, campaign) => sum + (campaign.collectedAmount || 0),
        0
      );

      const totalContributed = userContributions.documents.reduce(
        (sum, contribution) => sum + (contribution.amount || 0),
        0
      );

      const totalLoansToRepay = loansToRepay.reduce(
        (sum, loan) => sum + (loan.amount || 0),
        0
      );

      return {
        success: true,
        data: {
          campaigns: userCampaigns.documents,
          contributions: userContributions.documents,
          loansToRepay: loansToRepay,
          stats: {
            totalCampaigns: userCampaigns.total,
            activeCampaigns: userCampaigns.documents.filter(
              (c) => c.status === "active"
            ).length,
            totalRaised: totalRaised,
            totalContributed: totalContributed,
            totalLoansToRepay: totalLoansToRepay,
            totalContributions: userContributions.total,
          },
        },
      };
    } catch (error) {
      console.error("Error getting user dashboard:", error);
      return {
        success: false,
        error: error.message || "Failed to get user dashboard",
      };
    }
  }

  async markLoanRepaid(contributionId, repaymentData) {
    try {
      const contribution = await this.databases.updateDocument(
        this.databaseId,
        this.contributionsCollectionId,
        contributionId,
        {
          repaymentStatus: "repaid",
          repaidAt: new Date().toISOString(),
          ...repaymentData,
        }
      );

      return {
        success: true,
        data: contribution,
        message: "Loan marked as repaid successfully",
      };
    } catch (error) {
      console.error("Error marking loan as repaid:", error);
      return {
        success: false,
        error: error.message || "Failed to mark loan as repaid",
      };
    }
  }

  // Loan Repayment Methods
  async createLoanRepayment(repaymentData) {
    try {
      const repayment = await this.databases.createDocument(
        this.databaseId,
        this.loanRepaymentsCollectionId,
        ID.unique(),
        {
          loanContributionId: repaymentData.loanContributionId,
          repayerId: repaymentData.repayerId,
          amount: repaymentData.amount,
          utr: repaymentData.utr,
          paymentScreenshotUrl: repaymentData.paymentScreenshotUrl,
          status: repaymentData.status || "pending",
        }
      );

      return {
        success: true,
        data: repayment,
        message: "Loan repayment created successfully",
      };
    } catch (error) {
      console.error("Error creating loan repayment:", error);
      return {
        success: false,
        error: error.message || "Failed to create loan repayment",
      };
    }
  }

  async getUserLoanRepayments(userId) {
    try {
      const repayments = await this.databases.listDocuments(
        this.databaseId,
        this.loanRepaymentsCollectionId,
        [Query.equal("repayerId", userId), Query.orderDesc("$createdAt")]
      );

      return {
        success: true,
        data: repayments.documents,
        message: "User loan repayments retrieved successfully",
      };
    } catch (error) {
      console.error("Error getting user loan repayments:", error);
      return {
        success: false,
        error: error.message || "Failed to get user loan repayments",
      };
    }
  }

  async getReceivedLoanRepayments(userId) {
    try {
      // Get all contributions where user is the contributor (they gave loans)
      const contributions = await this.databases.listDocuments(
        this.databaseId,
        this.contributionsCollectionId,
        [Query.equal("contributorId", userId), Query.equal("isLoan", true)]
      );

      // Get repayments for these contributions
      const contributionIds = contributions.documents.map((doc) => doc.$id);

      if (contributionIds.length === 0) {
        return {
          success: true,
          data: [],
          message: "No received loan repayments found",
        };
      }

      const repayments = await this.databases.listDocuments(
        this.databaseId,
        this.loanRepaymentsCollectionId,
        [
          Query.equal("loanContributionId", contributionIds),
          Query.orderDesc("$createdAt"),
        ]
      );

      return {
        success: true,
        data: repayments.documents,
        message: "Received loan repayments retrieved successfully",
      };
    } catch (error) {
      console.error("Error getting received loan repayments:", error);
      return {
        success: false,
        error: error.message || "Failed to get received loan repayments",
      };
    }
  }

  async verifyLoanRepayment(repaymentId, verificationData) {
    try {
      const repayment = await this.databases.updateDocument(
        this.databaseId,
        this.loanRepaymentsCollectionId,
        repaymentId,
        {
          status: verificationData.status, // "verified" or "rejected"
          verifiedAt:
            verificationData.status === "verified"
              ? new Date().toISOString()
              : null,
        }
      );

      // If verified, update the original contribution status
      if (verificationData.status === "verified") {
        await this.databases.updateDocument(
          this.databaseId,
          this.contributionsCollectionId,
          repayment.loanContributionId,
          {
            repaymentStatus: "repaid",
            repaidAt: new Date().toISOString(),
          }
        );
      }

      return {
        success: true,
        data: repayment,
        message: `Loan repayment ${verificationData.status} successfully`,
      };
    } catch (error) {
      console.error("Error verifying loan repayment:", error);
      return {
        success: false,
        error: error.message || "Failed to verify loan repayment",
      };
    }
  }

  async getOverdueLoans(userId) {
    try {
      // Get all user's campaigns
      const userCampaigns = await this.databases.listDocuments(
        this.databaseId,
        this.campaignsCollectionId,
        [Query.equal("hostId", userId)]
      );

      const overdueLoans = [];
      const now = new Date();

      for (const campaign of userCampaigns.documents) {
        const contributions = await this.databases.listDocuments(
          this.databaseId,
          this.contributionsCollectionId,
          [
            Query.equal("campaignId", campaign.$id),
            Query.equal("type", "loan"),
            Query.equal("repaymentStatus", "pending"),
          ]
        );

        const overdue = contributions.documents.filter((contribution) => {
          if (!contribution.repaymentDueDate) return false;
          const dueDate = new Date(contribution.repaymentDueDate);
          return dueDate < now;
        });

        overdueLoans.push(...overdue);
      }

      return {
        success: true,
        data: overdueLoans,
      };
    } catch (error) {
      console.error("Error getting overdue loans:", error);
      return {
        success: false,
        error: error.message || "Failed to get overdue loans",
      };
    }
  }
}

/**
 * Main function for Appwrite Function execution
 * This is the entry point that Appwrite will call
 */
export default async ({ req, res, log, error: logError }) => {
  // Log the incoming request
  log(`${req.method} ${req.path}`);
  log(`Headers: ${JSON.stringify(req.headers)}`);

  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return res.json({ success: true, message: "CORS preflight" }, 200, {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization, x-user-id",
      "Access-Control-Max-Age": "86400",
    });
  }

  try {
    const friendFundAPI = new FriendFundAPI();
    const method = req.method;
    const path = req.path || req.url || "/";
    const query = req.query || {};
    const body = req.body || {};

    // Parse body if it's a string
    let parsedBody = body;
    if (typeof body === "string") {
      try {
        parsedBody = JSON.parse(body);
      } catch (e) {
        parsedBody = {};
      }
    }

    let result;
    let statusCode = 200;

    // Route handling
    if (path === "/" || path === "/campaigns") {
      if (method === "GET") {
        const queries = [];

        // Build Appwrite queries from URL parameters
        if (query.hostId) queries.push(Query.equal("hostId", query.hostId));
        if (query.creatorId)
          // Keep backward compatibility
          queries.push(Query.equal("hostId", query.creatorId));
        if (query.status) queries.push(Query.equal("status", query.status));
        if (query.purpose) queries.push(Query.equal("purpose", query.purpose));
        if (query.search) queries.push(Query.search("title", query.search));
        if (query.limit) queries.push(Query.limit(parseInt(query.limit)));
        if (query.offset) queries.push(Query.offset(parseInt(query.offset)));

        result = await friendFundAPI.getAllCampaigns(queries);
      } else if (method === "POST") {
        result = await friendFundAPI.createCampaign(parsedBody);
        statusCode = 201;
      } else {
        result = { success: false, error: "Method not allowed" };
        statusCode = 405;
      }
    } else if (path.startsWith("/campaigns/")) {
      const pathParts = path.split("/").filter((p) => p);
      const campaignId = pathParts[1];

      if (pathParts[2] === "contribute" && method === "GET") {
        // GET /campaigns/{id}/contribute - Get campaign details for contribution form
        result = await friendFundAPI.getCampaignForContribution(campaignId);
      } else if (method === "GET") {
        result = await friendFundAPI.getCampaign(campaignId);
      } else if (method === "PATCH") {
        result = await friendFundAPI.updateCampaign(campaignId, parsedBody);
      } else if (method === "DELETE") {
        result = await friendFundAPI.deleteCampaign(campaignId);
        statusCode = 204;
      } else {
        result = { success: false, error: "Method not allowed" };
        statusCode = 405;
      }
    } else if (path.startsWith("/contributions/")) {
      const pathParts = path.split("/").filter((p) => p);

      if (pathParts[1] === "campaign" && pathParts[2]) {
        // GET /contributions/campaign/{id}
        const campaignId = pathParts[2];
        result = await friendFundAPI.getCampaignContributions(campaignId);
      } else if (pathParts[1] === "user" && pathParts[2]) {
        // GET /contributions/user/{id}
        const userId = pathParts[2];
        result = await friendFundAPI.getUserContributions(userId);
      } else if (pathParts[1] && method === "PATCH") {
        // PATCH /contributions/{id}
        const contributionId = pathParts[1];
        result = await friendFundAPI.updateContribution(
          contributionId,
          parsedBody
        );
      } else if (
        pathParts[1] === "check-utr" &&
        pathParts[2] &&
        pathParts[3] &&
        method === "GET"
      ) {
        // GET /contributions/check-utr/{campaignId}/{utrNumber}
        const campaignId = pathParts[2];
        const utrNumber = pathParts[3];
        result = await friendFundAPI.checkUtrDuplication(utrNumber, campaignId);
      } else {
        result = { success: false, error: "Invalid contributions endpoint" };
        statusCode = 400;
      }
    } else if (path === "/contributions") {
      if (method === "POST") {
        result = await friendFundAPI.createContribution(parsedBody);
        statusCode = 201;
      } else {
        result = { success: false, error: "Method not allowed" };
        statusCode = 405;
      }
    } else if (path.startsWith("/qr/")) {
      const pathParts = path.split("/").filter((p) => p);
      const campaignId = pathParts[1];

      if (method === "GET") {
        result = await friendFundAPI.generateQRCode(campaignId);
      } else {
        result = { success: false, error: "Method not allowed" };
        statusCode = 405;
      }
    } else if (path.startsWith("/payment-qr/")) {
      const pathParts = path.split("/").filter((p) => p);
      const campaignId = pathParts[1];

      if (method === "POST") {
        const { upiId, amount } = parsedBody;
        result = await friendFundAPI.generatePaymentQRCode(
          campaignId,
          upiId,
          amount
        );
      } else {
        result = { success: false, error: "Method not allowed" };
        statusCode = 405;
      }
    } else if (path.startsWith("/users/")) {
      const pathParts = path.split("/").filter((p) => p);
      const userId = pathParts[1];

      if (method === "GET") {
        if (pathParts[2] === "dashboard") {
          // GET /users/{id}/dashboard
          result = await friendFundAPI.getUserDashboard(userId);
        } else if (pathParts[2] === "overdue-loans") {
          // GET /users/{id}/overdue-loans
          result = await friendFundAPI.getOverdueLoans(userId);
        } else {
          // GET /users/{id}
          result = await friendFundAPI.getUser(userId);
        }
      } else {
        result = { success: false, error: "Method not allowed" };
        statusCode = 405;
      }
    } else if (path === "/payment/process-screenshot") {
      if (method === "POST") {
        const { imageBase64, expectedAmount, contributorName, campaignId } =
          parsedBody;

        // Convert base64 to buffer
        const imageBuffer = Buffer.from(imageBase64, "base64");

        result = await friendFundAPI.processPaymentScreenshot(
          imageBuffer,
          expectedAmount,
          contributorName,
          campaignId
        );
        statusCode = 201;
      } else {
        result = { success: false, error: "Method not allowed" };
        statusCode = 405;
      }
    } else if (path === "/payment/upload-screenshot") {
      if (method === "POST") {
        const { fileBase64, fileName, contributionId } = parsedBody;

        // Convert base64 to buffer
        const fileBuffer = Buffer.from(fileBase64, "base64");

        result = await friendFundAPI.uploadPaymentScreenshot(
          fileBuffer,
          fileName,
          contributionId
        );
      } else {
        result = { success: false, error: "Method not allowed" };
        statusCode = 405;
      }
    } else if (path === "/summary") {
      if (method === "GET") {
        result = await friendFundAPI.getCampaignSummary();
      } else {
        result = { success: false, error: "Method not allowed" };
        statusCode = 405;
      }
    } else if (path.startsWith("/loans/")) {
      const pathParts = path.split("/").filter((p) => p);
      const loanId = pathParts[1];

      if (pathParts[2] === "repaid" && method === "PATCH") {
        // PATCH /loans/{id}/repaid
        result = await friendFundAPI.markLoanRepaid(loanId, parsedBody);
      } else {
        result = { success: false, error: "Invalid loan endpoint" };
        statusCode = 400;
      }
    } else if (path.startsWith("/loan-repayments/")) {
      const pathParts = path.split("/").filter((p) => p);

      if (pathParts[1] === "user" && pathParts[2]) {
        // GET /loan-repayments/user/{userId}
        const userId = pathParts[2];
        result = await friendFundAPI.getUserLoanRepayments(userId);
      } else if (pathParts[1] === "received" && pathParts[2]) {
        // GET /loan-repayments/received/{userId}
        const userId = pathParts[2];
        result = await friendFundAPI.getReceivedLoanRepayments(userId);
      } else if (
        pathParts[1] &&
        pathParts[2] === "verify" &&
        method === "POST"
      ) {
        // POST /loan-repayments/{id}/verify
        const repaymentId = pathParts[1];
        result = await friendFundAPI.verifyLoanRepayment(
          repaymentId,
          parsedBody
        );
      } else {
        result = { success: false, error: "Invalid loan repayment endpoint" };
        statusCode = 400;
      }
    } else if (path === "/loan-repayments") {
      if (method === "POST") {
        result = await friendFundAPI.createLoanRepayment(parsedBody);
        statusCode = 201;
      } else {
        result = { success: false, error: "Method not allowed" };
        statusCode = 405;
      }
    } else {
      result = {
        success: false,
        error: "Route not found",
        availableRoutes: [
          "GET /campaigns - Get all campaigns",
          "POST /campaigns - Create campaign",
          "GET /campaigns/{id} - Get specific campaign",
          "PATCH /campaigns/{id} - Update campaign",
          "DELETE /campaigns/{id} - Delete campaign",
          "GET /contributions/campaign/{id} - Get campaign contributions",
          "GET /contributions/user/{id} - Get user contributions",
          "POST /contributions - Create contribution",
          "PATCH /contributions/{id} - Update contribution",
          "GET /qr/{campaignId} - Generate QR code",
          "GET /users/{id} - Get user info",
          "GET /users/{id}/dashboard - Get user dashboard with stats",
          "GET /users/{id}/overdue-loans - Get user's overdue loans",
          "GET /summary - Get platform summary statistics",
          "PATCH /loans/{id}/repaid - Mark loan as repaid",
          "POST /loan-repayments - Create loan repayment",
          "GET /loan-repayments/user/{userId} - Get user's loan repayments",
          "GET /loan-repayments/received/{userId} - Get received loan repayments",
          "POST /loan-repayments/{id}/verify - Verify loan repayment",
        ],
      };
      statusCode = 404;
    }

    // Set response status based on result
    if (result && !result.success && statusCode === 200) {
      statusCode = 400;
    }

    log(`Response status: ${statusCode}`);
    log(`Response: ${JSON.stringify(result)}`);

    // Add CORS headers to all responses
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization, x-user-id",
    };

    return res.json(result, statusCode, corsHeaders);
  } catch (err) {
    logError("Function execution error:", err);

    // Add CORS headers to error responses too
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization, x-user-id",
    };

    return res.json(
      {
        success: false,
        error: err.message || "Internal server error",
        stack: process.env.NODE_ENV === "development" ? err.stack : undefined,
      },
      500,
      corsHeaders
    );
  }
};
