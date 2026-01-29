import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/admin/dashboard_screen.dart';
import 'presentation/screens/tenant/tenant_dashboard_screen.dart';
import 'presentation/screens/admin/room_management_screen.dart';
import 'presentation/screens/admin/tenant_management_screen.dart';
import 'presentation/screens/admin/financial_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kost Sejahtera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin-dashboard': (context) => const DashboardAdminScreen(),
        '/tenant-dashboard': (context) => const TenantDashboardScreen(),
        '/rooms': (context) => const RoomManagementScreen(),
        '/tenants': (context) => const TenantManagementScreen(),
        '/financial': (context) => const FinancialScreen(),
      },
    );
  }
}
