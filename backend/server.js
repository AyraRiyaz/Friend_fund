/**
 * FriendFund HTTP Server Backend - Single File
 * Standalone HTTP server with Appwrite integration for full-stack development
 * Author: Ayra Riyaz
 * Modified from Appwrite Function to HTTP Server for better development experience
 */

import "dotenv/config";
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
import http from "http";
import url from "url";

const PORT = process.env.PORT || 3000;

/**
 * @class FriendFundAPI
 * @description Main class for handling FriendFund operations via HTTP API
 */
class FriendFundAPI {
  constructor() {
    this.client = new Client();
    this.databases = new Databases(this.client);
    this.storage = new Storage(this.client);
    this.users = new Users(this.client);

    // Initialize Appwrite client
    this.client
      .setEndpoint(
        process.env.APPWRITE_ENDPOINT || "https://fra.cloud.appwrite.io/v1"
      )
      .setProject(process.env.APPWRITE_PROJECT_ID || "68b542650008ea019d84")
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
          createdAt: new Date().toISOString(),
          status: "active",
          currentAmount: 0,
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
        {
          ...updateData,
          updatedAt: new Date().toISOString(),
        }
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
          createdAt: new Date().toISOString(),
          status: "pending",
        },
        [Permission.read(Role.any())]
      );

      // Update campaign current amount
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
          currentAmount:
            (campaign.currentAmount || 0) + contributionData.amount,
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
        process.env.FRONTEND_URL ||
        "https://68b699f80025cf96484e.fra.appwrite.run"
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

// HTTP Server Setup
console.log(
  `🚀 FriendFund Backend-Frontend Connected: Running HTTP Server on port ${PORT}`
);

const server = http.createServer(async (req, res) => {
  // Set CORS headers for frontend integration
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader(
    "Access-Control-Allow-Methods",
    "GET, POST, PATCH, DELETE, OPTIONS"
  );
  res.setHeader(
    "Access-Control-Allow-Headers",
    "Content-Type, Authorization, x-user-id"
  );

  // Handle preflight OPTIONS request
  if (req.method === "OPTIONS") {
    res.writeHead(200);
    res.end();
    return;
  }

  try {
    const friendFundAPI = new FriendFundAPI();
    const parsedUrl = url.parse(req.url, true);
    const path = parsedUrl.pathname;
    const query = parsedUrl.query;
    const method = req.method;

    console.log(`${method} ${path}`);

    // Parse body for POST/PATCH requests
    let body = {};
    if (method === "POST" || method === "PATCH") {
      const chunks = [];
      for await (const chunk of req) {
        chunks.push(chunk);
      }
      const bodyString = Buffer.concat(chunks).toString();
      try {
        body = JSON.parse(bodyString);
      } catch (e) {
        body = {};
      }
    }

    let result;
    let statusCode = 200;

    // Route handling
    if (path === "/campaigns" || path === "/") {
      if (method === "GET") {
        const queries = [];

        // Build Appwrite queries from URL parameters
        if (query.creatorId)
          queries.push(`equal("creatorId", "${query.creatorId}")`);
        if (query.status) queries.push(`equal("status", "${query.status}")`);
        if (query.search) queries.push(`search("title", "${query.search}")`);
        if (query.limit) queries.push(`limit(${parseInt(query.limit)})`);
        if (query.offset) queries.push(`offset(${parseInt(query.offset)})`);

        result = await friendFundAPI.getAllCampaigns(queries);
      } else if (method === "POST") {
        result = await friendFundAPI.createCampaign(body);
        statusCode = 201; // Created
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
        result = await friendFundAPI.updateCampaign(campaignId, body);
      } else if (method === "DELETE") {
        result = await friendFundAPI.deleteCampaign(campaignId);
        statusCode = 204; // No Content
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
        result = await friendFundAPI.updateContribution(contributionId, body);
      } else {
        result = { success: false, error: "Invalid contributions endpoint" };
        statusCode = 400;
      }
    } else if (path === "/contributions") {
      if (method === "POST") {
        result = await friendFundAPI.createContribution(body);
        statusCode = 201; // Created
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
      statusCode = 400; // Bad Request
    }

    res.writeHead(statusCode, { "Content-Type": "application/json" });
    res.end(JSON.stringify(result || { success: false, error: "No response" }));
  } catch (error) {
    console.error("Server error:", error);
    if (!res.headersSent) {
      res.writeHead(500, { "Content-Type": "application/json" });
      res.end(
        JSON.stringify({
          success: false,
          error: error.message,
        })
      );
    }
  }
});

server.listen(PORT, () => {
  console.log(`🚀 FriendFund Server running on http://localhost:${PORT}`);
  console.log("📋 Available endpoints:");
  console.log("  GET    /campaigns - Get all campaigns");
  console.log("  POST   /campaigns - Create campaign");
  console.log("  GET    /campaigns/:id - Get specific campaign");
  console.log("  PATCH  /campaigns/:id - Update campaign");
  console.log("  DELETE /campaigns/:id - Delete campaign");
  console.log(
    "  GET    /contributions/campaign/:id - Get campaign contributions"
  );
  console.log("  GET    /contributions/user/:id - Get user contributions");
  console.log("  POST   /contributions - Create contribution");
  console.log("  PATCH  /contributions/:id - Update contribution");
  console.log("  GET    /qr/:campaignId - Generate QR code");
  console.log("  GET    /users/:id - Get user info");
  console.log("");
  console.log(
    "💡 Make sure to configure your .env file with Appwrite credentials"
  );
});
