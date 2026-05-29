import 'package:flutter/material.dart';

enum LogoSize { sm, lg }
enum LogoVariant { light, dark }

class Back2ULogo extends StatelessWidget {
  final LogoSize size;
  final LogoVariant variant;
  // 🟢 FIXED: Kept the parameter here so main.dart and auth_screen.dart compile perfectly
  final bool showSlogan; 

  const Back2ULogo({
    super.key,
    this.size = LogoSize.lg,
    this.variant = LogoVariant.dark,
    this.showSlogan = true, // 🟢 FIXED: Default value prevents parameter errors
  });

  @override
  Widget build(BuildContext context) {
    const tealTextColor = Color(0xFF0D9488);
    
    // Clean, large sizing scale
    final scale = size == LogoSize.lg ? 2.10 : 0.55;

    return Center(
      child: SizedBox(
        width: 160 * scale,
        height: 130 * scale,
        child: Image.asset(
          'assets/images/back2u_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.domain_verification, 
              size: 100 * scale, 
              color: tealTextColor,
            );
          },
        ),
      ),
    );
  }
}
