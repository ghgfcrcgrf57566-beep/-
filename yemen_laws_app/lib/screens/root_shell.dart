import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/settings_provider.dart';
import 'laws/laws_home_screen.dart';
import 'coming_soon_screen.dart';
import 'favorites/favorites_screen.dart';
import 'feedback/feedback_screen.dart';
import 'contact/contact_screen.dart';

/// الشاشة الرئيسية الجديدة: قائمة أقسام رئيسية بشكل مربعات (Cards)، وفق
/// الهوية الكلاسيكية الرصينة (رمادي فحمي/أسود مخملي + نحاسي/ذهبي هادئ).
class RootShell extends StatelessWidget {
  const RootShell({super.key});

  Future<bool> _confirmExit(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الخروج'),
        content: const Text('هل تريد الخروج من التطبيق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('خروج', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final sections = <_SectionData>[
      _SectionData(
        icon: Icons.balance,
        title: 'القوانين اليمنية',
        subtitle: 'المحتوى الأساسي للتطبيق',
        builder: (_) => const LawsHomeScreen(),
      ),
      _SectionData(
        icon: Icons.menu_book_outlined,
        title: 'المراجع القانونية',
        subtitle: 'كتب، شروحات، أبحاث، رسائل علمية',
        builder: (_) => const ComingSoonScreen(title: 'المراجع القانونية'),
      ),
      _SectionData(
        icon: Icons.account_balance_outlined,
        title: 'أحكام المحكمة العليا',
        subtitle: 'مدنية، تجارية، جزائية، مبادئ قضائية',
        builder: (_) => const ComingSoonScreen(title: 'أحكام المحكمة العليا'),
      ),
      _SectionData(
        icon: Icons.description_outlined,
        title: 'المذكرات والنماذج القانونية',
        subtitle: 'صحائف دعاوى، مذكرات، عقود، إنذارات',
        builder: (_) => const ComingSoonScreen(title: 'المذكرات والنماذج القانونية'),
      ),
      _SectionData(
        icon: Icons.star_border_rounded,
        title: 'المفضلة',
        subtitle: 'المواد والأحكام والمراجع المحفوظة',
        builder: (_) => const FavoritesScreen(),
      ),
      _SectionData(
        icon: Icons.edit_note_outlined,
        title: 'ملاحظات واقتراحات',
        subtitle: 'شاركنا رأيك لتطوير التطبيق',
        builder: (_) => const FeedbackScreen(),
      ),
      _SectionData(
        icon: Icons.phone_in_talk_outlined,
        title: 'التواصل والاستشارات',
        subtitle: 'محاماة - استشارات قانونية',
        builder: (_) => const ContactScreen(),
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit(context);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppConstants.appNameAr),
          actions: const [
            _ThemeToggleButton(),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final s = sections[index];
                    return _SectionCard(
                      data: s,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: s.builder),
                      ),
                    );
                  },
                ),
              ),
              const _HomeFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  _SectionData({required this.icon, required this.title, required this.subtitle, required this.builder});
}

class _SectionCard extends StatelessWidget {
  final _SectionData data;
  final VoidCallback onTap;

  const _SectionCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, size: 34, color: context.accent),
              const SizedBox(height: 12),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: context.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return PopupMenuButton<ThemeMode>(
      icon: Icon(
        settings.themeMode == ThemeMode.dark
            ? Icons.dark_mode_outlined
            : settings.themeMode == ThemeMode.light
                ? Icons.light_mode_outlined
                : Icons.brightness_auto_outlined,
      ),
      onSelected: (mode) => context.read<SettingsProvider>().setThemeMode(mode),
      itemBuilder: (context) => const [
        PopupMenuItem(value: ThemeMode.dark, child: Text('الوضع الليلي')),
        PopupMenuItem(value: ThemeMode.light, child: Text('الوضع النهاري')),
        PopupMenuItem(value: ThemeMode.system, child: Text('تلقائي (حسب الهاتف)')),
      ],
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Column(
        children: [
          Text(
            AppConstants.dedicationText,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: context.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppConstants.contactShortName} • ${AppConstants.contactTitleShort} • ${AppConstants.contactPhone}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: context.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            AppConstants.copyrightText,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: context.textSecondary.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}
