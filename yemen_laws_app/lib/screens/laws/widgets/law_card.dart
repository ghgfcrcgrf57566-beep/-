import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../data/models/law.dart';

class LawCard extends StatelessWidget {
  final Law law;
  final VoidCallback onTap;

  const LawCard({super.key, required this.law, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: context.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.balance, color: context.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      law.name,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${law.articlesCount} مادة${law.category != null ? ' • ${law.category}' : ''}',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12.5, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: context.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
