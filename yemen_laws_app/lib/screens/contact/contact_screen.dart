import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التواصل والاستشارات')),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x66D4AF37)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFF0D78A), Color(0xFF8A671C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.black87,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    AppConstants.contactName,
                    style: TextStyle(
                      color: Color(0xFFF0D78A),
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    AppConstants.contactTitleFull,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsetsDirectional.only(
                      start: 8,
                      end: 8,
                      top: 6,
                      bottom: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x19D4AF37),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x55D4AF37)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'نسخ الرقم',
                          onPressed: () async {
                            await Clipboard.setData(
                              const ClipboardData(
                                text: AppConstants.contactPhone,
                              ),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ رقم التواصل'),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: Color(0xFFD4AF37),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 2),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            final uri = Uri(
                              scheme: 'tel',
                              path: AppConstants.contactPhone,
                            );
                            final launched = await launchUrl(uri);
                            if (!launched && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تعذر فتح تطبيق الاتصال'),
                                ),
                              );
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.phone_rounded,
                                  color: Color(0xFFD4AF37),
                                  size: 21,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  AppConstants.contactPhone,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF181512),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x442E261A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'عن التطبيق',
                        style: TextStyle(
                          color: context.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.info_outline_rounded,
                        color: context.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppConstants.dedicationText,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: context.textSecondary,
                      height: 1.8,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '© ${AppConstants.copyrightText}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
