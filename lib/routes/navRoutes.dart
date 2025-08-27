import 'package:flutter/material.dart';

// Screens
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/sign_in_page.dart';
import '../screens/otp_verification_page.dart';
import '../screens/auth_choice_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/home_page.dart';
import '../screens/location_selection_screen.dart';

// Sprint 2 extras
import '../screens/booking_screen.dart';
import '../screens/my_deliveries_screen.dart';

class NavRoutes {
  // Classic names
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String signIn = '/signIn';
  static const String otpVerification = '/otpVerification';
  static const String authChoice = '/authChoice';
  static const String profileSetup = '/profileSetup';
  static const String homePage = '/homePage';
  static const String locationSelection = '/locationSelection';

  // New (Sprint 2)
  static const String book = '/book';
  static const String myDeliveries = '/my-deliveries';

  static final Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    signIn: (_) => const SignInPage(),
    otpVerification: (_) => const OtpVerificationPage(),
    authChoice: (_) => const AuthChoiceScreen(),
    profileSetup: (context) {
      final String? phoneNumber =
          ModalRoute.of(context)?.settings.arguments as String?;
      if (phoneNumber == null) return const SignInPage();
      return ProfileSetupScreen(phoneNumber: phoneNumber);
    },
    homePage: (_) => const HomePage(),
    locationSelection: (_) => const LocationSelectionScreen(),

    // Sprint 2 extras
    book: (_) => const BookingScreen(),
    myDeliveries: (_) => const MyDeliveriesScreen(),
  };
}
