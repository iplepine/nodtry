import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/proof/domain/proof_labels.dart' show kSupportEmail;

/// The policy pages, on the same Firebase Hosting site as invite links
/// (`https://nod-try.web.app/i/{CODE}`). The hosting lane serves
/// privacy-policy/index.html, support/index.html and the terms of use at these
/// paths; check they resolve before a store submission.
const String kPrivacyPolicyUrl = 'https://nod-try.web.app/privacy';
const String kTermsOfUseUrl = 'https://nod-try.web.app/terms';
const String kSupportPageUrl = 'https://nod-try.web.app/support';

/// Opens a link outside the app (browser, mail app). Returns whether it
/// opened. Overridable in tests.
typedef ExternalLinkLauncher = Future<bool> Function(Uri uri);

final externalLinkLauncherProvider = Provider<ExternalLinkLauncher>((ref) {
  return (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[LegalLinks] launch failed: $e');
      return false;
    }
  };
});

/// A `mailto:` draft to the support inbox.
Uri supportMailUri({required String subject, String body = ''}) {
  // Uri(queryParameters:) encodes spaces as '+', which mail apps show
  // literally; percent-encode each part instead.
  final query =
      'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
  return Uri.parse('mailto:$kSupportEmail?$query');
}
