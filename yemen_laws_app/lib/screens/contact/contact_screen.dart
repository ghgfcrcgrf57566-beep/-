import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التواصل والاستشارات القانونية')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.surfaceAlt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.divider),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: context.accent.withOpacity(0.15),
                  child: Icon(Icons.person_outline, size: 36, color: context.accent),
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.contactName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  AppConstants.contactTitleFull,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: context.textSecondary),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.call_outlined, color: context.accent, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        AppConstants.contactPhone,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
