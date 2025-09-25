import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_strategy/url_strategy.dart';
import 'controllers/auth_controller.dart';
import 'controllers/campaign_controller.dart';
import 'controllers/contribution_controller.dart';
import 'controllers/loan_repayment_controller.dart';
import 'services/appwrite_auth_service.dart';
import 'services/http_api_service.dart';
import 'theme/app_theme.dart';
import 'pages/home_screen.dart';
import 'pages/my_campaigns_screen.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/campaign_details_screen.dart';
import 'models/campaign.dart';
import 'pages/my_contributions_screen.dart';
import 'pages/profile_page.dart';
import 'pages/help_page.dart';
import 'pages/public_campaign_details_page.dart';
import 'widgets/contribution_modal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure URL strategy for web to remove hash
  if (kIsWeb) {
    setPathUrlStrategy();
  }

  // Initialize GetStorage for token management
  await GetStorage.init();

  // Initialize Appwrite for authentication only
  AppwriteService.initialize();

  // Initialize HTTP API service for backend communication
  final httpApiService = HttpApiService();

  // Initialize Controllers with dependency injection
  Get.put(httpApiService);
  Get.put(AuthController());
  Get.put(CampaignController());
  Get.put(ContributionController());
  Get.put(LoanRepaymentController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Friend Fund',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme
          .lightTheme, // Use light theme for both to maintain white and Violet design
      themeMode: ThemeMode.light,
      initialRoute: '/auth',
      getPages: [
        // Auth Routes
        GetPage(name: '/auth', page: () => const AuthWrapper()),
        GetPage(
          name: '/login',
          page: () => const GuestProtectedPage(child: LoginPage()),
        ),
        GetPage(
          name: '/register',
          page: () => const GuestProtectedPage(child: RegisterPage()),
        ),

        // App Routes (require authentication)
        GetPage(
          name: '/home',
          page: () => const AuthProtectedPage(child: HomeScreen()),
        ),
        GetPage(
          name: '/my-campaigns',
          page: () => const AuthProtectedPage(child: MyCampaignsScreen()),
        ),
        GetPage(
          name: '/add-campaign',
          page: () => const AuthProtectedPage(child: HomeScreen()),
        ),
        GetPage(
          name: '/campaign-details',
          page: () => AuthProtectedPage(
            child: Builder(
              builder: (context) {
                final arguments = Get.arguments;
                if (arguments != null && arguments is Campaign) {
                  return CampaignDetailsScreen(campaign: arguments);
                }
                // If no campaign provided, redirect to home
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.offAllNamed('/home');
                });
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        GetPage(
          name: '/my-contributions',
          page: () => const AuthProtectedPage(child: MyContributionsScreen()),
        ),
        GetPage(
          name: '/profile',
          page: () => const AuthProtectedPage(child: ProfilePage()),
        ),
        GetPage(
          name: '/help',
          page: () => const AuthProtectedPage(child: HelpPage()),
        ),

        // Public campaign details route (no authentication required)
        GetPage(
          name: '/campaign/:campaignId',
          page: () => Builder(
            builder: (context) {
              final campaignId = Get.parameters['campaignId'];
              if (campaignId != null && campaignId.isNotEmpty) {
                return PublicCampaignDetailsPage(campaignId: campaignId);
              }
              // If no campaign ID provided, redirect to home
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.offAllNamed('/home');
              });
              return const SizedBox.shrink();
            },
          ),
        ),

        // Public contribution modal route (no authentication required)
        GetPage(
          name: '/modal/contribute/:campaignId',
          page: () => Builder(
            builder: (context) {
              final campaignId = Get.parameters['campaignId'];
              if (campaignId != null && campaignId.isNotEmpty) {
                // Show the modal in a scaffold for direct URL access
                return Scaffold(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  body: Center(
                    child: EnhancedContributionModal(
                      campaignId: campaignId,
                      isFromQrCode: true, // This is accessed via QR code
                    ),
                  ),
                );
              }
              // If no campaign ID provided, redirect to home
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.offAllNamed('/home');
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
      unknownRoute: GetPage(
        name: '/notfound',
        page: () => const Scaffold(body: Center(child: Text('Page not found'))),
      ),
    );
  }
}

// Widget to protect routes that require being unauthenticated (guest only)
class GuestProtectedPage extends StatelessWidget {
  final Widget child;

  const GuestProtectedPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GetX<AuthController>(
      builder: (controller) {
        // Show loading while checking auth state
        if (controller.authStatus == AuthStatus.unknown ||
            controller.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryViolet),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // If authenticated, redirect to home
        if (controller.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed('/home');
          });
          return const SizedBox.shrink();
        }

        // User is not authenticated, show the guest page (login/register)
        return child;
      },
    );
  }
}

// Widget to protect routes that require authentication
class AuthProtectedPage extends StatelessWidget {
  final Widget child;

  const AuthProtectedPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GetX<AuthController>(
      builder: (controller) {
        // Show loading while checking auth state
        if (controller.authStatus == AuthStatus.unknown ||
            controller.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryViolet),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // If not authenticated, redirect to login
        if (!controller.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed('/login');
          });
          return const SizedBox.shrink();
        }

        // User is authenticated, show the protected page
        return child;
      },
    );
  }
}

// Auth Wrapper to check if user is authenticated
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<AuthController>(
      builder: (controller) {
        // Show loading while checking auth state
        if (controller.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryViolet),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // Redirect based on auth state
        if (controller.isAuthenticated) {
          // User is authenticated, redirect to home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed('/home');
          });
          return const SizedBox.shrink();
        } else {
          // User is not authenticated, show login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed('/login');
          });
          return const SizedBox.shrink();
        }
      },
    );
  }
}

// Middleware to protect authenticated routes
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    // If auth status is still being checked, allow access (will be handled by route)
    if (authController.authStatus == AuthStatus.unknown ||
        authController.isLoading) {
      return null;
    }

    // If user is not authenticated, redirect to login
    if (!authController.isAuthenticated) {
      return const RouteSettings(name: '/login');
    }

    return null; // Allow access to the route
  }
}

class GuestMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    // If auth status is still being checked, allow access (will be handled by route)
    if (authController.authStatus == AuthStatus.unknown ||
        authController.isLoading) {
      return null;
    }

    // If user is authenticated, redirect to home
    if (authController.isAuthenticated) {
      return const RouteSettings(name: '/home');
    }

    return null; // Allow access to the route (for unauthenticated users)
  }
}
