import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';

/// شاشة أنيقة تُعرض للأقسام القابلة للتوسع مستقبلاً (المراجع القانونية،
/// أحكام المحكمة العليا، المذكرات والنماذج) قبل إضافة محتوى حقيقي إليها.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_top_rounded, size: 54, color: context.accent.withOpacity(0.8)),
              const SizedBox(height: 18),
              Text(
                AppConstants.comingSoonMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'هذا القسم قابل للتوسع، وسيتم تزويده بمحتوى حقيقي في تحديثات قادمة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
