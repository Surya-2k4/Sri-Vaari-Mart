import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ToastUtils {
  static void showSuccess(BuildContext context, String message) {
    _showToast(
      context,
      message,
      backgroundColor: AppColors.primaryBlack,
      icon: Icons.check_circle_outline,
      iconColor: AppColors.successGreen,
    );
  }

  static void showError(BuildContext context, String message) {
    // Clean up exception message
    String cleanMessage = message;
    if (message.contains(': ')) {
      cleanMessage = message.split(': ').last;
    }

    _showToast(
      context,
      cleanMessage,
      backgroundColor: AppColors.primaryBlack,
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.errorRed,
    );
  }

  static void _showToast(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Clear existing snackbars
    scaffoldMessenger.removeCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
