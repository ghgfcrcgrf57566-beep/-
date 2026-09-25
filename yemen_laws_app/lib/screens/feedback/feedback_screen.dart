import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/connectivity_service.dart';
import '../../data/repositories/laws_repository.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _repo = LawsRepository.instance;
  final _controller = TextEditingController();
  bool _sending = false;

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    // نحفظ الملاحظة محليًا دائمًا أولاً، حتى لا يُفقد ما كتبه المستخدم
    // مهما حدث (سواء وُجد اتصال أم لا).
    final id = await _repo.addFeedbackNote(text);

    final hasInternet = await ConnectivityService.hasConnection();

    if (!mounted) return;

    if (!hasInternet) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppConstants.noInternetMessage),
          backgroundColor: AppColors.danger,
        ),
      );
      // النص يبقى كما هو في الحقل، ولم يُفقد، والملاحظة محفوظة محليًا
      // بانتظار محاولة إرسال لاحقة (سنن Sync عند توفر خادم مستقبلاً).
      return;
    }

    // ملاحظة: لا يوجد حاليًا خادم فعلي متصل بالتطبيق لاستقبال الملاحظات.
    // عند توفر اتصال، نكتفي بتعليم الملاحظة كمُرسلة محليًا؛ اربط هذه
    // الخطوة مستقبلاً بطلب API حقيقي (مثال: http.post لعنوان الخادم).
    await _repo.markFeedbackSent(id);

    if (!mounted) return;
    setState(() {
      _sending = false;
      _controller.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم استلام ملاحظتك، شكرًا لك')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملاحظات واقتراحات')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_outlined, color: context.accent, size: 26),
                const SizedBox(width: 8),
                Text(
                  'ملاحظات واقتراحات',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              AppConstants.feedbackIntro,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13.5, height: 1.7, color: context.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              textAlign: TextAlign.right,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'اكتب ملاحظتك أو اقتراحك هنا...',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_outlined),
              label: const Text('إرسال'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.antiqueBronze,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
