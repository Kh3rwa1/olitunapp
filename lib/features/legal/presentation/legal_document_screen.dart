import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ads/widgets/banner_ad_widget.dart';
import '../../../core/ads/widgets/native_ad_widget.dart';

enum LegalDocumentType { privacy, terms }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({required this.type, super.key});

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final document = switch (type) {
      LegalDocumentType.privacy => _privacyDocument,
      LegalDocumentType.terms => _termsDocument,
    };

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      bottomNavigationBar: const BannerAdWidget(placement: 'legal_bottom'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          tooltip: 'Go back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          document.title,
          style: AppTypography.inter(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.updated,
                      style: AppTypography.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final section in document.sections) ...[
                      Text(
                        section.title,
                        style: AppTypography.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        section.body,
                        style: AppTypography.inter(
                          height: 1.55,
                          fontSize: 15,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                    const SizedBox(height: 16),
                    const RepaintBoundary(
                      child: NativeAdWidget(placement: 'legal_native'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalDocument {
  const _LegalDocument({
    required this.title,
    required this.updated,
    required this.sections,
  });

  final String title;
  final String updated;
  final List<_LegalSection> sections;
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}

const _privacyDocument = _LegalDocument(
  title: 'Privacy Policy',
  updated: 'Last updated: 15 October 2026',
  sections: [
    _LegalSection(
      'What Olitun Collects',
      'Sign-in and your account record (account ID, email or Google name and email, display name, sessions) are handled by Appwrite in its Singapore region. Signed-in accounts also store onboarding choices and a copy of progress statistics in Appwrite account preferences. Guest use creates an anonymous account with no email.',
    ),
    _LegalSection(
      'Data Stored On Cloudflare',
      'Other data is stored on Cloudflare (Workers, the D1 database and R2 storage): review states, quiz mistakes, Bakhed listening progress, badges and rewards, learning analytics events, Binti waitlist submissions (name, phone number, ceremony type, city, state, optional date and notes), and purchase records (Razorpay order and payment IDs, amount, status).',
    ),
    _LegalSection(
      'How Data Is Used',
      'Data is used to sign you in, sync progress across devices, run review, badges and leaderboards, unlock purchased content, contact waitlist applicants, understand feature use, prevent abuse, and fix errors.',
    ),
    _LegalSection(
      'Service Providers',
      'Translations use Google Translate and Cloudflare Workers AI. AI Studio speech-to-text uses Sarvam AI. Santali voice uses Bodhan. Payments use Razorpay; card, UPI and bank details go directly to Razorpay and are never stored by Olitun. Android and iOS apps show Google AdMob ads, with a consent form where required. Builds with crash reporting send scrubbed error reports to Sentry.',
    ),
    _LegalSection(
      'Retention',
      'Learning data is kept until you delete your account. A cleanup job deletes raw analytics events older than 90 days. Translation and voice caches are shared, not linked to your account, and not deleted on a fixed schedule. AI Studio audio and documents are not stored by Olitun. Purchase records are kept for financial records.',
    ),
    _LegalSection(
      'Local And Offline Data',
      'The app keeps progress, settings, cached content and queued requests on the device for offline use. This storage relies on the operating system sandbox. Resetting progress or uninstalling the app removes local learning data.',
    ),
    _LegalSection(
      'Deleting Your Account',
      'Delete Account removes your Cloudflare files and every database row linked to your account, keeps purchase records with your account ID replaced by an anonymous marker, and then deletes your Appwrite account, or permanently blocks its sign-in if it cannot be deleted directly. A record of the deletion request is kept with its status.',
    ),
    _LegalSection(
      'Contact',
      'For privacy questions or data removal requests, contact the project maintainers through the GitHub repository at github.com/Kh3rwa1/olitunapp.',
    ),
  ],
);

const _termsDocument = _LegalDocument(
  title: 'Terms Of Use',
  updated: 'Last updated: May 5, 2026',
  sections: [
    _LegalSection(
      'Learning Purpose',
      'Olitun is an educational app for learning Ol Chiki and related Santali learning content. It should be used respectfully and with care for learners, families, and community language resources.',
    ),
    _LegalSection(
      'Accounts And Admin Access',
      'Users are responsible for the accounts they create. Admin tools are limited to authorized team members and must only be used to publish accurate, appropriate learning material.',
    ),
    _LegalSection(
      'Content',
      'Learning content, media, translations, and examples should not be copied, uploaded, or shared unless you have the rights to use them. Admins should verify rights before publishing media or lesson content.',
    ),
    _LegalSection(
      'Availability',
      'The app may change, pause, or remove features as the product improves. Offline features can continue to work with local data, but cloud sync and translation require network access.',
    ),
    _LegalSection(
      'No Harmful Use',
      'Do not abuse the app, bypass access controls, overload translation services, upload unsafe content, or use the platform in a way that harms other users or the service.',
    ),
  ],
);
