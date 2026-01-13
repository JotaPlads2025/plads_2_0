import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;

  const NeonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.neonGreen;
    final isDisabled = onPressed == null;

    return Container(
      decoration: BoxDecoration(
        boxShadow: isDisabled ? [] : [
          BoxShadow(
            color: themeColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? Colors.grey.shade800 : themeColor,
          foregroundColor: isDisabled ? Colors.grey.shade500 : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0, // Handled by Container for custom glow
        ),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class NeonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final Color? accentColor;
  final TextInputType? keyboardType;
  final bool readOnly; // Added

  const NeonTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.accentColor,
    this.keyboardType,
    this.readOnly = false, // Added default false
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.neonGreen;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly, // Pass to TextField
      style: const TextStyle(color: Colors.white),
      cursorColor: color,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
    );
  }
}
