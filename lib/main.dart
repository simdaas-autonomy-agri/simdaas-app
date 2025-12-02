import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/auth_gate.dart';
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
import 'features/auth/presentation/screens/profile_screen.dart';
import 'features/auth/presentation/screens/forgot_password_email_screen.dart';
import 'features/auth/presentation/screens/forgot_password_confirm_screen.dart';
// temp
import 'temp_features/control_centres_dashboard.dart';
import 'core/services/telemetry_service.dart';
import 'debug/telemetry_debug_screen.dart';
import 'core/services/auth_service.dart';
import 'core/utils/mac_utils.dart';
import 'features/equipments/presentation/providers/equipment_providers.dart'
    as eq_provs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

// Application-level navigator key so we can reliably show dialogs from
// places where the local BuildContext might not be attached to the root
// navigator (for example inside early bootstrap logic). Using this key
// makes the exit confirmation dialog robust.
final GlobalKey<NavigatorState> appNavKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavKey,
      title: 'Smart Sprayer',
      theme: AppTheme.lightTheme,
      // Use AuthGate as home so we can wait for persisted tokens to load
      // Wrap with WillPopScope to confirm app exit when at the root.
      home: WillPopScope(
        onWillPop: () async {
          // Use the app-level navigator key to check stack state so we're
          // robust even if the local `context` is not attached to the root
          // navigator.
          final nav = appNavKey.currentState;
          if (nav != null && nav.canPop()) return true;

          // Otherwise ask for confirmation. Use the app-level context so the
          // dialog is shown on the root navigator.
          final doExit = await showDialog<bool>(
                context: appNavKey.currentContext ?? context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Exit app?'),
                  content: const Text(
                      'Exiting will lose your ongoing work. Are you sure you want to exit the application?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Exit')),
                  ],
                ),
              ) ??
              false;
          if (doExit) {
            try {
              SystemNavigator.pop();
            } catch (_) {}
          }
          // Prevent default pop; we've either exited or cancelled.
          return false;
        },
        child: TelemetryBootstrapper(child: const AuthGate()),
      ),
      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/role_select': (ctx) => const ThreeButtonDashboardScreen(),
        '/plots': (ctx) => const PlotListScreen(),
        // '/dashboard': (ctx) => const ThreeButtonDashboardScreen(),
        '/dashboard': (ctx) => const TempDashboard(),
        '/debug/telemetry': (ctx) => const TelemetryDebugScreen(),
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
        '/forgot-password': (ctx) => const ForgotPasswordEmailScreen(),
        '/forgot-password-confirm': (ctx) =>
            const ForgotPasswordConfirmScreen(),
        '/profile': (ctx) => const ProfileScreen(),
      },
    );
  }
}

class TelemetryBootstrapper extends ConsumerWidget {
  final Widget child;
  const TelemetryBootstrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If user already present at build time, kick off a fetch asynchronously.
    final currentUserId = ref.read(authServiceProvider).currentUserId ?? '';
    if (currentUserId.isNotEmpty) {
      Future.microtask(() => _fetchAndSubscribe(ref, currentUserId));
    }

    // Listen for changes to auth state and react when a user logs in/out.
    ref.listen<AuthService>(authServiceProvider, (previous, next) {
      final userId = next.currentUserId ?? '';
      if (userId.isNotEmpty) {
        debugPrint('TelemetryBootstrapper.listen: userId present: $userId');
        // Set up a continuous listener on the controlUnitsProvider for this user
        // so we automatically subscribe/unsubscribe when control units change.
        final controlProv = eq_provs.controlUnitsProvider(userId);
        // Use fireImmediately so we react to the current cached/loaded state.
        ref.listen<AsyncValue<List<dynamic>>>(controlProv, (prev, nextCu) {
          try {
            nextCu.when(
              data: (items) {
                debugPrint(
                    'TelemetryBootstrapper: controlUnits changed: ${items.length}');
                final ids = <String>[];
                for (final cu in items) {
                  try {
                    final dynCu = cu as dynamic;
                    String id = '';
                    try {
                      final maybe = dynCu['mac'] ??
                          dynCu['mac_address'] ??
                          dynCu['controlUnitId'] ??
                          dynCu['control_unit_id'] ??
                          dynCu['id'];
                      if (maybe != null) id = maybe.toString();
                    } catch (_) {
                      try {
                        id = (dynCu.macAddress ??
                                    dynCu.controlUnitId ??
                                    dynCu.id)
                                ?.toString() ??
                            '';
                      } catch (_) {
                        id = '';
                      }
                    }
                    if (id.isNotEmpty) ids.add(id);
                  } catch (e) {
                    debugPrint(
                        'TelemetryBootstrapper: error extracting id from cu: $e');
                  }
                }
                final svc = ref.read(telemetryServiceProvider);
                svc.subscribeToDevices(ids);
              },
              loading: () {
                debugPrint(
                    'TelemetryBootstrapper: controlUnits loading for $userId');
              },
              error: (err, st) {
                debugPrint(
                    'TelemetryBootstrapper: controlUnits error for $userId: $err');
              },
            );
          } catch (e) {
            debugPrint(
                'TelemetryBootstrapper: controlUnits listener exception: $e');
          }
        });
      } else {
        debugPrint(
            'TelemetryBootstrapper.listen: user signed out or no userId');
        try {
          final svc = ref.read(telemetryServiceProvider);
          svc.subscribeToDevices(<String>[]);
        } catch (_) {}
      }
    });

    return child;
  }

  static Future<void> _fetchAndSubscribe(WidgetRef ref, String userId) async {
    try {
      debugPrint('TelemetryBootstrapper: fetching control units for $userId');
      final svc = ref.read(telemetryServiceProvider);
      final items =
          await ref.read(eq_provs.controlUnitsProvider(userId).future);
      debugPrint(
          'TelemetryBootstrapper: controlUnits fetched: ${items.length}');
      final ids = <String>[];
      for (final cu in items) {
        try {
          final dynCu = cu as dynamic;
          String id = '';
          try {
            final maybe = dynCu['mac'] ??
                dynCu['mac_address'] ??
                dynCu['controlUnitId'] ??
                dynCu['control_unit_id'] ??
                dynCu['id'];
            if (maybe != null) id = maybe.toString();
          } catch (_) {
            try {
              id = (dynCu.macAddress ?? dynCu.controlUnitId ?? dynCu.id)
                      ?.toString() ??
                  '';
            } catch (_) {
              id = '';
            }
          }
          if (id.isNotEmpty) ids.add(id);
        } catch (e) {
          debugPrint('TelemetryBootstrapper: error extracting id from cu: $e');
        }
      }
      debugPrint('TelemetryBootstrapper: subscribing to devices: $ids');
      svc.subscribeToDevices(ids);
    } catch (e, st) {
      debugPrint('TelemetryBootstrapper: failed fetching control units: $e');
      debugPrint('TelemetryBootstrapper stack: ${safeStringify(st)}');
    }
  }
}
