import 'package:connectivity_plus/connectivity_plus.dart';

/// فحص بسيط لوجود اتصال بالإنترنت، يُستخدم فقط في قسم "الملاحظات
/// والاقتراحات" لتقرير ما إذا كان بالإمكان محاولة الإرسال الآن أم لا.
/// المحتوى القانوني الأساسي للتطبيق لا يعتمد على هذا الفحص إطلاقًا.
class ConnectivityService {
  static Future<bool> hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }
}
