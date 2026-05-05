import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          document.title,
          style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final section in document.sections) ...[
                      Text(
                        section.title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        section.body,
                        style: GoogleFonts.inter(
                          height: 1.55,
                          fontSize: 15,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
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
  updated: 'Last updated: May 5, 2026',
  sections: [
    _LegalSection(
      'What Olitun Collects',
      'Olitun stores account details needed for sign-in, learner progress, app preferences, and content created through admin tools. Translation requests may be processed by the translator function so the app can return learning support in the selected language.',
    ),
    _LegalSection(
      'How Data Is Used',
      'Data is used to keep the learning experience working across sessions, sync approved educational content, protect admin areas, improve reliability, and respond to account or support requests.',
    ),
    _LegalSection(
      'Local And Offline Data',
      'The app keeps some progress and settings on the device for offline use. Clearing local app data or deleting an account may remove this local learning state.',
    ),
    _LegalSection(
      'Third-Party Services',
      'Olitun uses Appwrite for authentication, database, storage, and server functions. Optional crash reporting can be enabled for production diagnostics. Translation requests may use an external translation provider through the server-side function.',
    ),
    _LegalSection(
      'Your Choices',
      'You can reset local progress in settings, delete your account from the app, or contact the project owner to request help with data access or removal.',
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
