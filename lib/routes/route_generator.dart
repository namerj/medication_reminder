import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/add_medication_screen.dart';
import '../screens/medication_detail_screen.dart';
import '../screens/medication_check_screen.dart';
import '../screens/medication_record_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/terms_of_service_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../models/medication.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      
      case AppRoutes.medicationCheck:
        return MaterialPageRoute(
          builder: (_) => const MedicationCheckScreen(),
          settings: settings,
        );
      
      case AppRoutes.medicationRecord:
        return MaterialPageRoute(
          builder: (_) => const MedicationRecordScreen(),
          settings: settings,
        );
      
      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
      
      case AppRoutes.addMedication:
        return MaterialPageRoute(
          builder: (_) => const AddMedicationScreen(),
          settings: settings,
        );
      
      case AppRoutes.editMedication:
        final medication = settings.arguments as Medication?;
        return MaterialPageRoute(
          builder: (_) => AddMedicationScreen(
            editingMedication: medication,
          ),
          settings: settings,
        );
      
      case AppRoutes.medicationDetail:
        final medication = settings.arguments as Medication?;
        if (medication == null) {
          return _errorRoute('Medication information is required to view details');
        }
        return MaterialPageRoute(
          builder: (_) => MedicationDetailScreen(medication: medication),
          settings: settings,
        );
      
      case AppRoutes.termsOfService:
        return MaterialPageRoute(
          builder: (_) => const TermsOfServiceScreen(),
          settings: settings,
        );
      
      case AppRoutes.privacyPolicy:
        return MaterialPageRoute(
          builder: (_) => const PrivacyPolicyScreen(),
          settings: settings,
        );
      
      default:
        return _errorRoute('Page not found: ${settings.name}');
    }
  }
  
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.home,
                  (route) => false,
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}