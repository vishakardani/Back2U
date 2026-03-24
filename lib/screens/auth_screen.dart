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
  bool _obscurePassword = true; // 👈 added

  late final TextEditingController universityIdController;
  late final TextEditingController passwordController;
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();

    universityIdController = TextEditingController(text: '21DCS001');
    passwordController = TextEditingController(text: 'Test@123');

    if (authController.token.value.isNotEmpty) {
      Future.microtask(() => Get.off(() => const MainScaffold()));
    }
  }

  void _updateDefaultCredentials() {
    if (isAdminMode) {
      universityIdController.text = 'admin@unifound';
      passwordController.text = 'Admin@Charusat';
    } else {
      universityIdController.text = '21DCS001';
      passwordController.text = 'Test@123';
    }
  }

  void _handleLogin() async {
    if (universityIdController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        isAdminMode ? 'Please enter admin username' : 'Please enter university ID',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    bool success;

    if (isAdminMode) {
      success = await authController.adminLogin(
        username: universityIdController.text.trim(),
        password: passwordController.text,
      );
    } else {
      success = await authController.login(
        universityId: universityIdController.text.trim(),
        password: passwordController.text,
      );
    }

    if (success) {
      Get.off(() => const MainScaffold());
    }
  }

  void _handleRegister() async {
    if (universityIdController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter university ID',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (firstNameController.text.trim().isEmpty || lastNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your full name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (emailController.text.trim().isEmpty || !GetUtils.isEmail(emailController.text.trim())) {
      Get.snackbar(
        'Error',
        'Please enter a valid email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (phoneController.text.trim().isEmpty || phoneController.text.trim().length < 10) {
      Get.snackbar(
        'Error',
        'Please enter a valid phone number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (passwordController.text.length < 6) {
      Get.snackbar(
        'Error',
        'Password must be at least 6 characters',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final success = await authController.register(
      universityId: universityIdController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      phone: phoneController.text.trim(),
    );

    if (success) {
      Get.off(() => const MainScaffold());
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = isAdminMode ? const Color(0xFFE11D48) : const Color(0xFF0D9488);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
          child: Column(
            children: [
              const Back2ULogo(showSlogan: true),
              const SizedBox(height: 40),

              // Role Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _roleButton(
                    "Student",
                    !isAdminMode,
                    Icons.person_outline,
                        () {
                      setState(() {
                        isAdminMode = false;
                        isRegistering = false;
                        _obscurePassword = true; // 👈 reset on role switch
                        _clearFields();
                        _updateDefaultCredentials();
                      });
                    },
                  ),
                  const SizedBox(width: 40),
                  _roleButton(
                    "Admin",
                    isAdminMode,
                    Icons.shield_outlined,
                        () {
                      setState(() {
                        isAdminMode = true;
                        isRegistering = false;
                        _obscurePassword = true; // 👈 reset on role switch
                        _clearFields();
                        _updateDefaultCredentials();
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Login/Register Toggle (Only for Students)
              if (!isAdminMode)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _toggleButton(
                        "Login",
                        !isRegistering,
                            () {
                          setState(() {
                            isRegistering = false;
                            _obscurePassword = true; // 👈 reset on toggle
                            _clearFields();
                            _updateDefaultCredentials();
                          });
                        },
                      ),
                      _toggleButton(
                        "Register",
                        isRegistering,
                            () {
                          setState(() {
                            isRegistering = true;
                            _obscurePassword = true; // 👈 reset on toggle
                            _clearFields();
                          });
                        },
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // Form Fields
              _buildField(
                Icons.badge_outlined,
                isAdminMode ? "Admin Username" : "University ID",
                universityIdController,
              ),

              // Registration Fields (Only for Students)
              if (isRegistering && !isAdminMode) ...[
                const SizedBox(height: 16),
                _buildField(
                  Icons.person_outline,
                  "First Name",
                  firstNameController,
                ),
                const SizedBox(height: 16),
                _buildField(
                  Icons.person_outline,
                  "Last Name",
                  lastNameController,
                ),
                const SizedBox(height: 16),
                _buildField(
                  Icons.email_outlined,
                  "Email",
                  emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildField(
                  Icons.phone_outlined,
                  "Phone Number",
                  phoneController,
                  keyboardType: TextInputType.phone,
                ),
              ],

              const SizedBox(height: 16),

              // 👇 Password field with eye toggle
              _buildField(
                Icons.lock_outline,
                "Password",
                passwordController,
                obscure: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Submit Button
              Obx(() => SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: authController.isLoading.value
                      ? null
                      : (isRegistering && !isAdminMode
                      ? _handleRegister
                      : _handleLogin),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAdminMode
                        ? const Color(0xFFE11D48)
                        : const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: themeColor.withOpacity(0.3),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: authController.isLoading.value
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : Text(
                    isRegistering ? "CREATE ACCOUNT" : "ACCESS DASHBOARD",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      fontSize: 14,
                    ),
                  ),
                ),
              )),

              // Demo Credentials Hint
              if (!isRegistering) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Demo Credentials',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isAdminMode) ...[
                        _demoCredential('Username:', 'admin@unifound'),
                        _demoCredential('Password:', 'Admin@Charusat'),
                      ] else ...[
                        _demoCredential('Student ID:', '21DCS001'),
                        _demoCredential('Password:', 'Test@123'),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoCredential(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
            decoration: BoxDecoration(
              color: active ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: active ? color : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: active ? color : Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: active ? 24 : 0,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
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
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                color: active ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      IconData icon,
      String hint,
      TextEditingController controller, {
        bool obscure = false,
        TextInputType keyboardType = TextInputType.text,
        Widget? suffixIcon, // 👈 added
      }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        suffixIcon: suffixIcon, // 👈 added
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isAdminMode ? const Color(0xFFE11D48) : const Color(0xFF0D9488),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  void _clearFields() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    phoneController.clear();
  }

  @override
  void dispose() {
    universityIdController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
