const sdk = require("node-appwrite");

// Initialize Appwrite SDK
const client = new sdk.Client();
const account = new sdk.Account(client);
const databases = new sdk.Databases(client);
const users = new sdk.Users(client);

// Database and Collection IDs
const DATABASE_ID = "68b5433d0004cadff5ff";
const USERS_COLLECTION_ID = "68b5437f000585a01be6";
const CAMPAIGNS_COLLECTION_ID = "68b54652001a8a757571";
const CONTRIBUTIONS_COLLECTION_ID = "68b54a0700208ba7fdaa";

// Initialize Appwrite client
function initializeAppwrite(req) {
  client
    .setEndpoint(
      process.env.APPWRITE_FUNCTION_ENDPOINT || "https://cloud.appwrite.io/v1"
    )
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID || "")
    .setKey(process.env.APPWRITE_FUNCTION_API_KEY || "");

  // Set session if available
  if (req.headers["authorization"]) {
    client.setJWT(req.headers["authorization"].replace("Bearer ", ""));
  }
}

// Utility function to generate unique IDs
function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

// Response helper
function createResponse(data, status = 200, message = "Success") {
  return {
    statusCode: status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
    body: JSON.stringify({
      success: status < 400,
      message,
      data,
      timestamp: new Date().toISOString(),
    }),
  };
}

// Error handler
function handleError(error, defaultMessage = "An error occurred") {
  console.error("Error:", error);
  const status = error.code || 500;
  const message = error.message || defaultMessage;
  return createResponse(null, status, message);
}

// Route handlers

// Authentication handlers
async function registerUser(req) {
  try {
    const { mobileNumber, upiId, name } = JSON.parse(req.body || "{}");

    if (!mobileNumber || !upiId || !name) {
      return createResponse(
        null,
        400,
        "Mobile number, UPI ID, and name are required"
      );
    }

    // Create user in Appwrite Auth with email format (using mobile as email)
    const email = `${mobileNumber.replace("+", "")}@friendfund.app`;
    const password = generateId(); // Temporary password

    const user = await users.create(
      sdk.ID.unique(),
      email,
      undefined, // phone (optional)
      password,
      name
    );

    // Create user profile in database
    const userProfile = await databases.createDocument(
      DATABASE_ID,
      USERS_COLLECTION_ID,
      user.$id,
      {
        userId: user.$id,
        mobileNumber,
        upiId,
        name,
        createdAt: new Date().toISOString(),
      }
    );

    return createResponse(
      {
        userId: user.$id,
        email: user.email,
        name: user.name,
        mobileNumber,
        upiId,
      },
      201,
      "User registered successfully"
    );
  } catch (error) {
    return handleError(error, "Failed to register user");
  }
}

async function loginUser(req) {
  try {
    const { mobileNumber } = JSON.parse(req.body || "{}");

    if (!mobileNumber) {
      return createResponse(null, 400, "Mobile number is required");
    }

    // In a real implementation, you would send OTP here
    // For now, we'll simulate OTP generation
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    return createResponse(
      {
        otp, // In production, don't return OTP
        message: "OTP sent to mobile number",
        mobileNumber,
      },
      200,
      "OTP sent successfully"
    );
  } catch (error) {
    return handleError(error, "Failed to send OTP");
  }
}

async function verifyOTP(req) {
  try {
    const { mobileNumber, otp } = JSON.parse(req.body || "{}");

    if (!mobileNumber || !otp) {
      return createResponse(null, 400, "Mobile number and OTP are required");
    }

    // In production, verify the actual OTP
    // For now, we'll create a session for any 6-digit OTP
    if (otp.length !== 6) {
      return createResponse(null, 400, "Invalid OTP");
    }

    // Find user by mobile number
    const userQuery = await databases.listDocuments(
      DATABASE_ID,
      USERS_COLLECTION_ID,
      [sdk.Query.equal("mobileNumber", mobileNumber)]
    );

    if (userQuery.documents.length === 0) {
      return createResponse(null, 404, "User not found");
    }

    const user = userQuery.documents[0];

    // Create session token (in production, use proper JWT)
    const sessionToken = Buffer.from(
      JSON.stringify({ userId: user.userId, timestamp: Date.now() })
    ).toString("base64");

    return createResponse(
      {
        user: {
          userId: user.userId,
          mobileNumber: user.mobileNumber,
          upiId: user.upiId,
          name: user.name,
        },
        sessionToken,
      },
      200,
      "Login successful"
    );
  } catch (error) {
    return handleError(error, "Failed to verify OTP");
  }
}

async function getCurrentUser(req) {
  try {
    const authHeader = req.headers["authorization"];
    if (!authHeader) {
      return createResponse(null, 401, "Authorization header required");
    }

    const token = authHeader.replace("Bearer ", "");
    const decoded = JSON.parse(Buffer.from(token, "base64").toString());

    const user = await databases.getDocument(
      DATABASE_ID,
      USERS_COLLECTION_ID,
      decoded.userId
    );

    return createResponse({
      userId: user.userId,
      mobileNumber: user.mobileNumber,
      upiId: user.upiId,
      name: user.name,
      createdAt: user.createdAt,
    });
  } catch (error) {
    return handleError(error, "Failed to get user profile");
  }
}

// Campaign handlers
async function createCampaign(req) {
  try {
    const authHeader = req.headers["authorization"];
    if (!authHeader) {
      return createResponse(null, 401, "Authorization required");
    }

    const token = authHeader.replace("Bearer ", "");
    const decoded = JSON.parse(Buffer.from(token, "base64").toString());

    const { title, description, purpose, targetAmount, repaymentDueDate } =
      JSON.parse(req.body || "{}");

    if (!title || !description || !purpose || !targetAmount) {
      return createResponse(
        null,
        400,
        "Title, description, purpose, and target amount are required"
      );
    }

    const campaignId = generateId();

    const campaign = await databases.createDocument(
      DATABASE_ID,
      CAMPAIGNS_COLLECTION_ID,
      campaignId,
      {
        campaignId,
        hostId: decoded.userId,
        title,
        description,
        purpose,
        targetAmount: parseFloat(targetAmount),
        collectedAmount: 0,
        status: "active",
        repaymentDueDate: repaymentDueDate || null,
        createdAt: new Date().toISOString(),
      }
    );

    return createResponse(
      {
        campaignId: campaign.campaignId,
        title: campaign.title,
        description: campaign.description,
        purpose: campaign.purpose,
        targetAmount: campaign.targetAmount,
        collectedAmount: campaign.collectedAmount,
        status: campaign.status,
        shareLink: `https://friendfund.app/campaign/${campaign.campaignId}`,
        createdAt: campaign.createdAt,
      },
      201,
      "Campaign created successfully"
    );
  } catch (error) {
    return handleError(error, "Failed to create campaign");
  }
}

async function getCampaign(req, campaignId) {
  try {
    const campaign = await databases.getDocument(
      DATABASE_ID,
      CAMPAIGNS_COLLECTION_ID,
      campaignId
    );

    // Get host information
    const host = await databases.getDocument(
      DATABASE_ID,
      USERS_COLLECTION_ID,
      campaign.hostId
    );

    // Get contributions for this campaign
    const contributionsQuery = await databases.listDocuments(
      DATABASE_ID,
      CONTRIBUTIONS_COLLECTION_ID,
      [
        sdk.Query.equal("campaignId", campaignId),
        sdk.Query.orderDesc("createdAt"),
      ]
    );

    const contributions = contributionsQuery.documents.map((contrib) => ({
      contributionId: contrib.contributionId,
      contributorName: contrib.isAnonymous
        ? "Anonymous"
        : contrib.contributorName,
      amount: contrib.amount,
      type: contrib.type,
      repaymentStatus: contrib.repaymentStatus,
      createdAt: contrib.createdAt,
    }));

    return createResponse({
      campaignId: campaign.campaignId,
      title: campaign.title,
      description: campaign.description,
      purpose: campaign.purpose,
      targetAmount: campaign.targetAmount,
      collectedAmount: campaign.collectedAmount,
      status: campaign.status,
      repaymentDueDate: campaign.repaymentDueDate,
      host: {
        name: host.name,
        upiId: host.upiId,
      },
      contributions,
      progress: Math.round(
        (campaign.collectedAmount / campaign.targetAmount) * 100
      ),
      createdAt: campaign.createdAt,
    });
  } catch (error) {
    return handleError(error, "Failed to get campaign");
  }
}

async function getUserCampaigns(req) {
  try {
    const authHeader = req.headers["authorization"];
    if (!authHeader) {
      return createResponse(null, 401, "Authorization required");
    }

    const token = authHeader.replace("Bearer ", "");
    const decoded = JSON.parse(Buffer.from(token, "base64").toString());

    const campaignsQuery = await databases.listDocuments(
      DATABASE_ID,
      CAMPAIGNS_COLLECTION_ID,
      [
        sdk.Query.equal("hostId", decoded.userId),
        sdk.Query.orderDesc("createdAt"),
      ]
    );

    const campaigns = campaignsQuery.documents.map((campaign) => ({
      campaignId: campaign.campaignId,
      title: campaign.title,
      description: campaign.description,
      purpose: campaign.purpose,
      targetAmount: campaign.targetAmount,
      collectedAmount: campaign.collectedAmount,
      status: campaign.status,
      progress: Math.round(
        (campaign.collectedAmount / campaign.targetAmount) * 100
      ),
      createdAt: campaign.createdAt,
    }));

    return createResponse(campaigns);
  } catch (error) {
    return handleError(error, "Failed to get campaigns");
  }
}

async function updateCampaign(req, campaignId) {
  try {
    const authHeader = req.headers["authorization"];
    if (!authHeader) {
      return createResponse(null, 401, "Authorization required");
    }

    const token = authHeader.replace("Bearer ", "");
    const decoded = JSON.parse(Buffer.from(token, "base64").toString());

    const { title, description, purpose, targetAmount, status } = JSON.parse(
      req.body || "{}"
    );

    // Verify campaign ownership
    const campaign = await databases.getDocument(
      DATABASE_ID,
      CAMPAIGNS_COLLECTION_ID,
      campaignId
    );

    if (campaign.hostId !== decoded.userId) {
      return createResponse(null, 403, "Unauthorized to update this campaign");
    }

    const updateData = {};
    if (title) updateData.title = title;
    if (description) updateData.description = description;
    if (purpose) updateData.purpose = purpose;
    if (targetAmount) updateData.targetAmount = parseFloat(targetAmount);
    if (status) updateData.status = status;

    const updatedCampaign = await databases.updateDocument(
      DATABASE_ID,
      CAMPAIGNS_COLLECTION_ID,
      campaignId,
      updateData
    );

    return createResponse(
      {
        campaignId: updatedCampaign.campaignId,
        title: updatedCampaign.title,
        description: updatedCampaign.description,
        purpose: updatedCampaign.purpose,
        targetAmount: updatedCampaign.targetAmount,
        collectedAmount: updatedCampaign.collectedAmount,
        status: updatedCampaign.status,
      },
      200,
      "Campaign updated successfully"
    );
  } catch (error) {
    return handleError(error, "Failed to update campaign");
  }
}

// Contribution handlers
async function makeContribution(req) {
  try {
    const { campaignId, contributorName, amount, utr, type, isAnonymous } =
      JSON.parse(req.body || "{}");

    if (!campaignId || !contributorName || !amount || !utr || !type) {
      return createResponse(
        null,
        400,
        "Campaign ID, contributor name, amount, UTR, and type are required"
      );
    }

    if (!["gift", "loan"].includes(type)) {
      return createResponse(null, 400, 'Type must be either "gift" or "loan"');
    }

    // Verify campaign exists and is active
    const campaign = await databases.getDocument(
      DATABASE_ID,
      CAMPAIGNS_COLLECTION_ID,
      campaignId
    );

    if (campaign.status !== "active") {
      return createResponse(null, 400, "Campaign is not active");
    }

    const contributionId = generateId();

    const contribution = await databases.createDocument(
      DATABASE_ID,
      CONTRIBUTIONS_COLLECTION_ID,
      contributionId,
      {
        contributionId,
        campaignId,
        contributorName,
        amount: parseFloat(amount),
        utr,
        type,
        repaymentStatus: type === "loan" ? "pending" : null,
        isAnonymous: isAnonymous || false,
        createdAt: new Date().toISOString(),
      }
    );

    // Update campaign collected amount
    const newCollectedAmount = campaign.collectedAmount + parseFloat(amount);
    await databases.updateDocument(
      DATABASE_ID,
      CAMPAIGNS_COLLECTION_ID,
      campaignId,
      {
        collectedAmount: newCollectedAmount,
      }
    );

    return createResponse(
      {
        contributionId: contribution.contributionId,
        campaignId: contribution.campaignId,
        amount: contribution.amount,
        type: contribution.type,
        repaymentStatus: contribution.repaymentStatus,
        createdAt: contribution.createdAt,
      },
      201,
      "Contribution recorded successfully"
    );
  } catch (error) {
    return handleError(error, "Failed to record contribution");
  }
}

async function getCampaignContributions(req, campaignId) {
  try {
    const contributionsQuery = await databases.listDocuments(
      DATABASE_ID,
      CONTRIBUTIONS_COLLECTION_ID,
      [
        sdk.Query.equal("campaignId", campaignId),
        sdk.Query.orderDesc("createdAt"),
      ]
    );

    const contributions = contributionsQuery.documents.map((contrib) => ({
      contributionId: contrib.contributionId,
      contributorName: contrib.isAnonymous
        ? "Anonymous"
        : contrib.contributorName,
      amount: contrib.amount,
      type: contrib.type,
      repaymentStatus: contrib.repaymentStatus,
      utr: contrib.utr,
      createdAt: contrib.createdAt,
    }));

    return createResponse(contributions);
  } catch (error) {
    return handleError(error, "Failed to get contributions");
  }
}

async function markLoanRepaid(req, contributionId) {
  try {
    const authHeader = req.headers["authorization"];
    if (!authHeader) {
      return createResponse(null, 401, "Authorization required");
    }

    const token = authHeader.replace("Bearer ", "");
    const decoded = JSON.parse(Buffer.from(token, "base64").toString());

    // Get contribution
    const contribution = await databases.getDocument(
      DATABASE_ID,
      CONTRIBUTIONS_COLLECTION_ID,
      contributionId
    );

    if (contribution.type !== "loan") {
      return createResponse(null, 400, "Only loans can be marked as repaid");
    }

    // Verify campaign ownership
    const campaign = await databases.getDocument(
      DATABASE_ID,
      CAMPAIGNS_COLLECTION_ID,
      contribution.campaignId
    );

    if (campaign.hostId !== decoded.userId) {
      return createResponse(
        null,
        403,
        "Unauthorized to update this contribution"
      );
    }

    const updatedContribution = await databases.updateDocument(
      DATABASE_ID,
      CONTRIBUTIONS_COLLECTION_ID,
      contributionId,
      {
        repaymentStatus: "repaid",
      }
    );

    return createResponse(
      {
        contributionId: updatedContribution.contributionId,
        repaymentStatus: updatedContribution.repaymentStatus,
      },
      200,
      "Loan marked as repaid"
    );
  } catch (error) {
    return handleError(error, "Failed to mark loan as repaid");
  }
}

// Main function
module.exports = async ({ req, res, log, error }) => {
  try {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
      return createResponse(null, 200, "OK");
    }

    // Initialize Appwrite
    initializeAppwrite(req);

    // Parse URL path
    const url = new URL(req.url, `http://${req.headers.host}`);
    const path = url.pathname;
    const method = req.method;

    log(`${method} ${path}`);

    // Route handling
    if (path === "/auth/register" && method === "POST") {
      return await registerUser(req);
    }

    if (path === "/auth/login" && method === "POST") {
      return await loginUser(req);
    }

    if (path === "/auth/verify-otp" && method === "POST") {
      return await verifyOTP(req);
    }

    if (path === "/auth/user" && method === "GET") {
      return await getCurrentUser(req);
    }

    if (path === "/campaigns" && method === "POST") {
      return await createCampaign(req);
    }

    if (path === "/campaigns" && method === "GET") {
      return await getUserCampaigns(req);
    }

    if (path.startsWith("/campaigns/") && method === "GET") {
      const campaignId = path.split("/")[2];
      if (campaignId && !path.includes("/contributions")) {
        return await getCampaign(req, campaignId);
      }
      if (campaignId && path.endsWith("/contributions")) {
        return await getCampaignContributions(req, campaignId);
      }
    }

    if (path.startsWith("/campaigns/") && method === "PUT") {
      const campaignId = path.split("/")[2];
      return await updateCampaign(req, campaignId);
    }

    if (path === "/contributions" && method === "POST") {
      return await makeContribution(req);
    }

    if (
      path.startsWith("/contributions/") &&
      path.endsWith("/repay") &&
      method === "PUT"
    ) {
      const contributionId = path.split("/")[2];
      return await markLoanRepaid(req, contributionId);
    }

    // Default route
    return createResponse(
      {
        service: "FriendFund API",
        version: "2.0.0",
        endpoints: [
          "POST /auth/register",
          "POST /auth/login",
          "POST /auth/verify-otp",
          "GET /auth/user",
          "POST /campaigns",
          "GET /campaigns",
          "GET /campaigns/:id",
          "PUT /campaigns/:id",
          "GET /campaigns/:id/contributions",
          "POST /contributions",
          "PUT /contributions/:id/repay",
        ],
      },
      200,
      "FriendFund API is running"
    );
  } catch (err) {
    error("Unhandled error:", err);
    return handleError(err, "Internal server error");
  }
};
