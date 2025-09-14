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
  databaseId: process.env.APPWRITE_DATABASE_ID || "68b5433d0004cadff5ff",
  collections: {
    campaigns: process.env.CAMPAIGNS_COLLECTION_ID || "68b54652001a8a757571",
    contributions:
      process.env.CONTRIBUTIONS_COLLECTION_ID || "68b54a0700208ba7fdaa",
    notifications: process.env.NOTIFICATIONS_COLLECTION_ID || "notifications",
  },
  buckets: {
    screenshots: process.env.SCREENSHOTS_BUCKET_ID || "68c66749001ad2d77cfa",
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

  // Comprehensive CORS headers for web applications
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods":
      "GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD",
    "Access-Control-Allow-Headers": [
      "Content-Type",
      "Authorization",
      "x-appwrite-user-id",
      "x-appwrite-user-jwt",
      "x-appwrite-project",
      "Accept",
      "Accept-Language",
      "Accept-Encoding",
      "Cache-Control",
      "Pragma",
      "Origin",
      "Referer",
      "User-Agent",
    ].join(", "),
    "Access-Control-Allow-Credentials": "false", // Set to false when using "*" for origin
    "Access-Control-Max-Age": "86400", // 24 hours
    "Access-Control-Expose-Headers": "Content-Length, Content-Range",
  };

  // Handle preflight requests (CORS)
  if (method === "OPTIONS") {
    log(`========== CORS PREFLIGHT REQUEST ==========`);
    log(`Origin: ${headers.origin || "Not provided"}`);
    log(
      `Access-Control-Request-Method: ${
        headers["access-control-request-method"] || "Not provided"
      }`
    );
    log(
      `Access-Control-Request-Headers: ${
        headers["access-control-request-headers"] || "Not provided"
      }`
    );
    log(`Responding with CORS headers and 200 status`);

    return res.json(
      {
        message: "CORS preflight successful",
        timestamp: new Date().toISOString(),
        method: method,
        path: path,
        corsEnabled: true,
      },
      200,
      corsHeaders
    );
  }

  // Handle direct function calls (for testing)
  if (method === "GET" && (path === "/" || path === "")) {
    log(`Direct function call detected, returning function info`);
    return res.json(
      {
        message: "FriendFund Backend Function is running",
        version: "1.0.0",
        endpoints: [
          "health",
          "auth",
          "campaigns",
          "contributions",
          "ocr",
          "notifications",
          "users",
          "qr",
        ],
        usage:
          "Send POST requests with {path: '/endpoint', method: 'METHOD', bodyJson: {...}} in the body",
      },
      200,
      corsHeaders
    );
  }

  log(`========== APPWRITE FUNCTION EXECUTION START ==========`);
  log(`Timestamp: ${new Date().toISOString()}`);
  log(`Function Environment Variables Check:`);
  log(
    `- APPWRITE_FUNCTION_PROJECT_ID: ${
      process.env.APPWRITE_FUNCTION_PROJECT_ID || "NOT SET"
    }`
  );
  log(
    `- APPWRITE_DATABASE_ID: ${process.env.APPWRITE_DATABASE_ID || "NOT SET"}`
  );
  log(
    `- CAMPAIGNS_COLLECTION_ID: ${
      process.env.CAMPAIGNS_COLLECTION_ID || "NOT SET"
    }`
  );

  try {
    // Parse request data more safely
    let payload = {};
    let userId = headers["x-appwrite-user-id"];

    log(`========== REQUEST PARSING ==========`);
    log(`Request Method: ${method}`);
    log(`Request Path: ${path}`);
    log(`User ID from Headers: ${userId || "NOT PROVIDED"}`);
    log(`Headers: ${JSON.stringify(headers, null, 2)}`);
    log(`BodyRaw Type: ${typeof bodyRaw}`);
    log(`BodyRaw Length: ${bodyRaw ? bodyRaw.length : 0}`);
    log(`BodyRaw Content: ${bodyRaw || "EMPTY"}`);

    // Safely check if bodyJson exists and is valid
    let bodyJsonSafe = null;
    try {
      if (bodyJson !== null && bodyJson !== undefined) {
        bodyJsonSafe = bodyJson;
        log(`BodyJson Type: ${typeof bodyJson}`);
        log(`BodyJson Content: ${JSON.stringify(bodyJson, null, 2)}`);
      } else {
        log(`BodyJson is null or undefined`);
      }
    } catch (jsonError) {
      log(`ERROR accessing bodyJson: ${jsonError.message}`);
      error(`BodyJson access error: ${jsonError.stack}`);
    }

    log(`========== PAYLOAD PROCESSING ==========`);
    // Handle different ways the body might be sent
    if (bodyJsonSafe && typeof bodyJsonSafe === "object") {
      payload = bodyJsonSafe;
      log(`Using bodyJson as payload`);
    } else if (
      bodyRaw &&
      typeof bodyRaw === "string" &&
      bodyRaw.trim() !== ""
    ) {
      try {
        const parsed = JSON.parse(bodyRaw);
        payload = parsed;
        log(`Successfully parsed bodyRaw as JSON`);
      } catch (parseError) {
        log(`ERROR parsing bodyRaw: ${parseError.message}`);
        error(`BodyRaw parse error: ${parseError.stack}`);
        payload = {};
      }
    } else {
      log(`No valid body data found, using empty payload`);
      payload = {};
    }

    // Store the actual request data if it exists
    let requestData = {};
    if (payload.bodyJson && typeof payload.bodyJson === "object") {
      log(`Found nested bodyJson in payload`);
      requestData = payload.bodyJson;
    } else {
      // If no bodyJson, the payload itself might be the request data (for GET requests)
      requestData = payload;
    }

    log(`Final Payload: ${JSON.stringify(payload, null, 2)}`);

    log(`========== ROUTING ==========`);
    // In Appwrite functions, path is always "/", so we MUST get the real path from payload
    const requestPath = payload.path;
    const requestMethod = payload.method || method;

    log(`Original URL path (always "/" in Appwrite functions): '${path}'`);
    log(`Payload path: '${payload.path || "NOT PROVIDED"}'`);
    log(`Payload method: '${payload.method || "NOT PROVIDED"}'`);
    log(`Final requestPath: '${requestPath || "MISSING"}'`);
    log(`Final requestMethod: '${requestMethod}'`);

    // Handle missing path in payload - this is critical for Appwrite functions
    if (!requestPath || requestPath === "/" || requestPath === "") {
      log(`ERROR: No valid path provided in payload`);
      log(
        `Appwrite functions require the path to be sent in the request body as 'path' field`
      );
      return res.json(
        Utils.errorResponse(
          'Missing API path. Please provide a \'path\' field in the request body (e.g., {"path": "/campaigns", "method": "GET"})',
          {
            receivedPayload: payload,
            expectedFormat: {
              path: "/endpoint",
              method: "GET|POST|PUT|DELETE|PATCH",
              bodyJson: "optional data object",
            },
          },
          400
        ),
        400,
        corsHeaders
      );
    }

    const route = requestPath.split("/").filter(Boolean);
    const endpoint = route[0] || "";
    const action = route[1] || "";
    const id = route[2] || "";

    log(`Parsed Route Array: [${route.join(", ")}]`);
    log(`Endpoint: '${endpoint}'`);
    log(`Action: '${action}'`);
    log(`ID: '${id}'`);
    log(`User ID: ${userId || "NOT PROVIDED"}`);

    log(`========== HANDLER ROUTING ==========`);

    // Route to appropriate handler
    switch (endpoint) {
      case "health":
        log(`Routing to: health endpoint`);
        return res.json(
          Utils.successResponse("Backend is healthy", {
            timestamp: new Date().toISOString(),
            version: "1.0.0",
          }),
          200,
          corsHeaders
        );

      case "auth":
        log(`Routing to: auth handler`);
        return await handleAuth(
          requestMethod,
          action,
          requestData,
          res,
          log,
          error,
          corsHeaders
        );

      case "campaigns":
        log(`Routing to: campaigns handler`);
        return await handleCampaigns(
          requestMethod,
          action,
          id,
          requestData,
          userId,
          res,
          log,
          error,
          corsHeaders
        );

      case "contributions":
        log(`Routing to: contributions handler`);
        return await handleContributions(
          requestMethod,
          action,
          id,
          requestData,
          userId,
          res,
          log,
          error,
          corsHeaders
        );

      case "ocr":
        log(`Routing to: ocr handler`);
        return await handleOCR(
          requestMethod,
          action,
          requestData,
          userId,
          res,
          log,
          error,
          corsHeaders
        );

      case "notifications":
        log(`Routing to: notifications handler`);
        return await handleNotifications(
          requestMethod,
          action,
          id,
          requestData,
          userId,
          res,
          log,
          error,
          corsHeaders
        );

      case "users":
        log(`Routing to: users handler`);
        return await handleUsers(
          requestMethod,
          action,
          id,
          requestData,
          userId,
          res,
          log,
          error,
          corsHeaders
        );

      case "qr":
        log(`Routing to: qr handler`);
        return await handleQR(requestMethod, id, res, log, error, corsHeaders);

      default:
        log(`ERROR: No handler found for endpoint: '${endpoint}'`);
        log(
          `Available endpoints: health, auth, campaigns, contributions, ocr, notifications, users, qr`
        );
        return res.json(
          Utils.errorResponse("Endpoint not found", null, 404),
          404,
          corsHeaders
        );
    }
  } catch (err) {
    log(`========== UNHANDLED ERROR ==========`);
    log(`Error Message: ${err.message}`);
    log(`Error Stack: ${err.stack}`);
    error(`Unhandled error in main function: ${err.message}`);
    error(`Full error stack: ${err.stack}`);
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
async function handleAuth(
  method,
  action,
  payload,
  res,
  log,
  error,
  corsHeaders
) {
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
  error,
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
  error,
  corsHeaders
) {
  log(`========== CAMPAIGNS HANDLER ==========`);
  log(`Method: ${method}`);
  log(`Action: ${action}`);
  log(`ID: ${id}`);
  log(`User ID: ${userId}`);
  log(`Payload: ${JSON.stringify(payload, null, 2)}`);

  try {
    log(`========== CAMPAIGNS ROUTING ==========`);
    switch (method) {
      case "GET":
        if (id) {
          log(`Routing to: Get single campaign with ID: ${id}`);
          return await getCampaign(id, res, log, corsHeaders);
        } else if (action === "user" && userId) {
          log(`Routing to: Get user campaigns for user: ${userId}`);
          return await getUserCampaigns(userId, res, log, corsHeaders);
        } else {
          log(`Routing to: Get all campaigns`);
          return await getAllCampaigns(res, log, error, corsHeaders);
        }

      case "POST":
        if (action === "link" && id) {
          log(`Routing to: Generate campaign link for ID: ${id}`);
          return await generateCampaignLink(id, res, corsHeaders);
        } else {
          log(`Routing to: Create new campaign`);
          return await createCampaign(payload, userId, res, log, corsHeaders);
        }

      case "PUT":
      case "PATCH":
        if (id) {
          log(`Routing to: Update campaign with ID: ${id}`);
          return await updateCampaign(id, payload, userId, res, corsHeaders);
        }
        break;

      case "DELETE":
        if (id) {
          log(`Routing to: Delete campaign with ID: ${id}`);
          return await deleteCampaign(id, userId, res, corsHeaders);
        }
        break;
    }

    log(`ERROR: Invalid campaign operation - no matching route found`);
    return res.json(
      Utils.errorResponse("Invalid campaign operation"),
      400,
      corsHeaders
    );
  } catch (err) {
    log(`ERROR in campaigns handler: ${err.message}`);
    error(`Campaigns handler error: ${err.stack}`);
    return res.json(
      Utils.errorResponse("Campaign operation failed", err.message),
      500,
      corsHeaders
    );
  }
}

async function getAllCampaigns(res, log, error, corsHeaders) {
  log(`========== GET ALL CAMPAIGNS ==========`);
  log(`Database ID: ${config.databaseId}`);
  log(`Collection ID: ${config.collections.campaigns}`);

  try {
    log(`Querying campaigns from database...`);
    const campaigns = await databases.listDocuments(
      config.databaseId,
      config.collections.campaigns,
      [
        Query.equal("status", "active"),
        Query.orderDesc("createdAt"),
        Query.limit(50),
      ]
    );

    log(`Found ${campaigns.documents.length} campaigns`);
    log(
      `Campaign documents: ${JSON.stringify(
        campaigns.documents.map((c) => ({ id: c.$id, title: c.title })),
        null,
        2
      )}`
    );

    // Enrich campaigns with host names
    log(`Enriching campaigns with host names...`);
    const enrichedCampaigns = await Promise.all(
      campaigns.documents.map(async (campaign, index) => {
        log(
          `Processing campaign ${index + 1}/${campaigns.documents.length}: ${
            campaign.$id
          }`
        );
        try {
          const hostUser = await users.get(campaign.hostId);
          log(`Found host user for campaign ${campaign.$id}: ${hostUser.name}`);

          const enriched = {
            id: campaign.$id,
            title: campaign.title,
            description: campaign.description,
            purpose: campaign.purpose,
            targetAmount: campaign.targetAmount,
            collectedAmount: campaign.collectedAmount,
            hostId: campaign.hostId,
            hostName: hostUser.name,
            createdAt: campaign.$createdAt,
            dueDate: campaign.dueDate || null,
            status: campaign.status,
            contributions: [], // Will be populated when needed
          };

          log(
            `Enriched campaign ${campaign.$id}: ${JSON.stringify(
              enriched,
              null,
              2
            )}`
          );
          return enriched;
        } catch (err) {
          log(
            `ERROR getting host user for campaign ${campaign.$id}: ${err.message}`
          );
          // If host user not found, use default name
          const enriched = {
            id: campaign.$id,
            title: campaign.title,
            description: campaign.description,
            purpose: campaign.purpose,
            targetAmount: campaign.targetAmount,
            collectedAmount: campaign.collectedAmount,
            hostId: campaign.hostId,
            hostName: "Unknown User",
            createdAt: campaign.$createdAt,
            dueDate: campaign.dueDate || null,
            status: campaign.status,
            contributions: [],
          };

          log(`Using default host name for campaign ${campaign.$id}`);
          return enriched;
        }
      })
    );

    log(`Successfully enriched all campaigns`);
    log(
      `Final enriched campaigns: ${JSON.stringify(enrichedCampaigns, null, 2)}`
    );

    const response = Utils.successResponse(
      "Campaigns retrieved successfully",
      enrichedCampaigns
    );

    log(`Sending response: ${JSON.stringify(response, null, 2)}`);
    return res.json(response, 200, corsHeaders);
  } catch (err) {
    log(`ERROR in getAllCampaigns: ${err.message}`);
    error(`getAllCampaigns error: ${err.stack}`);
    throw err;
  }
}

async function getCampaign(campaignId, res, log, corsHeaders) {
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
    createdAt: campaign.$createdAt,
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
    createdAt: campaign.$createdAt,
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
    createdAt: updatedCampaign.$createdAt,
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

  const updateData = {};

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
  error,
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
  error,
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
  error,
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
async function handleQR(method, campaignId, res, log, error, corsHeaders) {
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
