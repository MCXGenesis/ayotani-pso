import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';

class CircleSocialButton extends StatelessWidget {
  CircleSocialButton({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: CircleBorder(),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.cardBg,
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: Offset(0, 6),
              color: Colors.black.withOpacity(0.08),
            )
          ],
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Center(child: child),
      ),
    );
  }
}
