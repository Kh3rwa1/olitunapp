import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/gamification_section.dart';
import '../../widgets/admin_page_header.dart';
import '../widgets/gamification_widgets.dart';

class GamificationOverviewView extends StatelessWidget {
  const GamificationOverviewView({super.key});

  String _pathForSection(String key) {
    return switch (key) {
      'badges' => '/admin/gamification/badges',
      'config' => '/admin/gamification/config',
      'bakhed_lyrics' => '/admin/gamification/bakhed/lyrics',
      'bakhed_vocabulary' => '/admin/gamification/bakhed/vocabulary',
      'bakhed_notes' => '/admin/gamification/bakhed/cultural-notes',
      _ => '/admin/gamification',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 860;
    final cards = gamificationSections.values
        .where((section) => section.key != 'audit_logs')
        .toList(growable: false);

    return Padding(
      padding: EdgeInsets.all(isWide ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminPageHeader(
            title: 'Gamification CMS',
            subtitle:
                'Admin-managed copy, badges, circles, missions, rewards, config, and scoring traces.',
            eyebrow: 'PRODUCT OPS',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : 1,
                childAspectRatio: isWide ? 2.4 : 3.4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final section = cards[index];
                return GamificationOverviewCard(
                  section: section,
                  onTap: () => context.go(_pathForSection(section.key)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
