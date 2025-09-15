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
      const campaign = await this.databases.createDocument(
        this.databaseId,
        this.campaignsCollectionId,
        ID.unique(),
        {
          ...campaignData,
          status: campaignData.status || "active",
          collectedAmount: 0,
          contributions: [],
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
        },
        [Permission.read(Role.any())]
      );

      // Update campaign collected amount
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
            (campaign.collectedAmount || 0) + contributionData.amount,
        }
      );

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

  // QR Code Generation
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

  // User Operations (for getting user info)
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
}

/**
 * Main function for Appwrite Function execution
 * This is the entry point that Appwrite will call
 */
export default async ({ req, res, log, error: logError }) => {
  // Log the incoming request
  log(`${req.method} ${req.path}`);
  log(`Headers: ${JSON.stringify(req.headers)}`);

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

      if (method === "GET") {
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
    } else if (path.startsWith("/users/")) {
      const pathParts = path.split("/").filter((p) => p);
      const userId = pathParts[1];

      if (method === "GET") {
        result = await friendFundAPI.getUser(userId);
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

    return res.json(result, statusCode);
  } catch (err) {
    logError("Function execution error:", err);
    return res.json(
      {
        success: false,
        error: err.message || "Internal server error",
        stack: process.env.NODE_ENV === "development" ? err.stack : undefined,
      },
      500
    );
  }
};
