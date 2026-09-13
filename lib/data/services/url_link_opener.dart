import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/repositories/link_opener.dart';

/// فتح الروابط عبر `url_launcher` في تطبيق خارجي (المتصفح أو البريد).
class UrlLinkOpener implements LinkOpener {
  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // جهاز بلا متصفح أو رابط مرفوض — نعيد false لتعرض الشاشة رسالة بدل التعطّل.
      debugPrint('تعذّر فتح الرابط $uri: $e');
      return false;
    }
  }
}
