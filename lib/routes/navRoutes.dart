import 'package:flutter/material.dart';

// Auth/onboarding screens
import 'package:cargomate_v3/screens/signup_screen.dart';
import 'package:cargomate_v3/screens/splash_screen.dart';
import 'package:cargomate_v3/screens/onboarding_screen.dart';
import 'package:cargomate_v3/screens/sign_in_page.dart';
import 'package:cargomate_v3/screens/otp_verification_page.dart';
import 'package:cargomate_v3/screens/auth_choice_screen.dart';

// Home screens
import 'package:cargomate_v3/screens/home_page.dart';
import 'package:cargomate_v3/screens/driver_home_page.dart';

// Sprint 2
import 'package:cargomate_v3/screens/booking_screen.dart';
import 'package:cargomate_v3/screens/my_deliveries_screen.dart';
import 'package:cargomate_v3/screens/delivery_details_screen.dart';

class NavRoutes {
  // Authentication & Onboarding
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String signIn = '/signIn';
  static const String otpVerification = '/otpVerification';
  static const String authChoice = '/authChoice';
  static const String signUp = '/signUp'; // ✅ New sign-up route

  // Role-based home routes
  static const String homePage = '/homePage'; // Customer
  static const String driverHome = '/driverHome'; // Driver

  // Feature routes (Sprint 2)
  static const String book = '/book';
  static const String myDeliveries = '/myDeliveries';
  static const String deliveryDetails = '/deliveryDetails';

  /// Centralized routes map
  static final Map<String, WidgetBuilder> routes = {
    // Authentication flow
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    signIn: (_) => const SignInPage(),
    otpVerification: (_) => const OtpVerificationPage(),
    authChoice: (_) => const AuthChoiceScreen(),
    signUp: (_) => const SignUpScreen(), // ✅ Using SignUpScreen now
    // Role-based navigation
    homePage: (_) => const HomePage(), // Customer homepage
    driverHome: (_) => const DriverHomePage(), // Driver homepage
    // Sprint 2 Features
    book: (_) => const BookingScreen(),
    myDeliveries: (_) => const MyDeliveriesScreen(),
    deliveryDetails: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        return DeliveryDetailsScreen(delivery: args);
      }
      return const Scaffold(body: Center(child: Text('No delivery provided')));
    },
  };

  /// Role-based navigation helper
  static void navigateToHome(BuildContext context, String role) {
    final String targetRoute = role.toLowerCase() == 'driver'
        ? driverHome
        : homePage;

    Navigator.pushNamedAndRemoveUntil(context, targetRoute, (route) => false);
  }
}
