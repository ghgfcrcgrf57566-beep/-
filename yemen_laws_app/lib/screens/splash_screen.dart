import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import 'root_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2400), _openHome);
  }

  void _openHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RootShell()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0C0E10),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0F11),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final imageWidth = (width * 0.76).clamp(230.0, 390.0);
              final imageHeight = (height * 0.34).clamp(230.0, 350.0);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    ClipRect(
                      child: SizedBox(
                        width: imageWidth,
                        height: imageHeight,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            width: imageWidth,
                            height: imageWidth,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      AppConstants.appNameAr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFE2BA70),
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 11,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      AppConstants.appNameEn,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD8C69D),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 170,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: const LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: Color(0x332F2F2F),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.antiqueBronze,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 3),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          AppConstants.contactShortName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFD8D1C3),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${AppConstants.contactTitleShort} • ${AppConstants.contactPhone}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFC8C0B1),
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '© حقوق الطبع محفوظة 2026',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFAAA497),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
