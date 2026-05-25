import 'package:flutter/material.dart';

enum LogoSize { sm, lg }
enum LogoVariant { light, dark }

class Back2ULogo extends StatelessWidget {
  final LogoSize size;
  final LogoVariant variant;
  final bool showSlogan;

  const Back2ULogo({
    super.key,
    this.size = LogoSize.lg,
    this.variant = LogoVariant.dark,
    this.showSlogan = true,
  });

  @override
  Widget build(BuildContext context) {
    final scale = size == LogoSize.lg ? 1.0 : 0.4;

    return SizedBox(
      width: 160 * scale,
      height: 130 * scale,
      child: Image.asset(
        'assets/images/back2u_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
