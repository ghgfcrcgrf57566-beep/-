import 'package:flutter/material.dart';

/// هوية بصرية كلاسيكية ورصينة لموسوعة "قوانين اليمن - Yemen Law":
/// خلفية رمادية فحمية داكنة/أسود مخملي + نص وأيقونات بلون نحاسي عتيق/ذهبي
/// هادئ. **ممنوع استخدام اللون الكحلي (Navy) في أي مكان بالتصميم.**
class AppColors {
  // ---- الوضع الليلي (الهوية الأساسية للتطبيق) ----
  static const Color darkBackground = Color(0xFF121212); // أسود مخملي دافئ
  static const Color darkSurface = Color(0xFF1E1C1A); // رمادي فحمي للبطاقات
  static const Color darkSurfaceAlt = Color(0xFF262320);
  static const Color antiqueBronze = Color(0xFFB08D57); // نحاس عتيق
  static const Color softGold = Color(0xFFD4AF6A); // ذهبي هادئ (تمييز/عناوين)
  static const Color darkTextPrimary = Color(0xFFEDE6DA); // بيج فاتح مريح للعين
  static const Color darkTextSecondary = Color(0xFFB7AFA2);
  static const Color darkDivider = Color(0xFF3A3631);

  // ---- الوضع النهاري (نفس الروح الكلاسيكية، بخلفية فاتحة دافئة) ----
  static const Color lightBackground = Color(0xFFF5F1E8); // بيج ورقي دافئ
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEFE8D8);
  static const Color bronzeOnLight = Color(0xFF8A6A3B); // نحاسي أغمق ليتباين على الفاتح
  static const Color lightTextPrimary = Color(0xFF2A2620);
  static const Color lightTextSecondary = Color(0xFF6B6357);
  static const Color lightDivider = Color(0xFFDDD3BE);

  static const Color success = Color(0xFF5A7D5A);
  static const Color danger = Color(0xFFA84C4C);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.antiqueBronze,
        brightness: Brightness.dark,
        primary: AppColors.antiqueBronze,
        secondary: AppColors.softGold,
        surface: AppColors.darkSurface,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.softGold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.softGold,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.antiqueBronze),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.darkDivider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkDivider, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceAlt,
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.softGold, width: 1.4),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.antiqueBronze,
        linearTrackColor: AppColors.darkSurfaceAlt,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.antiqueBronze,
        foregroundColor: Colors.black,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.softGold),
        trackColor: WidgetStateProperty.all(AppColors.darkSurfaceAlt),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        titleTextStyle: TextStyle(color: AppColors.softGold, fontWeight: FontWeight.w700, fontSize: 17),
        contentTextStyle: TextStyle(color: AppColors.darkTextPrimary, fontSize: 14.5),
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.bronzeOnLight,
        brightness: Brightness.light,
        primary: AppColors.bronzeOnLight,
        secondary: AppColors.antiqueBronze,
        surface: AppColors.lightSurface,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.bronzeOnLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.bronzeOnLight,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.bronzeOnLight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.lightDivider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightDivider, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        hintStyle: const TextStyle(color: AppColors.lightTextSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.bronzeOnLight, width: 1.4),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.bronzeOnLight,
        linearTrackColor: AppColors.lightSurfaceAlt,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.bronzeOnLight,
        foregroundColor: Colors.white,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        titleTextStyle: TextStyle(color: AppColors.bronzeOnLight, fontWeight: FontWeight.w700, fontSize: 17),
        contentTextStyle: TextStyle(color: AppColors.lightTextPrimary, fontSize: 14.5),
      ),
    );
  }
}

/// دوال مساعدة لاستخدام الألوان الصحيحة بحسب الوضع الحالي (ليلي/نهاري)
/// من أي مكان في الشجرة دون تكرار فحص Theme.of(context).brightness يدويًا.
extension AppColorsContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get textPrimary => isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary => isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get accent => isDark ? AppColors.softGold : AppColors.bronzeOnLight;
  Color get surfaceAlt => isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
  Color get divider => isDark ? AppColors.darkDivider : AppColors.lightDivider;
}
