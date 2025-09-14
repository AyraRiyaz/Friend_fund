import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
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
          page: () => const LoginPage(),
          middlewares: [GuestMiddleware()], // Block access when authenticated
        ),
        GetPage(
          name: '/register',
          page: () => const RegisterPage(),
          middlewares: [GuestMiddleware()], // Block access when authenticated
        ),

        // App Routes (require authentication)
        GetPage(
          name: '/home',
          page: () => const HomePage(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/my-campaigns',
          page: () => const MyCampaignsPage(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/add-campaign',
          page: () => const AddCampaignPage(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/campaign-details',
          page: () => const CampaignDetailsPage(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/my-contributions',
          page: () => const MyContributionsPage(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/profile',
          page: () => const ProfilePage(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/help',
          page: () => const HelpPage(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/about',
          page: () => const AboutPage(),
          middlewares: [AuthMiddleware()],
        ),
      ],
      unknownRoute: GetPage(
        name: '/notfound',
        page: () => const Scaffold(body: Center(child: Text('Page not found'))),
      ),
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

    // If user is authenticated, redirect to home
    if (authController.isAuthenticated) {
      return const RouteSettings(name: '/home');
    }

    return null; // Allow access to the route (for unauthenticated users)
  }
}
