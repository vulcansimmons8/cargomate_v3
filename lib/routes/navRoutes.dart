import 'package:flutter/material.dart';

// Core auth/onboarding screens
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/sign_in_page.dart';
import '../screens/otp_verification_page.dart';
import '../screens/auth_choice_screen.dart';
import '../screens/profile_setup_screen.dart';

// Home screens
import '../screens/home_page.dart';
import '../screens/home_router.dart';
import '../screens/driver_home_page.dart';

// Sprint 2
import '../screens/booking_screen.dart';
import '../screens/my_deliveries_screen.dart';
import '../screens/delivery_details_screen.dart';

// If you are still using a manual location picker screen, keep this.
// Otherwise, comment/remove and rely on MapPickerScreen directly.
// import '../screens/location_selection_screen.dart';

class NavRoutes {
  // Classic/auth flow
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String signIn = '/signIn';
  static const String otpVerification = '/otpVerification';
  static const String authChoice = '/authChoice';
  static const String profileSetup = '/profileSetup';

  // Role-based routing
  static const String homeRouter = '/homeRouter';
  static const String homePage = '/homePage'; // customer
  static const String driverHome = '/driverHome';

  // Sprint 2 extras
  static const String book = '/book';
  static const String myDeliveries = '/my-deliveries';
  static const String deliveryDetails = '/delivery-details';

  // Optional if you’re still using LocationSelectionScreen
  // static const String locationSelection = '/locationSelection';

  static final Map<String, WidgetBuilder> routes = {
    // Auth flow
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

    // Role-based
    homeRouter: (_) => const HomeRouter(),
    homePage: (_) => const HomePage(), // customer
    driverHome: (_) => const DriverHomePage(),

    // Sprint 2
    book: (_) => const BookingScreen(),
    myDeliveries: (_) => const MyDeliveriesScreen(),

    deliveryDetails: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        return DeliveryDetailsScreen(delivery: args);
      }
      return const Scaffold(body: Center(child: Text('No delivery provided')));
    },

    // Optional
    // locationSelection: (_) => const LocationSelectionScreen(),
  };
}
