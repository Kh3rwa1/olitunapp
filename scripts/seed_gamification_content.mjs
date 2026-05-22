#!/usr/bin/env node
/**
 * Seeds production-safe starter content for the admin-managed gamification CMS.
 *
 * This script uses the Appwrite CLI session for permissions, so run:
 *   APPWRITE_CLI="$HOME/.npm-global/bin/appwrite" node scripts/seed_gamification_content.mjs
 *
 * It only creates missing documents. Existing documents are left untouched.
 */

import { spawnSync } from 'node:child_process';

const appwrite = process.env.APPWRITE_CLI || 'appwrite';
const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
const now = new Date().toISOString();
const updatedBy = 'seed_gamification_content';

const rows = [
  ['gamification_config', 'default', {
    configId: 'default',
    bakhedCompletionThreshold: 80,
    streakShieldMax: 2,
    quickWinEnabled: true,
    badgesEnabled: true,
    mistakeReviewEnabled: true,
    updatedBy,
    updatedAt: now,
  }],

  ['bravo_messages', 'bravo_lesson_completed', {
    messageId: 'bravo_lesson_completed',
    trigger: 'lesson_completed',
    title: 'A real learning step',
    body: 'You gave Santali practice your attention today. Keep this pace gently.',
    language: 'en',
    scriptMode: 'both',
    learnerLevel: 'all',
    weight: 10,
    status: 'published',
    isActive: true,
    version: 1,
    updatedBy,
    createdAt: now,
    updatedAt: now,
  }],
  ['bravo_messages', 'bravo_quiz_correct', {
    messageId: 'bravo_quiz_correct',
    trigger: 'quiz_correct',
    title: 'Good recognition',
    body: 'You connected the sound, script, and meaning.',
    language: 'en',
    scriptMode: 'both',
    learnerLevel: 'all',
    weight: 8,
    status: 'published',
    isActive: true,
    version: 1,
    updatedBy,
    createdAt: now,
    updatedAt: now,
  }],
  ['bravo_messages', 'bravo_mistake_reviewed', {
    messageId: 'bravo_mistake_reviewed',
    trigger: 'quiz_wrong_but_reviewed',
    title: 'Second chances count',
    body: 'Mistakes are lessons asking for a second chance.',
    language: 'en',
    scriptMode: 'both',
    learnerLevel: 'all',
    weight: 8,
    status: 'published',
    isActive: true,
    version: 1,
    updatedBy,
    createdAt: now,
    updatedAt: now,
  }],
  ['bravo_messages', 'bravo_bakhed_listened', {
    messageId: 'bravo_bakhed_listened',
    trigger: 'bakhed_listened',
    title: 'You listened with care',
    body: 'Bakhed carries language, rhythm, and memory together.',
    language: 'en',
    scriptMode: 'both',
    learnerLevel: 'all',
    weight: 7,
    status: 'published',
    isActive: true,
    version: 1,
    updatedBy,
    createdAt: now,
    updatedAt: now,
  }],

  ...[
    ['first_lesson', 'First Lesson', 'Complete your first Santali learning step.', 'learning', '🏆', 1, 10],
    ['ten_lessons', '10 Lessons', 'Build steady learning with ten completed lessons.', 'learning', '📚', 10, 25],
    ['fifty_words', '50 Words', 'Practice fifty words across your vocabulary path.', 'learning', '🌾', 50, 50],
    ['quiz_master', 'Quiz Master', 'Complete quizzes with consistent understanding.', 'quiz', '🎯', 10, 30],
    ['ol_chiki_reader', 'Ol Chiki Reader', 'Grow comfort reading Ol Chiki letters and words.', 'learning', 'ᱚ', 30, 40],
    ['first_bakhed', 'First Bakhed', 'Listen to your first Bakhed learning story.', 'culture', '🎧', 1, 15],
    ['five_bakhed', '5 Bakhed Listened', 'Spend time with five Bakhed listening sessions.', 'culture', '🎵', 5, 30],
    ['cultural_explorer', 'Cultural Explorer', 'Read cultural notes with respect and curiosity.', 'culture', '🌿', 5, 25],
    ['three_day_streak', '3-Day Streak', 'Return to learning across three days.', 'habit', '🔥', 3, 15],
    ['seven_day_streak', '7-Day Streak', 'Keep a gentle learning rhythm for a week.', 'habit', '✨', 7, 25],
    ['thirty_day_streak', '30-Day Streak', 'Build a month of steady Santali practice.', 'habit', '🌙', 30, 75],
    ['perfect_week', 'Perfect Week', 'Complete every daily mission for a full week.', 'habit', '✅', 7, 50],
  ].map(([badgeId, name, description, category, icon, target, rewardStars], index) => [
    'badges',
    badgeId,
    {
      badgeId,
      name,
      description,
      category,
      icon,
      target,
      rewardStars,
      unlockRule: JSON.stringify({ type: badgeId, target }),
      status: 'published',
      isActive: true,
      sortOrder: index + 1,
      version: 1,
      updatedBy,
      createdAt: now,
      updatedAt: now,
    },
  ]),

  ...[
    ['complete_1_lesson', 'Complete 1 lesson', 'Take one focused step in your learning path.', 'lesson_completed', 1, 25, 'all', false, 1],
    ['take_1_quiz', 'Take 1 quick quiz', 'Check what you remember without pressure.', 'quiz_completed', 1, 15, 'all', false, 2],
    ['listen_1_bakhed', 'Listen to 1 Bakhed', 'Listen to at least 80 percent to count today.', 'bakhed_completed_80_percent', 1, 20, 'all', false, 3],
    ['review_1_mistake', 'Review 1 mistake', 'Give one tricky word a second chance.', 'mistake_review_completed', 1, 15, 'all', false, 4],
    ['quick_win_read_1_letter', 'Quick Win: Read 1 letter', 'Read one Ol Chiki letter with care.', 'quick_win_completed', 1, 10, 'beginner', true, 5],
  ].map(([missionId, title, description, type, targetCount, rewardStars, learnerLevel, isQuickWin, sortOrder]) => [
    'mission_templates',
    missionId,
    {
      missionId,
      title,
      description,
      type,
      targetCount,
      rewardStars,
      learnerLevel,
      isQuickWin,
      status: 'published',
      isActive: true,
      sortOrder,
      version: 1,
      updatedBy,
      createdAt: now,
      updatedAt: now,
    },
  ]),

  ...[
    ['reward_stars_25', 'stars_awarded', 'You earned 25 stars', 'Your practice was counted. Keep learning gently.', '25 stars', '⭐'],
    ['reward_badge_unlocked', 'badge_unlocked', 'Badge unlocked', 'You reached a meaningful learning milestone.', 'New badge', '🏆'],
    ['reward_streak_shield_used', 'streak_shield_used', 'Streak Shield used', 'Your streak is safe. Keep going today.', 'Shield used', '🛡️'],
  ].map(([messageId, trigger, title, body, rewardLabel, icon]) => [
    'reward_messages',
    messageId,
    {
      messageId,
      trigger,
      title,
      body,
      rewardLabel,
      icon,
      status: 'published',
      isActive: true,
      version: 1,
      updatedBy,
      createdAt: now,
      updatedAt: now,
    },
  ]),

  ...[
    ['feedback_correct', 'correct', 'Correct', 'Good recognition. Keep the sound and meaning together.'],
    ['feedback_incorrect', 'incorrect', 'Not yet', 'Pause, review the correct answer, and try again with care.'],
    ['feedback_review_needed', 'review_needed', 'Worth reviewing', 'This question can become easier after a short mistake review.'],
    ['feedback_perfect_score', 'perfect_score', 'Perfect score', 'You were focused and accurate through the whole quiz.'],
    ['feedback_passed', 'passed', 'Quiz passed', 'You understood enough to keep moving forward.'],
    ['feedback_failed', 'failed', 'Try one more review', 'This is a good moment to practice the missed questions.'],
  ].map(([messageId, type, title, body]) => [
    'quiz_feedback_messages',
    messageId,
    {
      messageId,
      type,
      title,
      body,
      status: 'published',
      isActive: true,
      version: 1,
      updatedBy,
      createdAt: now,
      updatedAt: now,
    },
  ]),

  ['bakhed_lyrics', 'seed_bakhed_lyric_1', {
    bakhedId: 'seed_bakhed_1',
    lineIndex: 0,
    startMs: 0,
    endMs: 4000,
    olChiki: 'ᱡᱚᱦᱟᱨ',
    latin: 'Johar',
    meaning: 'A respectful greeting.',
  }],
  ['bakhed_vocabulary', 'seed_bakhed_vocab_1', {
    bakhedId: 'seed_bakhed_1',
    olChiki: 'ᱡᱚᱦᱟᱨ',
    latin: 'Johar',
    meaning: 'Greeting or respect.',
    audioFileId: '',
    sortOrder: 1,
  }],
  ['bakhed_cultural_notes', 'seed_bakhed_note_1', {
    noteId: 'seed_bakhed_note_1',
    bakhedId: 'seed_bakhed_1',
    title: 'Cultural Note',
    body: 'Use Bakhed content with care: keep the source, context, and community meaning visible when teaching from it.',
    source: 'Olitun starter note',
    isPublished: true,
  }],

  ['admin_audit_logs', `seed_gamification_${Date.now()}`, {
    actorUserId: updatedBy,
    action: 'gamification_seed_created',
    targetType: 'gamification_content',
    targetId: 'starter_pack',
    metadata: JSON.stringify({ source: 'scripts/seed_gamification_content.mjs' }),
    success: true,
    createdAt: now,
  }],
];

let created = 0;
let skipped = 0;

for (const [collectionId, documentId, data] of rows) {
  const result = spawnSync(appwrite, [
    'databases',
    'create-document',
    '--database-id',
    databaseId,
    '--collection-id',
    collectionId,
    '--document-id',
    documentId,
    '--data',
    JSON.stringify(data),
  ], { encoding: 'utf8' });

  const output = `${result.stdout || ''}${result.stderr || ''}`;
  if (result.status === 0) {
    created += 1;
    console.log(`created ${collectionId}/${documentId}`);
  } else if (output.includes('already exists') || output.includes('document_already_exists')) {
    skipped += 1;
    console.log(`skipped ${collectionId}/${documentId}`);
  } else {
    console.error(output.trim());
    process.exit(result.status || 1);
  }
}

console.log(`\nDone. Created ${created}, skipped ${skipped}.`);
