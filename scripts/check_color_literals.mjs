#!/usr/bin/env node

/**
 * CI Gate: Enforce Design System Color Tokens & Ban Raw Color Literals
 *
 * Rules:
 * 1. Hardcoded Color(0x...) and const Color(0x...) literals are prohibited in feature & presentation code.
 * 2. All colors must use tokens defined in lib/core/theme/app_colors.dart or theme semantic surfaces.
 * 3. lib/core/theme/ is permanently exempt as the single source of truth.
 * 4. Ratchet enforcement: Existing files with grandfathered counts must not increase; as files are cleaned up,
 *    their counts in GRANDFATHERED_COUNTS must be reduced or removed.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, '..');
const LIB_DIR = path.join(ROOT_DIR, 'lib');

// Directories permanently exempt from color token gate
const EXEMPT_DIRECTORIES = [
  'lib/core/theme',
  'lib/l10n/generated',
];

// Grandfather list with exact allowed count per file.
// As files are refactored to use AppColors, decrease their count or remove them entirely.
const GRANDFATHERED_COUNTS = {
  "lib/core/ads/widgets/native_ad_widget.dart": 1,
  "lib/features/admin/presentation/affirmations/admin_affirmations_screen.dart": 6,
  "lib/features/admin/presentation/analytics/widgets/admin_analytics_cards.dart": 2,
  "lib/features/admin/presentation/banners/widgets/banner_form_sheet.dart": 1,
  "lib/features/admin/presentation/categories/widgets/category_form_sheet.dart": 2,
  "lib/features/admin/presentation/content/widgets/content_bulk_action_bar.dart": 2,
  "lib/features/admin/presentation/content/widgets/content_filter_bar.dart": 1,
  "lib/features/admin/presentation/content/widgets/content_grid_card.dart": 1,
  "lib/features/admin/presentation/content/widgets/content_list_tile.dart": 1,
  "lib/features/admin/presentation/dashboard/widgets/analytics_chart.dart": 2,
  "lib/features/admin/presentation/dashboard/widgets/dashboard_analytics_panel.dart": 2,
  "lib/features/admin/presentation/gamification/widgets/gamification_widgets.dart": 1,
  "lib/features/admin/presentation/lessons/content/admin_lesson_content_screen.dart": 1,
  "lib/features/admin/presentation/lessons/content/widgets/add_block_sheet.dart": 5,
  "lib/features/admin/presentation/lessons/content/widgets/edit_block_sheet.dart": 8,
  "lib/features/admin/presentation/lessons/content/widgets/lesson_block_card.dart": 7,
  "lib/features/admin/presentation/lessons/content/widgets/lesson_content_top_bar.dart": 6,
  "lib/features/admin/presentation/lessons/content/widgets/lesson_editor_block_list.dart": 1,
  "lib/features/admin/presentation/lessons/content/widgets/lesson_mockup_preview.dart": 8,
  "lib/features/admin/presentation/lessons/content/widgets/universal_block_sheet.dart": 8,
  "lib/features/admin/presentation/lessons/widgets/lesson_card.dart": 2,
  "lib/features/admin/presentation/login/widgets/admin_login_background.dart": 3,
  "lib/features/admin/presentation/numbers/widgets/number_grid.dart": 3,
  "lib/features/admin/presentation/quizzes/widgets/quiz_form_sheet/option_editor.dart": 4,
  "lib/features/admin/presentation/quizzes/widgets/quiz_form_sheet/quiz_questions_section.dart": 3,
  "lib/features/admin/presentation/sentences/widgets/sentence_card.dart": 4,
  "lib/features/admin/presentation/shell/admin_shell.dart": 5,
  "lib/features/admin/presentation/shell/widgets/admin_top_bar.dart": 1,
  "lib/features/admin/presentation/widgets/admin_command_palette.dart": 1,
  "lib/features/admin/presentation/widgets/admin_glass_card.dart": 1,
  "lib/features/admin/presentation/widgets/content_form.dart": 3,
  "lib/features/admin/presentation/widgets/content_form/content_block_edit_dialog.dart": 1,
  "lib/features/admin/presentation/widgets/content_form/content_block_list_section.dart": 6,
  "lib/features/admin/presentation/widgets/content_form/content_form_card.dart": 4,
  "lib/features/admin/presentation/widgets/content_form/content_form_identity_section.dart": 5,
  "lib/features/admin/presentation/widgets/dashboard_kpi_widgets.dart": 4,
  "lib/features/admin/presentation/words/widgets/word_card.dart": 3,
  "lib/features/affirmations/presentation/widgets/affirmation_share_sheet.dart": 1,
  "lib/features/auth/presentation/email_auth/email_auth_screen.dart": 1,
  "lib/features/content/presentation/widgets/inline_media_players.dart": 2,
  "lib/features/content/presentation/widgets/premium_bakhed_body.dart": 3,
  "lib/features/content/presentation/widgets/story_player_body.dart": 2,
  "lib/features/home/presentation/widgets/next_best_action_card.dart": 3,
  "lib/features/learn/presentation/screens/content_grid_screen.dart": 3,
  "lib/features/lessons/presentation/category_lessons_screen.dart": 2,
  "lib/features/lessons/presentation/practice/stroke_order_view.dart": 2,
  "lib/features/lessons/presentation/widgets/blocks/quiz_block_cta_widget.dart": 3,
  "lib/features/lessons/presentation/widgets/category_lessons/category_browse_all_card.dart": 1,
  "lib/features/lessons/presentation/widgets/category_lessons/category_hero_header.dart": 1,
  "lib/features/lessons/presentation/widgets/category_lessons/category_lesson_card.dart": 1,
  "lib/features/lessons/presentation/widgets/category_lessons/category_lessons_timeline.dart": 3,
  "lib/features/lessons/presentation/widgets/dynamic_blocks/dynamic_html_block.dart": 3,
  "lib/features/lessons/presentation/widgets/lesson_block_detail/lesson_block_card_content.dart": 1,
  "lib/features/lessons/presentation/widgets/lesson_block_detail/lesson_block_hero_header.dart": 1,
  "lib/features/lessons/presentation/widgets/lesson_block_detail/lesson_block_item_view.dart": 2,
  "lib/features/lessons/presentation/widgets/lesson_block_detail/lesson_block_quiz_cta.dart": 3,
  "lib/features/main/presentation/main_shell/main_shell_screen.dart": 4,
  "lib/features/main/presentation/main_shell/widgets/desktop_right_panel.dart": 1,
  "lib/features/main/presentation/main_shell/widgets/desktop_sidebar.dart": 1,
  "lib/features/profile/presentation/progress_screen.dart": 2,
  "lib/features/profile/presentation/widgets/mastery_chart.dart": 2,
  "lib/features/profile/presentation/widgets/next_milestone_card.dart": 4,
  "lib/features/profile/presentation/widgets/streak_calendar.dart": 3,
  "lib/features/quiz/presentation/mistake_review_screen.dart": 1,
  "lib/features/quiz/presentation/widgets/quiz_complete_screen.dart": 3,
  "lib/features/quiz/presentation/widgets/quiz_out_of_hearts_screen.dart": 3,
  "lib/features/rhymes/presentation/widgets/binti_guru_form_sheet.dart": 1,
  "lib/features/rhymes/presentation/widgets/binti_guru_landing.dart": 4,
  "lib/main.dart": 3
};

function getAllDartFiles(dir) {
  let results = [];
  const list = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of list) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results = results.concat(getAllDartFiles(fullPath));
    } else if (entry.isFile() && entry.name.endsWith('.dart')) {
      results.push(fullPath);
    }
  }

  return results;
}

function checkColorLiterals() {
  if (!fs.existsSync(LIB_DIR)) {
    console.error('Error: "lib" directory not found.');
    process.exit(1);
  }

  const dartFiles = getAllDartFiles(LIB_DIR);
  const colorLiteralRegex = /\bColor\(0x[0-9a-fA-F]+\)/g;

  const violations = [];
  const staleGrandfathered = [];
  let checkedCount = 0;
  let totalLiteralsFound = 0;

  for (const file of dartFiles) {
    const relPath = path.relative(ROOT_DIR, file).replace(/\\/g, '/');

    // Skip permanently exempt directories
    if (EXEMPT_DIRECTORIES.some((exempt) => relPath.startsWith(exempt))) {
      continue;
    }

    checkedCount++;
    const content = fs.readFileSync(file, 'utf-8');
    const matches = content.match(colorLiteralRegex) || [];
    const count = matches.length;
    totalLiteralsFound += count;

    const grandfatheredCount = GRANDFATHERED_COUNTS[relPath];

    if (grandfatheredCount !== undefined) {
      if (count < grandfatheredCount) {
        staleGrandfathered.push({
          path: relPath,
          actual: count,
          expected: grandfatheredCount,
        });
      } else if (count > grandfatheredCount) {
        violations.push({
          path: relPath,
          actual: count,
          expected: grandfatheredCount,
          message: `File increased color literals from ${grandfatheredCount} to ${count}.`,
        });
      }
    } else if (count > 0) {
      violations.push({
        path: relPath,
        actual: count,
        expected: 0,
        message: `New file contains ${count} raw Color(0x...) literal(s). Use AppColors tokens instead.`,
      });
    }
  }

  console.log(`\n🔍 Checked ${checkedCount} Dart files in lib/ for color token compliance.`);
  console.log(`📊 Found ${totalLiteralsFound} total remaining literals across ${Object.keys(GRANDFATHERED_COUNTS).length} grandfathered files.`);

  let hasError = false;

  if (staleGrandfathered.length > 0) {
    console.warn('\n⚠️  Ratcheting Gate: The following files have reduced color literals and must update GRANDFATHERED_COUNTS:');
    for (const item of staleGrandfathered) {
      if (item.actual === 0) {
        console.warn(`  - ${item.path} (CLEAN! 0 literals remaining, remove from GRANDFATHERED_COUNTS)`);
      } else {
        console.warn(`  - ${item.path} (decreased from ${item.expected} to ${item.actual})`);
      }
    }
    hasError = true;
  }

  if (violations.length > 0) {
    console.error('\n❌ Color Literal Violations:');
    for (const item of violations) {
      console.error(`  - ${item.path}: ${item.message}`);
    }
    console.error('\nPlease migrate hardcoded Color(0x...) literals to AppColors tokens in lib/core/theme/app_colors.dart.\n');
    hasError = true;
  }

  if (hasError) {
    process.exit(1);
  }

  console.log('✅ Color token gate passed successfully! Zero unapproved raw color literals.\n');
}

checkColorLiterals();
