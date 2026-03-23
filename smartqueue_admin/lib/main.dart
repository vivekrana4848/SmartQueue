import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app/admin_theme.dart';
import 'app/admin_router.dart';
import 'providers/admin_providers.dart';
import 'analytics/analytics_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SmartQueueAdminApp());
}

class SmartQueueAdminApp extends StatelessWidget {
  const SmartQueueAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => SectorAdminProvider()),
        ChangeNotifierProvider(create: (_) => BranchAdminProvider()),
        ChangeNotifierProvider(create: (_) => ServiceAdminProvider()),
        ChangeNotifierProvider(create: (_) => CounterAdminProvider()),
        ChangeNotifierProvider(create: (_) => QueueAdminProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => EnterpriseAnalyticsProvider()..init()),
        ChangeNotifierProvider(create: (_) => AdminUserProvider()),
        ChangeNotifierProvider(create: (_) => DashboardStatsProvider()),
      ],
      child: Builder(builder: (context) {
        final router = AdminRouter.router(context);
        return MaterialApp.router(
          title: 'SmartQueue Admin',
          theme: AdminTheme.theme,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      }),
    );
  }
}
