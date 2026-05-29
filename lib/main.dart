import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'services/storage_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/home_controller.dart'; 
import 'widgets/logo.dart'; 

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/post_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    Get.put(AuthController());
    Get.put(HomeController());
    
    return GetMaterialApp(
      title: 'Back2U',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      // 🟢 CHANGE: We use a wrapper widget instead of an Obx in the 'home' property.
      // This allows for safer navigation transitions during logout.
      home: const AuthWrapper(),
    );
  }

  // Extracted theme for cleaner code
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6F8FB),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D9488),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF6F8FB),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0, backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
        ),
      ),
    );
  }
}

// 🟢 NEW: Wrapper to manage auth state without triggering immediate UI reconstruction crashes
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  
  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    
    return Obx(() {
      if (authController.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))));
      }
      return authController.token.value.isNotEmpty ? const MainScaffold() : const AuthScreen();
    });
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int currentIndex = 0;
  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [HomeScreen(), PostScreen(), const ProfileScreen()];
  }

  void _onNavTap(int index) {
    if (currentIndex == index) return;
    setState(() { currentIndex = index; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Back2ULogo(size: LogoSize.sm),
        backgroundColor: const Color(0xFFF6F8FB),
      ),
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: currentIndex, onTap: _onNavTap),
    );
  }
}
