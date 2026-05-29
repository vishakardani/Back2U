import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/logo.dart';
import '../controllers/auth_controller.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final authController = Get.put(AuthController());

  bool isAdminMode = false;
  bool isRegistering = false;
  bool _obscurePassword = true;

  // Controllers
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  final universityIdController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();

  static const String CHARUSAT_DOMAIN = '@charusat.edu.in';

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();

    if (authController.token.value.isNotEmpty) {
      Future.microtask(() => Get.offAll(() => const MainScaffold()));
    }
  }

  bool _isValidEmail(String email) {
    if (!GetUtils.isEmail(email.trim())) return false;
    if (!isAdminMode) {
      return email.trim().toLowerCase().endsWith(CHARUSAT_DOMAIN);
    }
    return true;
  }

  void _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      Get.snackbar('Error', 'Please enter your email',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (!_isValidEmail(email)) {
      Get.snackbar('Error', 'Please use your official $CHARUSAT_DOMAIN email',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (password.isEmpty) {
      Get.snackbar('Error', 'Please enter your password',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    bool success;
    if (isAdminMode) {
      success = await authController.adminLogin(
        username: email,
        password: password,
      );
    } else {
      success = await authController.login(
        email: email,
        password: password,
      );
    }

    if (success) {
      Get.offAll(() => const MainScaffold());
    }
  }

  void _handleGoogleSignIn() async {
    final success = await authController.googleSignIn();
    if (success) {
      Get.offAll(() => const MainScaffold());
    }
  }

  void _handleRegister() async {
    if (universityIdController.text.trim().isEmpty) {
      Get.snackbar('Error', 'University ID is required',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final email = emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      Get.snackbar('Error', 'Valid $CHARUSAT_DOMAIN email is required',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (firstNameController.text.trim().isEmpty || lastNameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Full name is required',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (phoneController.text.trim().length < 10) {
      Get.snackbar('Error', 'Enter a valid 10-digit phone number',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (passwordController.text.length < 6) {
      Get.snackbar('Error', 'Password must be at least 6 characters',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final success = await authController.register(
      universityId: universityIdController.text.trim(),
      email: email,
      password: passwordController.text,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      phone: phoneController.text.trim(),
    );

    if (success) {
      setState(() => isRegistering = false);
      passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(32, 24, 32, bottomInset + 20),
          child: Column(
            children: [
              const Back2ULogo(
                size: LogoSize.lg,
                variant: LogoVariant.dark,
                showSlogan: true,
              ),
              const SizedBox(height: 32),

              // Role Switcher
              Row(
                // 🟢 FIXED: Fixed the structural alignment parameter syntax error here
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _roleButton("Student", !isAdminMode, Icons.person_outline, () {
                    setState(() {
                      isAdminMode = false;
                      isRegistering = false;
                      _clearFields();
                    });
                  }),
                  const SizedBox(width: 40),
                  _roleButton("Admin", isAdminMode, Icons.shield_outlined, () {
                    setState(() {
                      isAdminMode = true;
                      isRegistering = false;
                      _clearFields();
                    });
                  }),
                ],
              ),

              const SizedBox(height: 24),

              if (!isAdminMode)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      _toggleButton("Login", !isRegistering, () {
                        setState(() => isRegistering = false);
                      }),
                      _toggleButton("Register", isRegistering, () {
                        setState(() => isRegistering = true);
                      }),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              _buildField(
                Icons.email_outlined,
                isAdminMode ? "Admin Username" : "University Email",
                emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              if (isRegistering && !isAdminMode) ...[
                const SizedBox(height: 12),
                _buildField(Icons.badge_outlined, "University ID", universityIdController),
                const SizedBox(height: 12),
                _buildField(Icons.person_outline, "First Name", firstNameController),
                const SizedBox(height: 12),
                _buildField(Icons.person_outline, "Last Name", lastNameController),
                const SizedBox(height: 12),
                _buildField(Icons.phone_outlined, "Phone Number", phoneController, keyboardType: TextInputType.phone),
              ],

              const SizedBox(height: 12),

              _buildField(
                Icons.lock_outline,
                "Password",
                passwordController,
                obscure: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 32),

              Obx(() => SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: authController.isLoading.value ? null : (isRegistering ? _handleRegister : _handleLogin),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAdminMode ? const Color(0xFFE11D48) : const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  child: authController.isLoading.value
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isRegistering ? "CREATE ACCOUNT" : "LOGIN", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ),
              )),

              if (!isAdminMode && !isRegistering) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12))),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 20),
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: authController.isLoading.value ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    icon: const Icon(Icons.g_mobiledata, size: 30, color: Color(0xFF4285F4)),
                    label: const Text('Sign in with Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleButton(String label, bool active, IconData icon, VoidCallback onTap) {
    final color = isAdminMode ? const Color(0xFFE11D48) : const Color(0xFF0D9488);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: active ? color.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: active ? color : Colors.grey, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? color : Colors.grey, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.w600, color: active ? Colors.black : Colors.grey[600]))),
        ),
      ),
    );
  }

  Widget _buildField(IconData icon, String hint, TextEditingController controller, {bool obscure = false, TextInputType keyboardType = TextInputType.text, Widget? suffixIcon}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        suffixIcon: suffixIcon,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isAdminMode ? const Color(0xFFE11D48) : const Color(0xFF0D9488), width: 1.5)),
      ),
    );
  }

  void _clearFields() {
    emailController.clear();
    passwordController.clear();
    universityIdController.clear();
    firstNameController.clear();
    lastNameController.clear();
    phoneController.clear();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    universityIdController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
