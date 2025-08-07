import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'routes/navigation_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize localization data
  await initializeDateFormatting('en_US', null);
  
  // Initialize theme service
  final themeService = ThemeService();
  await themeService.loadTheme();
  
  runApp(MedicationReminderApp(themeService: themeService));
}

class MedicationReminderApp extends StatelessWidget {
  final ThemeService themeService;
  
  const MedicationReminderApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: themeService,
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Medication Reminder',
            navigatorKey: NavigationHelper.navigatorKey,
            theme: ThemeService.lightTheme,
            darkTheme: ThemeService.darkTheme,
            themeMode: themeService.themeMode,
            initialRoute: AppRoutes.home,
            onGenerateRoute: RouteGenerator.generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
