const {
  Client,
  Databases,
  Users,
  Account,
  ID,
  Query,
} = require("node-appwrite");

// Initialize Appwrite Client
const client = new Client()
  .setEndpoint(process.env.APPWRITE_ENDPOINT || "https://cloud.appwrite.io/v1")
  .setProject(process.env.APPWRITE_PROJECT)
  .setKey(process.env.APPWRITE_API_KEY);

const databases = new Databases(client);
const users = new Users(client);
const account = new Account(client);

// Environment Variables
const DATABASE_ID = process.env.DATABASE_ID || "friendfundDB";
const COLLECTION_USERS = process.env.COLLECTION_USERS || "users";
const COLLECTION_CAMPAIGNS = process.env.COLLECTION_CAMPAIGNS || "campaigns";
const COLLECTION_CONTRIBUTIONS =
  process.env.COLLECTION_CONTRIBUTIONS || "contributions";

/**
 * Main Function - Routes all HTTP requests
 */
module.exports = async ({ req, res, log, error }) => {
  try {
    // Set CORS headers
    res.headers = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, PATCH, PUT, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
      "Content-Type": "application/json",
    };

    // Handle preflight OPTIONS request
    if (req.method === "OPTIONS") {
      return res.json({ success: true });
    }

    log(`Incoming request: ${req.method} ${req.path}`);

    // Parse request body for POST/PATCH requests
    let body = {};
    if (req.method === "POST" || req.method === "PATCH") {
      try {
        body =
          typeof req.body === "string" ? JSON.parse(req.body) : req.body || {};
      } catch (e) {
        return res.json({
          success: false,
          data: null,
          error: "Invalid JSON body",
        });
      }
    }

    // Extract JWT token for authentication
    const authHeader =
      req.headers["authorization"] || req.headers["Authorization"];
    const token = authHeader ? authHeader.replace("Bearer ", "") : null;

    // Route the request based on method and path
    const route = `${req.method} ${req.path}`;

    switch (true) {
      case route === "POST /campaigns":
        return await createCampaign(req, res, body, token, log);

      case route === "GET /campaigns":
        return await getCampaigns(req, res, token, log);

      case route === "POST /contributions":
        return await createContribution(req, res, body, token, log);

      case route.startsWith("PATCH /contributions/") &&
        route.endsWith("/repaid"):
        const contributionId = req.path.split("/")[2];
        return await markContributionRepaid(
          req,
          res,
          contributionId,
          token,
          log
        );

      default:
        return res.json({
          success: false,
          data: null,
          error: `Route not found: ${route}`,
        });
    }
  } catch (err) {
    error(`Global error: ${err.message}`);
    return res.json({
      success: false,
      data: null,
      error: "Internal server error",
    });
  }
};

/**
 * Helper function to get user from JWT token
 */
async function getUserFromToken(token, log) {
  if (!token) {
    throw new Error("Authentication token required");
  }

  try {
    // Set the JWT token for this request
    const userClient = new Client()
      .setEndpoint(
        process.env.APPWRITE_ENDPOINT || "https://cloud.appwrite.io/v1"
      )
      .setProject(process.env.APPWRITE_PROJECT)
      .setJWT(token);

    const userAccount = new Account(userClient);
    const user = await userAccount.get();

    log(`Authenticated user: ${user.$id}`);
    return user;
  } catch (err) {
    throw new Error("Invalid or expired token");
  }
}

/**
 * 1. POST /campaigns - Create a new fundraising campaign
 */
async function createCampaign(req, res, body, token, log) {
  try {
    // Authenticate user
    const user = await getUserFromToken(token, log);

    // Validate required fields
    const {
      title,
      description,
      purpose,
      targetAmount,
      repaymentDueDate,
      upiId,
    } = body;

    if (
      !title ||
      !description ||
      !purpose ||
      !targetAmount ||
      !repaymentDueDate ||
      !upiId
    ) {
      return res.json({
        success: false,
        data: null,
        error:
          "Missing required fields: title, description, purpose, targetAmount, repaymentDueDate, upiId",
      });
    }

    // Validate targetAmount is a positive number
    if (isNaN(targetAmount) || targetAmount <= 0) {
      return res.json({
        success: false,
        data: null,
        error: "Target amount must be a positive number",
      });
    }

    // Create campaign document
    const campaignData = {
      title: title.trim(),
      description: description.trim(),
      purpose: purpose.trim(),
      targetAmount: parseFloat(targetAmount),
      collectedAmount: 0,
      repaymentDueDate,
      upiId: upiId.trim(),
      hostId: user.$id,
      hostName: user.name || user.phone || "Unknown",
      status: "active",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    const campaign = await databases.createDocument(
      DATABASE_ID,
      COLLECTION_CAMPAIGNS,
      ID.unique(),
      campaignData
    );

    log(`Campaign created: ${campaign.$id}`);

    return res.json({
      success: true,
      data: {
        campaign: {
          id: campaign.$id,
          ...campaignData,
        },
      },
      error: null,
    });
  } catch (err) {
    log(`Create campaign error: ${err.message}`);
    return res.json({
      success: false,
      data: null,
      error: err.message,
    });
  }
}

/**
 * 2. GET /campaigns - Fetch campaigns
 */
async function getCampaigns(req, res, token, log) {
  try {
    const queries = [Query.equal("status", "active")];

    // Check if user wants only their campaigns
    const hostOnly = req.query?.hostOnly === "true";

    if (hostOnly) {
      // Authenticate user for host-only requests
      const user = await getUserFromToken(token, log);
      queries.push(Query.equal("hostId", user.$id));
    }

    // Fetch campaigns
    const response = await databases.listDocuments(
      DATABASE_ID,
      COLLECTION_CAMPAIGNS,
      queries
    );

    const campaigns = response.documents.map((doc) => ({
      id: doc.$id,
      title: doc.title,
      description: doc.description,
      purpose: doc.purpose,
      targetAmount: doc.targetAmount,
      collectedAmount: doc.collectedAmount,
      repaymentDueDate: doc.repaymentDueDate,
      upiId: doc.upiId,
      hostId: doc.hostId,
      hostName: doc.hostName,
      status: doc.status,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    }));

    log(`Fetched ${campaigns.length} campaigns`);

    return res.json({
      success: true,
      data: {
        campaigns,
        total: campaigns.length,
      },
      error: null,
    });
  } catch (err) {
    log(`Get campaigns error: ${err.message}`);
    return res.json({
      success: false,
      data: null,
      error: err.message,
    });
  }
}

/**
 * 3. POST /contributions - Log a contributor's payment
 */
async function createContribution(req, res, body, token, log) {
  try {
    // Validate required fields
    const { campaignId, contributorName, amount, utr, type, isAnonymous } =
      body;

    if (!campaignId || !amount || !utr || !type) {
      return res.json({
        success: false,
        data: null,
        error: "Missing required fields: campaignId, amount, utr, type",
      });
    }

    // Validate amount
    if (isNaN(amount) || amount <= 0) {
      return res.json({
        success: false,
        data: null,
        error: "Amount must be a positive number",
      });
    }

    // Validate type
    if (!["donation", "loan"].includes(type)) {
      return res.json({
        success: false,
        data: null,
        error: 'Type must be either "donation" or "loan"',
      });
    }

    // Check if campaign exists
    const campaign = await databases.getDocument(
      DATABASE_ID,
      COLLECTION_CAMPAIGNS,
      campaignId
    );

    if (campaign.status !== "active") {
      return res.json({
        success: false,
        data: null,
        error: "Campaign is not active",
      });
    }

    // Determine contributor name
    const finalContributorName =
      isAnonymous === true ? "Anonymous" : contributorName || "Anonymous";

    // Get contributor ID if authenticated
    let contributorId = null;
    try {
      if (token) {
        const user = await getUserFromToken(token, log);
        contributorId = user.$id;
      }
    } catch (err) {
      // If token is invalid, continue as anonymous
      log("No valid authentication for contribution, proceeding as anonymous");
    }

    // Create contribution document
    const contributionData = {
      campaignId,
      contributorId,
      contributorName: finalContributorName.trim(),
      amount: parseFloat(amount),
      utr: utr.trim(),
      type,
      isAnonymous: isAnonymous === true,
      isRepaid: false,
      createdAt: new Date().toISOString(),
    };

    // If it's a loan, add repayment due date from campaign
    if (type === "loan") {
      contributionData.repaymentDueDate = campaign.repaymentDueDate;
    }

    const contribution = await databases.createDocument(
      DATABASE_ID,
      COLLECTION_CONTRIBUTIONS,
      ID.unique(),
      contributionData
    );

    // Update campaign's collected amount
    const newCollectedAmount = campaign.collectedAmount + parseFloat(amount);
    const newStatus =
      newCollectedAmount >= campaign.targetAmount ? "completed" : "active";

    await databases.updateDocument(
      DATABASE_ID,
      COLLECTION_CAMPAIGNS,
      campaignId,
      {
        collectedAmount: newCollectedAmount,
        status: newStatus,
        updatedAt: new Date().toISOString(),
      }
    );

    log(`Contribution created: ${contribution.$id} for campaign ${campaignId}`);

    return res.json({
      success: true,
      data: {
        contribution: {
          id: contribution.$id,
          ...contributionData,
        },
        campaign: {
          collectedAmount: newCollectedAmount,
          status: newStatus,
        },
      },
      error: null,
    });
  } catch (err) {
    log(`Create contribution error: ${err.message}`);
    return res.json({
      success: false,
      data: null,
      error: err.message.includes("not found")
        ? "Campaign not found"
        : err.message,
    });
  }
}

/**
 * 4. PATCH /contributions/:id/repaid - Mark a loan contribution as repaid
 */
async function markContributionRepaid(req, res, contributionId, token, log) {
  try {
    // Authenticate user
    const user = await getUserFromToken(token, log);

    // Get contribution
    const contribution = await databases.getDocument(
      DATABASE_ID,
      COLLECTION_CONTRIBUTIONS,
      contributionId
    );

    if (contribution.type !== "loan") {
      return res.json({
        success: false,
        data: null,
        error: "Only loan contributions can be marked as repaid",
      });
    }

    if (contribution.isRepaid) {
      return res.json({
        success: false,
        data: null,
        error: "Contribution is already marked as repaid",
      });
    }

    // Get campaign to verify user is the host
    const campaign = await databases.getDocument(
      DATABASE_ID,
      COLLECTION_CAMPAIGNS,
      contribution.campaignId
    );

    if (campaign.hostId !== user.$id) {
      return res.json({
        success: false,
        data: null,
        error: "Only the campaign host can mark contributions as repaid",
      });
    }

    // Update contribution
    const updatedContribution = await databases.updateDocument(
      DATABASE_ID,
      COLLECTION_CONTRIBUTIONS,
      contributionId,
      {
        isRepaid: true,
        repaidAt: new Date().toISOString(),
      }
    );

    log(`Contribution marked as repaid: ${contributionId}`);

    return res.json({
      success: true,
      data: {
        contribution: {
          id: updatedContribution.$id,
          isRepaid: true,
          repaidAt: updatedContribution.repaidAt,
        },
      },
      error: null,
    });
  } catch (err) {
    log(`Mark contribution repaid error: ${err.message}`);
    return res.json({
      success: false,
      data: null,
      error: err.message.includes("not found")
        ? "Contribution not found"
        : err.message,
    });
  }
}
