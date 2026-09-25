import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import 'root_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RootShell()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              // ⚖️ ميزان العدالة بتصميم بسيط وأنيق باللون النحاسي/الذهبي
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.antiqueBronze.withOpacity(0.5), width: 1.2),
                ),
                child: const Icon(Icons.balance, size: 56, color: AppColors.softGold),
              ),
              const SizedBox(height: 26),
              const Text(
                AppConstants.appNameAr,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.softGold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppConstants.appNameEn,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkTextSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(flex: 2),
              // شريط تحميل نحاسي عتيق
              SizedBox(
                width: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: AppColors.darkSurfaceAlt,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.antiqueBronze),
                  ),
                ),
              ),
              const Spacer(flex: 3),
              Text(
                AppConstants.contactShortName,
                style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              Text(
                '${AppConstants.contactTitleShort} • ${AppConstants.contactPhone}',
                style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: 10),
              Text(
                AppConstants.copyrightText,
                style: TextStyle(fontSize: 10.5, color: AppColors.darkTextSecondary.withOpacity(0.7)),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
