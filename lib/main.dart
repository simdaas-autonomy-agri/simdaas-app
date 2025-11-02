import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
// role selection now uses the unified three-button dashboard
import 'features/plot_mapping/presentation/screens/plot_list_screen.dart';
import 'features/plot_mapping/presentation/screens/map_screen.dart';
import 'features/job_planner/presentation/screens/job_planner_screen.dart';
import 'features/job_planner/presentation/screens/create_job_screen.dart';
import 'features/home/presentation/screens/admin_dashboard_screen.dart';
import 'features/home/presentation/screens/three_button_dashboard_screen.dart';
import 'features/job_planner/presentation/screens/job_supervisor_dashboard_screen.dart';
import 'features/data_monitoring/presentation/screens/monitoring_screen.dart';
import 'features/equipments/presentation/screens/equipment_list_screen.dart';
import 'features/equipments/presentation/screens/equipment_category_screen.dart';
import 'features/equipments/presentation/screens/create_control_unit_screen.dart';
import 'features/equipments/presentation/screens/create_tractor_screen.dart';
import 'features/equipments/presentation/screens/create_sprayer_screen.dart';
import 'features/home/presentation/screens/technician_dashboard_screen.dart';
import 'features/home/presentation/screens/job_reports_screen.dart';
import 'features/home/presentation/screens/settings_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/verify_email_screen.dart';
// temp
import 'temp_features/control_centres_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Sprayer',
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/role_select': (ctx) => const ThreeButtonDashboardScreen(),
        '/plots': (ctx) => const PlotListScreen(),
        // '/dashboard': (ctx) => const ThreeButtonDashboardScreen(),
        '/dashboard': (ctx) => const TempDashboard(),
        '/admin_dashboard': (ctx) => const AdminDashboardScreen(),
        '/job_supervisor_dashboard': (ctx) =>
            const JobSupervisorDashboardScreen(),
        '/technician_dashboard': (ctx) => const TechnicianDashboardScreen(),
        '/job_reports': (ctx) => const JobReportsScreen(),
        '/settings': (ctx) => const SettingsScreen(),
        '/map': (ctx) => const MapScreen(),
        '/jobs': (ctx) => const JobPlannerScreen(),
        '/create_job': (ctx) => const CreateJobScreen(),
        '/monitoring': (ctx) => const MonitoringScreen(),
        '/equipments': (ctx) => const EquipmentListScreen(),
        '/equipment_categories': (ctx) => const EquipmentCategoryScreen(),
        '/create_control_unit': (ctx) => const CreateControlUnitScreen(),
        '/create_tractor': (ctx) => const CreateTractorScreen(),
        '/create_sprayer': (ctx) => const CreateSprayerScreen(),
        '/register': (ctx) => const RegisterScreen(),
        '/verify-email': (ctx) => const VerifyEmailScreen(),
      },
    );
  }
}
