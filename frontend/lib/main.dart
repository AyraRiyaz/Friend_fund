import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_strategy/url_strategy.dart';
import 'controllers/auth_controller.dart';
import 'controllers/campaign_controller.dart';
import 'services/appwrite_auth_service.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/my_campaigns_page.dart';
import 'pages/add_campaign_page.dart';
import 'pages/campaign_details_page.dart';
import 'pages/my_contributions_page.dart';
import 'pages/profile_page.dart';
import 'pages/help_page.dart';
import 'pages/about_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure URL strategy for web to remove hash
  if (kIsWeb) {
    setPathUrlStrategy();
  }

  // Initialize GetStorage for token management
  await GetStorage.init();

  // Initialize Appwrite
  AppwriteService.initialize();
  final apiService = ApiService();

  // Initialize Controllers with dependency injection
  Get.put(apiService);
  Get.put(AuthController());
  Get.put(CampaignController());

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
          .lightTheme, // Use light theme for both to maintain white and blue design
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
          page: () => const AuthProtectedPage(child: HomePage()),
        ),
        GetPage(
          name: '/my-campaigns',
          page: () => const AuthProtectedPage(child: MyCampaignsPage()),
        ),
        GetPage(
          name: '/add-campaign',
          page: () => const AuthProtectedPage(child: AddCampaignPage()),
        ),
        GetPage(
          name: '/campaign-details',
          page: () => const AuthProtectedPage(child: CampaignDetailsPage()),
        ),
        GetPage(
          name: '/my-contributions',
          page: () => const AuthProtectedPage(child: MyContributionsPage()),
        ),
        GetPage(
          name: '/profile',
          page: () => const AuthProtectedPage(child: ProfilePage()),
        ),
        GetPage(
          name: '/help',
          page: () => const AuthProtectedPage(child: HelpPage()),
        ),
        GetPage(
          name: '/about',
          page: () => const AuthProtectedPage(child: AboutPage()),
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

  const GuestProtectedPage({Key? key, required this.child}) : super(key: key);

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
                  CircularProgressIndicator(color: Colors.teal),
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

  const AuthProtectedPage({Key? key, required this.child}) : super(key: key);

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
                  CircularProgressIndicator(color: Colors.teal),
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
  const AuthWrapper({Key? key}) : super(key: key);

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
                  CircularProgressIndicator(color: Colors.teal),
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
