/**
 * FriendFund Unified Backend Function
 * Single Appwrite function handling all API endpoints
 *
 * ARCHITECTURE: Uses Appwrite Auth preferences instead of users collection for user data storage
 *
 * API Endpoints:
 * - POST /auth/register - Register new user (stores data in auth preferences)
 * - POST /auth/login - User login (retrieves data from auth preferences)
 * - GET /users/{id} - Get user by ID (from Appwrite Users API)
 * - PUT /users/{id} - Update user profile (updates auth preferences)
 * - GET /campaigns - Get all active campaigns
 * - GET /campaigns/{id} - Get specific campaign with contributions
 * - GET /campaigns/user - Get current user's campaigns
 * - POST /campaigns - Create new campaign
 * - PUT /campaigns/{id} - Update campaign
 * - DELETE /campaigns/{id} - Delete campaign
 * - POST /campaigns/link/{id} - Generate campaign sharing link
 * - GET /contributions/campaign/{id} - Get campaign contributions
 * - GET /contributions/user/{id} - Get user contributions
 * - POST /contributions - Create new contribution
 * - PATCH /contributions/repaid/{id} - Mark loan as repaid
 * - POST /ocr/process - Process payment screenshot OCR
 * - GET /notifications/overdue - Get overdue loans
 * - POST /notifications/reminder - Send loan reminder
 * - GET /qr/{campaignId} - Generate QR code for campaign
 *
 * Author: Ayra Riyaz
 * Company: Pro26
 * Modified to align with Flutter frontend models and requirements
 */

const {
  Client,
  Databases,
  Storage,
  Users,
  ID,
  Query,
  Permission,
  Role,
} = require("node-appwrite");
const QRCode = require("qrcode");

// Configuration
const config = {
  endpoint:
    process.env.APPWRITE_FUNCTION_ENDPOINT || "https://cloud.appwrite.io/v1",
  projectId: process.env.APPWRITE_FUNCTION_PROJECT_ID,
  apiKey: process.env.APPWRITE_API_KEY,
  databaseId: process.env.APPWRITE_DATABASE_ID || "friendfund-db",
  collections: {
    campaigns: process.env.CAMPAIGNS_COLLECTION_ID || "campaigns",
    contributions: process.env.CONTRIBUTIONS_COLLECTION_ID || "contributions",
    notifications: process.env.NOTIFICATIONS_COLLECTION_ID || "notifications",
  },
  buckets: {
    screenshots: process.env.SCREENSHOTS_BUCKET_ID || "screenshots",
  },
  baseUrl: process.env.FRONTEND_BASE_URL || "https://friendfund.pro26.in",
};

// Initialize Appwrite client
const client = new Client()
  .setEndpoint(config.endpoint)
  .setProject(config.projectId)
  .setKey(config.apiKey);

const databases = new Databases(client);
const storage = new Storage(client);
const users = new Users(client);

// Utility functions
const Utils = {
  successResponse: (message, data = null) => ({
    success: true,
    message,
    data,
    timestamp: new Date().toISOString(),
  }),

  errorResponse: (message, errors = null, code = 400) => ({
    success: false,
    message,
    errors,
    code,
    timestamp: new Date().toISOString(),
  }),

  validateRequired: (data, requiredFields) => {
    const missing = requiredFields.filter((field) => !data[field]);
    if (missing.length > 0) {
      throw new Error(`Missing required fields: ${missing.join(", ")}`);
    }
  },

  generateId: () => ID.unique(),

  sanitizeAmount: (amount) => {
    const num = parseFloat(amount);
    if (isNaN(num) || num <= 0) {
      throw new Error("Invalid amount");
    }
    return Math.round(num * 100) / 100; // Round to 2 decimal places
  },

  validateUTR: (utr) => {
    const utrPattern = /^\d{12}$/;
    if (!utrPattern.test(utr)) {
      throw new Error("Invalid UTR format. UTR must be 12 digits.");
    }
    return utr;
  },

  generateCampaignLink: (campaignId) => {
    return `${config.baseUrl}/campaign/${campaignId}`;
  },
};

// OCR Processing (simplified for this implementation)
const OCRService = {
  async processImage(imageData) {
    // This is a simplified OCR implementation
    // In production, you would integrate with Google Vision API, Tesseract.js, or similar
    try {
      // Simulate OCR processing
      await new Promise((resolve) => setTimeout(resolve, 2000));

      // Mock extraction results
      // In real implementation, this would analyze the image
      const mockResults = {
        amount: null,
        utr: null,
        confidence: 0.85,
        rawText: "Transaction successful...",
      };

      return {
        success: true,
        data: mockResults,
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
      };
    }
  },
};

/**
 * Main function handler
 */
module.exports = async ({ req, res, log, error }) => {
  const { method, path, headers, bodyRaw, bodyJson } = req;

  // CORS headers
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
    "Access-Control-Allow-Headers":
      "Content-Type, Authorization, x-appwrite-user-id",
  };

  // Handle preflight requests
  if (method === "OPTIONS") {
    return res.json({}, 200, corsHeaders);
  }

  try {
    // Parse request data more safely
    let payload = {};
    let userId = headers["x-appwrite-user-id"];

    log(`Raw request data: method=${method}, path=${path}`);
    log(`Headers: ${JSON.stringify(headers)}`);
    log(`BodyRaw type: ${typeof bodyRaw}, value: ${bodyRaw}`);
    log(
      `BodyJson type: ${typeof bodyJson}, value: ${JSON.stringify(bodyJson)}`
    );

    // Handle different ways the body might be sent
    if (bodyJson && typeof bodyJson === "object") {
      payload = bodyJson;
    } else if (bodyRaw && typeof bodyRaw === "string") {
      try {
        const parsed = JSON.parse(bodyRaw);
        payload = parsed;
      } catch (parseError) {
        log(`Error parsing bodyRaw: ${parseError}`);
        payload = {};
      }
    }

    // If payload has nested bodyJson, extract it
    if (payload.bodyJson && typeof payload.bodyJson === "object") {
      payload = payload.bodyJson;
    }

    log(`Final parsed payload: ${JSON.stringify(payload)}`);

    // Parse route from the payload path or fallback to URL path
    const requestPath = payload.path || path;
    const requestMethod = payload.method || method;

    const route = requestPath.split("/").filter(Boolean);
    const endpoint = route[0] || "";
    const action = route[1] || "";
    const id = route[2] || "";

    log(`Request: ${requestMethod} ${requestPath}`);
    log(`User ID: ${userId}`);
    log(`Endpoint: ${endpoint}, Action: ${action}, ID: ${id}`);

    // Route to appropriate handler
    switch (endpoint) {
      case "health":
        return res.json(
          Utils.successResponse("Backend is healthy", {
            timestamp: new Date().toISOString(),
            version: "1.0.0",
          }),
          200,
          corsHeaders
        );

      case "auth":
        return await handleAuth(
          requestMethod,
          action,
          payload,
          res,
          log,
          corsHeaders
        );

      case "campaigns":
        return await handleCampaigns(
          requestMethod,
          action,
          id,
          payload,
          userId,
          res,
          log,
          corsHeaders
        );

      case "contributions":
        return await handleContributions(
          requestMethod,
          action,
          id,
          payload,
          userId,
          res,
          log,
          corsHeaders
        );

      case "ocr":
        return await handleOCR(
          requestMethod,
          action,
          payload,
          userId,
          res,
          log,
          corsHeaders
        );

      case "notifications":
        return await handleNotifications(
          requestMethod,
          action,
          id,
          payload,
          userId,
          res,
          log,
          corsHeaders
        );

      case "users":
        return await handleUsers(
          requestMethod,
          action,
          id,
          payload,
          userId,
          res,
          log,
          corsHeaders
        );

      case "qr":
        return await handleQR(requestMethod, id, res, log, corsHeaders);

      default:
        return res.json(
          Utils.errorResponse("Endpoint not found", null, 404),
          404,
          corsHeaders
        );
    }
  } catch (err) {
    error(`Unhandled error: ${err.message}`);
    return res.json(
      Utils.errorResponse("Internal server error", err.message, 500),
      500,
      corsHeaders
    );
  }
};

/**
 * Authentication handlers
 */
async function handleAuth(method, action, payload, res, log, corsHeaders) {
  try {
    switch (method) {
      case "POST":
        if (action === "register") {
          return await registerUser(payload, res, log, corsHeaders);
        } else if (action === "login") {
          return await loginUser(payload, res, log, corsHeaders);
        }
        break;
    }

    return res.json(
      Utils.errorResponse("Invalid auth operation"),
      400,
      corsHeaders
    );
  } catch (err) {
    return res.json(
      Utils.errorResponse("Authentication failed", err.message),
      500,
      corsHeaders
    );
  }
}

async function registerUser(payload, res, log, corsHeaders) {
  Utils.validateRequired(payload, ["name", "phoneNumber", "email", "password"]);

  try {
    // Create user in Appwrite Auth
    const user = await users.create(
      Utils.generateId(),
      payload.email,
      payload.phoneNumber,
      payload.password,
      payload.name
    );

    // Update user preferences instead of creating database document
    const userPrefs = {
      phoneNumber: payload.phoneNumber?.trim() || "",
      upiId: payload.upiId || "",
      profileImage: payload.profileImage || "",
      joinedAt: new Date().toISOString(),
    };

    await users.updatePrefs(user.$id, userPrefs);

    log(`User registered: ${user.$id}`);

    return res.json(
      Utils.successResponse("User registered successfully", {
        id: user.$id,
        name: user.name,
        phoneNumber: userPrefs.phoneNumber,
        email: user.email,
        upiId: userPrefs.upiId,
        profileImage: userPrefs.profileImage,
        joinedAt: userPrefs.joinedAt,
      }),
      201,
      corsHeaders
    );
  } catch (err) {
    return res.json(
      Utils.errorResponse("Registration failed", err.message),
      400,
      corsHeaders
    );
  }
}

async function loginUser(payload, res, log, corsHeaders) {
  Utils.validateRequired(payload, ["email", "password"]);

  try {
    // In a real implementation, you would validate credentials
    // For now, we'll simulate successful login and return user data

    // Get user by email from Users API
    const userList = await users.list([Query.equal("email", payload.email)]);

    if (userList.users.length === 0) {
      return res.json(
        Utils.errorResponse("Invalid credentials"),
        401,
        corsHeaders
      );
    }

    const user = userList.users[0];
    const prefs = user.prefs || {};

    log(`User logged in: ${user.$id}`);

    return res.json(
      Utils.successResponse("Login successful", {
        id: user.$id,
        name: user.name,
        phoneNumber: prefs.phoneNumber || "",
        email: user.email,
        upiId: prefs.upiId || "",
        profileImage: prefs.profileImage || "",
        joinedAt: user.$createdAt,
      }),
      200,
      corsHeaders
    );
  } catch (err) {
    return res.json(
      Utils.errorResponse("Login failed", err.message),
      500,
      corsHeaders
    );
  }
}

/**
 * User management handlers
 */
async function handleUsers(
  method,
  action,
  id,
  payload,
  userId,
  res,
  log,
  corsHeaders
) {
  try {
    switch (method) {
      case "GET":
        if (id) {
          return await getUser(id, res, corsHeaders);
        }
        break;

      case "PUT":
      case "PATCH":
        if (id) {
          return await updateUser(id, payload, userId, res, corsHeaders);
        }
        break;
    }

    return res.json(
      Utils.errorResponse("Invalid user operation"),
      400,
      corsHeaders
    );
  } catch (err) {
    return res.json(
      Utils.errorResponse("User operation failed", err.message),
      500,
      corsHeaders
    );
  }
}

async function getUser(userId, res, corsHeaders) {
  // Get user data from Appwrite Auth Users API
  const user = await users.get(userId);

  // Get additional preferences
  const prefs = user.prefs || {};

  return res.json(
    Utils.successResponse("User retrieved successfully", {
      id: user.$id,
      name: user.name,
      phoneNumber: prefs.phoneNumber || "",
      email: user.email,
      upiId: prefs.upiId || "",
      profileImage: prefs.profileImage || "",
      joinedAt: user.$createdAt,
    }),
    200,
    corsHeaders
  );
}

async function updateUser(userId, payload, currentUserId, res, corsHeaders) {
  // Check if user is updating their own profile
  if (userId !== currentUserId) {
    return res.json(
      Utils.errorResponse("Unauthorized to update this user", null, 403),
      403,
      corsHeaders
    );
  }

  // Get current user to merge with new data
  const currentUser = await users.get(userId);
  const currentPrefs = currentUser.prefs || {};

  // Prepare update data for preferences
  const updatePrefs = { ...currentPrefs };

  if (payload.phoneNumber) updatePrefs.phoneNumber = payload.phoneNumber.trim();
  if (payload.upiId) updatePrefs.upiId = payload.upiId.trim();
  if (payload.profileImage) updatePrefs.profileImage = payload.profileImage;

  // Update preferences
  if (
    Object.keys(updatePrefs).length > 0 &&
    JSON.stringify(updatePrefs) !== JSON.stringify(currentPrefs)
  ) {
    await users.updatePrefs(userId, updatePrefs);
  }

  // Update name if provided (this requires updating the user account)
  if (payload.name && payload.name.trim() !== currentUser.name) {
    await users.updateName(userId, payload.name.trim());
  }

  // Get updated user data
  const updatedUser = await users.get(userId);
  const updatedPrefs = updatedUser.prefs || {};

  return res.json(
    Utils.successResponse("User updated successfully", {
      id: updatedUser.$id,
      name: updatedUser.name,
      phoneNumber: updatedPrefs.phoneNumber || "",
      email: updatedUser.email,
      upiId: updatedPrefs.upiId || "",
      profileImage: updatedPrefs.profileImage || "",
      joinedAt: updatedUser.$createdAt,
    }),
    200,
    corsHeaders
  );
}

/**
 * Campaign handlers
 */
async function handleCampaigns(
  method,
  action,
  id,
  payload,
  userId,
  res,
  log,
  corsHeaders
) {
  try {
    switch (method) {
      case "GET":
        if (id) {
          // Get single campaign
          return await getCampaign(id, res, corsHeaders);
        } else if (action === "user" && userId) {
          // Get user's campaigns
          return await getUserCampaigns(userId, res, corsHeaders);
        } else {
          // Get all campaigns
          return await getAllCampaigns(res, corsHeaders);
        }

      case "POST":
        if (action === "link" && id) {
          // Generate campaign link
          return await generateCampaignLink(id, res, corsHeaders);
        } else {
          // Create campaign
          return await createCampaign(payload, userId, res, log, corsHeaders);
        }

      case "PUT":
      case "PATCH":
        if (id) {
          // Update campaign
          return await updateCampaign(id, payload, userId, res, corsHeaders);
        }
        break;

      case "DELETE":
        if (id) {
          // Delete campaign
          return await deleteCampaign(id, userId, res, corsHeaders);
        }
        break;
    }

    return res.json(
      Utils.errorResponse("Invalid campaign operation"),
      400,
      corsHeaders
    );
  } catch (err) {
    return res.json(
      Utils.errorResponse("Campaign operation failed", err.message),
      500,
      corsHeaders
    );
  }
}

async function getAllCampaigns(res, corsHeaders) {
  const campaigns = await databases.listDocuments(
    config.databaseId,
    config.collections.campaigns,
    [
      Query.equal("status", "active"),
      Query.orderDesc("createdAt"),
      Query.limit(50),
    ]
  );

  // Enrich campaigns with host names
  const enrichedCampaigns = await Promise.all(
    campaigns.documents.map(async (campaign) => {
      try {
        const hostUser = await users.get(campaign.hostId);

        return {
          id: campaign.$id,
          title: campaign.title,
          description: campaign.description,
          purpose: campaign.purpose,
          targetAmount: campaign.targetAmount,
          collectedAmount: campaign.collectedAmount,
          hostId: campaign.hostId,
          hostName: hostUser.name,
          createdAt: campaign.createdAt,
          dueDate: campaign.dueDate || null,
          status: campaign.status,
          contributions: [], // Will be populated when needed
        };
      } catch (err) {
        // If host user not found, use default name
        return {
          id: campaign.$id,
          title: campaign.title,
          description: campaign.description,
          purpose: campaign.purpose,
          targetAmount: campaign.targetAmount,
          collectedAmount: campaign.collectedAmount,
          hostId: campaign.hostId,
          hostName: "Unknown User",
          createdAt: campaign.createdAt,
          dueDate: campaign.dueDate || null,
          status: campaign.status,
          contributions: [],
        };
      }
    })
  );

  return res.json(
    Utils.successResponse(
      "Campaigns retrieved successfully",
      enrichedCampaigns
    ),
    200,
    corsHeaders
  );
}

async function getCampaign(campaignId, res, corsHeaders) {
  const campaign = await databases.getDocument(
    config.databaseId,
    config.collections.campaigns,
    campaignId
  );

  // Get host user information
  let hostName = "Unknown User";
  try {
    const hostUser = await users.get(campaign.hostId);
    hostName = hostUser.name;
  } catch (err) {
    // Host user not found, keep default name
  }

  // Get campaign contributions
  const contributions = await databases.listDocuments(
    config.databaseId,
    config.collections.contributions,
    [Query.equal("campaignId", campaignId), Query.orderDesc("createdAt")]
  );

  // Format contributions to match frontend model
  const formattedContributions = contributions.documents.map((contrib) => ({
    id: contrib.$id,
    campaignId: contrib.campaignId,
    contributorId: contrib.contributorId,
    contributorName: contrib.contributorName,
    amount: contrib.amount,
    type: contrib.type,
    date: contrib.createdAt, // Map createdAt to date
    repaymentStatus: contrib.repaymentStatus,
    repaymentDueDate: contrib.repaymentDueDate || null,
    utrNumber: contrib.utr, // Map utr to utrNumber
  }));

  const enrichedCampaign = {
    id: campaign.$id,
    title: campaign.title,
    description: campaign.description,
    purpose: campaign.purpose,
    targetAmount: campaign.targetAmount,
    collectedAmount: campaign.collectedAmount,
    hostId: campaign.hostId,
    hostName: hostName,
    createdAt: campaign.createdAt,
    dueDate: campaign.dueDate || null,
    status: campaign.status,
    contributions: formattedContributions,
  };

  return res.json(
    Utils.successResponse("Campaign retrieved successfully", enrichedCampaign),
    200,
    corsHeaders
  );
}

async function getUserCampaigns(userId, res, corsHeaders) {
  const campaigns = await databases.listDocuments(
    config.databaseId,
    config.collections.campaigns,
    [Query.equal("hostId", userId), Query.orderDesc("createdAt")]
  );

  // Get user information for hostName
  let hostName = "Unknown User";
  try {
    const user = await users.get(userId);
    hostName = user.name;
  } catch (err) {
    // User not found, keep default name
  }

  // Format campaigns to match frontend model
  const formattedCampaigns = campaigns.documents.map((campaign) => ({
    id: campaign.$id,
    title: campaign.title,
    description: campaign.description,
    purpose: campaign.purpose,
    targetAmount: campaign.targetAmount,
    collectedAmount: campaign.collectedAmount,
    hostId: campaign.hostId,
    hostName: hostName,
    createdAt: campaign.createdAt,
    dueDate: campaign.dueDate || null,
    status: campaign.status,
    contributions: [], // Will be populated when needed
  }));

  return res.json(
    Utils.successResponse(
      "User campaigns retrieved successfully",
      formattedCampaigns
    ),
    200,
    corsHeaders
  );
}

async function createCampaign(payload, userId, res, log, corsHeaders) {
  Utils.validateRequired(payload, [
    "title",
    "description",
    "purpose",
    "targetAmount",
  ]);

  // Get user name for hostName from Users API
  let hostName = "Unknown User";
  try {
    const user = await users.get(userId);
    hostName = user.name;
  } catch (err) {
    // User not found, keep default name
    log(`Could not get user name for ${userId}: ${err.message}`);
  }

  const campaignData = {
    hostId: userId,
    title: payload.title.trim(),
    description: payload.description.trim(),
    purpose: payload.purpose.trim(),
    targetAmount: Utils.sanitizeAmount(payload.targetAmount),
    collectedAmount: 0,
    status: "active",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  if (payload.dueDate) {
    campaignData.dueDate = new Date(payload.dueDate).toISOString();
  }

  const campaign = await databases.createDocument(
    config.databaseId,
    config.collections.campaigns,
    Utils.generateId(),
    campaignData
  );

  // Generate campaign link and QR code
  const campaignLink = Utils.generateCampaignLink(campaign.$id);
  const qrCodeUrl = await generateQRCode(campaign.$id);

  // Update campaign with link and QR
  const updatedCampaign = await databases.updateDocument(
    config.databaseId,
    config.collections.campaigns,
    campaign.$id,
    {
      campaignLink,
      qrCodeUrl,
      updatedAt: new Date().toISOString(),
    }
  );

  log(`Campaign created: ${campaign.$id}`);

  // Return formatted response
  const formattedCampaign = {
    id: updatedCampaign.$id,
    title: updatedCampaign.title,
    description: updatedCampaign.description,
    purpose: updatedCampaign.purpose,
    targetAmount: updatedCampaign.targetAmount,
    collectedAmount: updatedCampaign.collectedAmount,
    hostId: updatedCampaign.hostId,
    hostName: hostName,
    createdAt: updatedCampaign.createdAt,
    dueDate: updatedCampaign.dueDate || null,
    status: updatedCampaign.status,
    contributions: [],
  };

  return res.json(
    Utils.successResponse("Campaign created successfully", formattedCampaign),
    201,
    corsHeaders
  );
}

async function updateCampaign(campaignId, payload, userId, res, corsHeaders) {
  // First check if user owns the campaign
  const existingCampaign = await databases.getDocument(
    config.databaseId,
    config.collections.campaigns,
    campaignId
  );

  if (existingCampaign.hostId !== userId) {
    return res.json(
      Utils.errorResponse("Unauthorized to update this campaign", null, 403),
      403,
      corsHeaders
    );
  }

  const updateData = {
    updatedAt: new Date().toISOString(),
  };

  // Only update allowed fields
  if (payload.title) updateData.title = payload.title.trim();
  if (payload.description) updateData.description = payload.description.trim();
  if (payload.status) updateData.status = payload.status;
  if (payload.targetAmount)
    updateData.targetAmount = Utils.sanitizeAmount(payload.targetAmount);

  const updatedCampaign = await databases.updateDocument(
    config.databaseId,
    config.collections.campaigns,
    campaignId,
    updateData
  );

  return res.json(
    Utils.successResponse("Campaign updated successfully", updatedCampaign),
    200,
    corsHeaders
  );
}

async function deleteCampaign(campaignId, userId, res, corsHeaders) {
  // First check if user owns the campaign
  const existingCampaign = await databases.getDocument(
    config.databaseId,
    config.collections.campaigns,
    campaignId
  );

  if (existingCampaign.hostId !== userId) {
    return res.json(
      Utils.errorResponse("Unauthorized to delete this campaign", null, 403),
      403,
      corsHeaders
    );
  }

  // Check if campaign has contributions - should not delete if it has contributions
  const contributions = await databases.listDocuments(
    config.databaseId,
    config.collections.contributions,
    [Query.equal("campaignId", campaignId)]
  );

  if (contributions.documents.length > 0) {
    return res.json(
      Utils.errorResponse(
        "Cannot delete campaign with existing contributions",
        null,
        400
      ),
      400,
      corsHeaders
    );
  }

  // Delete the campaign
  await databases.deleteDocument(
    config.databaseId,
    config.collections.campaigns,
    campaignId
  );

  return res.json(
    Utils.successResponse("Campaign deleted successfully"),
    200,
    corsHeaders
  );
}

async function generateCampaignLink(campaignId, res, corsHeaders) {
  const campaignLink = Utils.generateCampaignLink(campaignId);
  const qrCodeUrl = await generateQRCode(campaignId);

  return res.json(
    Utils.successResponse("Campaign link generated successfully", {
      campaignLink,
      qrCodeUrl,
    }),
    200,
    corsHeaders
  );
}

/**
 * Contribution handlers
 */
async function handleContributions(
  method,
  action,
  id,
  payload,
  userId,
  res,
  log,
  corsHeaders
) {
  try {
    switch (method) {
      case "GET":
        if (action === "campaign" && id) {
          // Get contributions for a campaign
          return await getCampaignContributions(id, res, corsHeaders);
        } else if (action === "user" && id) {
          // Get user's contributions
          return await getUserContributions(id, res, corsHeaders);
        }
        break;

      case "POST":
        // Create contribution
        return await createContribution(payload, userId, res, log, corsHeaders);

      case "PATCH":
        if (action === "repaid" && id) {
          // Mark loan as repaid
          return await markLoanRepaid(id, userId, res, corsHeaders);
        }
        break;
    }

    return res.json(
      Utils.errorResponse("Invalid contribution operation"),
      400,
      corsHeaders
    );
  } catch (err) {
    return res.json(
      Utils.errorResponse("Contribution operation failed", err.message),
      500,
      corsHeaders
    );
  }
}

async function getCampaignContributions(campaignId, res, corsHeaders) {
  const contributions = await databases.listDocuments(
    config.databaseId,
    config.collections.contributions,
    [Query.equal("campaignId", campaignId), Query.orderDesc("createdAt")]
  );

  // Format contributions to match frontend model
  const formattedContributions = contributions.documents.map((contrib) => ({
    id: contrib.$id,
    campaignId: contrib.campaignId,
    contributorId: contrib.contributorId,
    contributorName: contrib.contributorName,
    amount: contrib.amount,
    type: contrib.type,
    date: contrib.createdAt, // Map createdAt to date
    repaymentStatus: contrib.repaymentStatus,
    repaymentDueDate: contrib.repaymentDueDate || null,
    utrNumber: contrib.utr, // Map utr to utrNumber
  }));

  return res.json(
    Utils.successResponse(
      "Contributions retrieved successfully",
      formattedContributions
    ),
    200,
    corsHeaders
  );
}

async function getUserContributions(userId, res, corsHeaders) {
  const contributions = await databases.listDocuments(
    config.databaseId,
    config.collections.contributions,
    [Query.equal("contributorId", userId), Query.orderDesc("createdAt")]
  );

  // Format contributions to match frontend model
  const formattedContributions = contributions.documents.map((contrib) => ({
    id: contrib.$id,
    campaignId: contrib.campaignId,
    contributorId: contrib.contributorId,
    contributorName: contrib.contributorName,
    amount: contrib.amount,
    type: contrib.type,
    date: contrib.createdAt, // Map createdAt to date
    repaymentStatus: contrib.repaymentStatus,
    repaymentDueDate: contrib.repaymentDueDate || null,
    utrNumber: contrib.utr, // Map utr to utrNumber
  }));

  return res.json(
    Utils.successResponse(
      "User contributions retrieved successfully",
      formattedContributions
    ),
    200,
    corsHeaders
  );
}

async function createContribution(payload, userId, res, log, corsHeaders) {
  Utils.validateRequired(payload, [
    "campaignId",
    "amount",
    "utrNumber",
    "type",
  ]);

  // Validate campaign exists and is active
  const campaign = await databases.getDocument(
    config.databaseId,
    config.collections.campaigns,
    payload.campaignId
  );

  if (campaign.status !== "active") {
    return res.json(
      Utils.errorResponse("Campaign is not active"),
      400,
      corsHeaders
    );
  }

  // Validate UTR is unique for this campaign (map utrNumber to utr)
  const existingContribution = await databases.listDocuments(
    config.databaseId,
    config.collections.contributions,
    [
      Query.equal("campaignId", payload.campaignId),
      Query.equal("utr", Utils.validateUTR(payload.utrNumber)),
    ]
  );

  if (existingContribution.documents.length > 0) {
    return res.json(
      Utils.errorResponse("UTR already exists for this campaign"),
      400,
      corsHeaders
    );
  }

  // Get contributor name
  let contributorName = "Anonymous";
  if (!payload.isAnonymous && userId) {
    try {
      const contributor = await users.get(userId);
      contributorName = contributor.name;
    } catch (err) {
      // User not found, keep anonymous
    }
  }

  const contributionData = {
    campaignId: payload.campaignId,
    contributorId: userId || "anonymous",
    contributorName: contributorName,
    amount: Utils.sanitizeAmount(payload.amount),
    utr: Utils.validateUTR(payload.utrNumber), // Store as utr internally
    type: payload.type, // 'gift' or 'loan'
    repaymentStatus: payload.type === "loan" ? "pending" : "na",
    isAnonymous: payload.isAnonymous || false,
    paymentScreenshotUrl: payload.paymentScreenshotUrl || "",
    createdAt: new Date().toISOString(),
  };

  if (payload.type === "loan" && payload.repaymentDueDate) {
    contributionData.repaymentDueDate = new Date(
      payload.repaymentDueDate
    ).toISOString();
  }

  const contribution = await databases.createDocument(
    config.databaseId,
    config.collections.contributions,
    Utils.generateId(),
    contributionData
  );

  // Update campaign collected amount
  const newCollectedAmount = campaign.collectedAmount + contributionData.amount;
  await databases.updateDocument(
    config.databaseId,
    config.collections.campaigns,
    payload.campaignId,
    {
      collectedAmount: newCollectedAmount,
      updatedAt: new Date().toISOString(),
    }
  );

  log(
    `Contribution created: ${contribution.$id} for campaign: ${payload.campaignId}`
  );

  // Return formatted response
  const formattedContribution = {
    id: contribution.$id,
    campaignId: contribution.campaignId,
    contributorId: contribution.contributorId,
    contributorName: contribution.contributorName,
    amount: contribution.amount,
    type: contribution.type,
    date: contribution.createdAt, // Map createdAt to date
    repaymentStatus: contribution.repaymentStatus,
    repaymentDueDate: contribution.repaymentDueDate || null,
    utrNumber: contribution.utr, // Map utr to utrNumber
  };

  return res.json(
    Utils.successResponse(
      "Contribution created successfully",
      formattedContribution
    ),
    201,
    corsHeaders
  );
}

async function markLoanRepaid(contributionId, userId, res, corsHeaders) {
  const contribution = await databases.getDocument(
    config.databaseId,
    config.collections.contributions,
    contributionId
  );

  // Check if user is the campaign host
  const campaign = await databases.getDocument(
    config.databaseId,
    config.collections.campaigns,
    contribution.campaignId
  );

  if (campaign.hostId !== userId) {
    return res.json(
      Utils.errorResponse(
        "Unauthorized to mark this loan as repaid",
        null,
        403
      ),
      403,
      corsHeaders
    );
  }

  if (contribution.type !== "loan") {
    return res.json(
      Utils.errorResponse("Only loans can be marked as repaid"),
      400,
      corsHeaders
    );
  }

  const updatedContribution = await databases.updateDocument(
    config.databaseId,
    config.collections.contributions,
    contributionId,
    {
      repaymentStatus: "repaid",
      repaidAt: new Date().toISOString(),
    }
  );

  return res.json(
    Utils.successResponse(
      "Loan marked as repaid successfully",
      updatedContribution
    ),
    200,
    corsHeaders
  );
}

/**
 * OCR handlers
 */
async function handleOCR(
  method,
  action,
  payload,
  userId,
  res,
  log,
  corsHeaders
) {
  if (method !== "POST" || action !== "process") {
    return res.json(
      Utils.errorResponse("Invalid OCR operation"),
      400,
      corsHeaders
    );
  }

  if (!userId) {
    return res.json(
      Utils.errorResponse(
        "Authentication required for OCR processing",
        null,
        401
      ),
      401,
      corsHeaders
    );
  }

  // Process OCR (simplified implementation)
  const ocrResult = await OCRService.processImage(payload.imageData);

  if (!ocrResult.success) {
    return res.json(
      Utils.errorResponse("OCR processing failed", ocrResult.error),
      500,
      corsHeaders
    );
  }

  return res.json(
    Utils.successResponse("OCR processing completed", ocrResult.data),
    200,
    corsHeaders
  );
}

/**
 * Notification handlers
 */
async function handleNotifications(
  method,
  action,
  id,
  payload,
  userId,
  res,
  log,
  corsHeaders
) {
  try {
    switch (method) {
      case "POST":
        if (action === "reminder") {
          return await sendLoanReminder(payload, userId, res, log, corsHeaders);
        }
        break;

      case "GET":
        if (action === "overdue") {
          return await getOverdueLoans(userId, res, corsHeaders);
        }
        break;
    }

    return res.json(
      Utils.errorResponse("Invalid notification operation"),
      400,
      corsHeaders
    );
  } catch (err) {
    return res.json(
      Utils.errorResponse("Notification operation failed", err.message),
      500,
      corsHeaders
    );
  }
}

async function sendLoanReminder(payload, userId, res, log, corsHeaders) {
  Utils.validateRequired(payload, ["contributionId"]);

  // For now, just log the reminder (implement SMS/WhatsApp integration here)
  log(`Loan reminder sent for contribution: ${payload.contributionId}`);

  // Create notification record
  const notification = await databases.createDocument(
    config.databaseId,
    config.collections.notifications,
    Utils.generateId(),
    {
      contributionId: payload.contributionId,
      type: "loan_reminder",
      message: "Loan repayment reminder sent",
      sentAt: new Date().toISOString(),
      sentBy: userId,
    }
  );

  return res.json(
    Utils.successResponse("Reminder sent successfully", notification),
    200,
    corsHeaders
  );
}

async function getOverdueLoans(userId, res, corsHeaders) {
  // Get loans that are overdue (more than 30 days old and pending)
  const thirtyDaysAgo = new Date(
    Date.now() - 30 * 24 * 60 * 60 * 1000
  ).toISOString();

  const overdueLoans = await databases.listDocuments(
    config.databaseId,
    config.collections.contributions,
    [
      Query.equal("type", "loan"),
      Query.equal("repaymentStatus", "pending"),
      Query.lessThan("createdAt", thirtyDaysAgo),
    ]
  );

  return res.json(
    Utils.successResponse(
      "Overdue loans retrieved successfully",
      overdueLoans.documents
    ),
    200,
    corsHeaders
  );
}

/**
 * QR Code handlers
 */
async function handleQR(method, campaignId, res, log, corsHeaders) {
  if (method !== "GET") {
    return res.json(
      Utils.errorResponse("Invalid QR operation"),
      400,
      corsHeaders
    );
  }

  try {
    const qrCodeUrl = await generateQRCode(campaignId);

    return res.json(
      Utils.successResponse("QR code generated successfully", { qrCodeUrl }),
      200,
      corsHeaders
    );
  } catch (err) {
    return res.json(
      Utils.errorResponse("QR code generation failed", err.message),
      500,
      corsHeaders
    );
  }
}

/**
 * Helper function to generate QR code
 */
async function generateQRCode(campaignId) {
  const campaignLink = Utils.generateCampaignLink(campaignId);

  try {
    // Generate QR code as data URL
    const qrCodeDataUrl = await QRCode.toDataURL(campaignLink, {
      width: 300,
      margin: 2,
      color: {
        dark: "#000000",
        light: "#FFFFFF",
      },
    });

    // In a real implementation, you would save this to Appwrite Storage
    // For now, we'll return the data URL
    return qrCodeDataUrl;
  } catch (err) {
    throw new Error(`QR code generation failed: ${err.message}`);
  }
}
