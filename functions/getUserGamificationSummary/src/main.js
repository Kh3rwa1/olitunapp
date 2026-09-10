import { Client, Databases, Query } from "node-appwrite";

import {
  LEADERBOARD_RULES,
  leaderboardForUser,
  parseBody,
  scoreWeeklyEvents,
  utcWeekRange,
} from "./leaderboard.js";

export const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || "olitun_db";
export const ANALYTICS_COLLECTION = "learning_analytics_events";
const BADGES_COLLECTION = "badges";
const USER_BADGES_COLLECTION = "user_badges";
const REWARD_EVENTS_COLLECTION = "reward_events";
const PAGE_SIZE = 100;
const MAX_EVENTS_PER_TYPE = 5000;

async function listWeeklyEvents(databases, start, end) {
  const events = [];
  for (const eventName of Object.keys(LEADERBOARD_RULES)) {
    let offset = 0;
    while (true) {
      const result = await databases.listDocuments(
        DATABASE_ID,
        ANALYTICS_COLLECTION,
        [
          Query.equal("eventName", eventName),
          Query.greaterThanEqual("dateKey", start),
          Query.lessThanEqual("dateKey", end),
          Query.limit(PAGE_SIZE),
          Query.offset(offset),
        ],
      );
      events.push(...result.documents);
      if (result.documents.length < PAGE_SIZE) break;
      offset += result.documents.length;
      if (offset >= MAX_EVENTS_PER_TYPE) {
        throw new Error(`Leaderboard event limit reached for ${eventName}.`);
      }
    }
  }
  return events;
}

export async function buildWeeklyLeaderboard(
  databases,
  userId,
  now = new Date(),
) {
  const week = utcWeekRange(now);
  const events = await listWeeklyEvents(databases, week.start, week.end);
  const scored = scoreWeeklyEvents(events, week.start, week.end);
  const current = leaderboardForUser(scored, userId);
  return {
    ...current,
    weekStart: week.start,
    weekEnd: week.end,
    generatedAt: new Date().toISOString(),
  };
}

function appwriteClient(req) {
  const endpoint =
    process.env.APPWRITE_FUNCTION_API_ENDPOINT || process.env.APPWRITE_ENDPOINT;
  const projectId =
    process.env.APPWRITE_FUNCTION_PROJECT_ID || process.env.APPWRITE_PROJECT_ID;
  const apiKey =
    req.headers["x-appwrite-key"] ||
    process.env.APPWRITE_FUNCTION_API_KEY ||
    process.env.APPWRITE_API_KEY;

  if (!endpoint || !projectId || !apiKey) {
    throw new Error("Missing Appwrite function environment variables.");
  }

  return new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);
}

async function loadGamificationSummary(databases, userId) {
  const [badgesResult, userBadgesResult, rewardsResult] = await Promise.all([
    databases.listDocuments(DATABASE_ID, BADGES_COLLECTION, [
      Query.equal("status", "published"),
      Query.equal("isActive", true),
      Query.orderAsc("sortOrder"),
      Query.limit(500),
    ]),
    databases.listDocuments(DATABASE_ID, USER_BADGES_COLLECTION, [
      Query.equal("userId", userId),
      Query.limit(500),
    ]),
    databases.listDocuments(DATABASE_ID, REWARD_EVENTS_COLLECTION, [
      Query.equal("userId", userId),
      Query.limit(100),
    ]),
  ]);

  const progressByBadge = new Map(
    userBadgesResult.documents.map((doc) => [doc.badgeId, doc]),
  );
  const badges = badgesResult.documents.map((badge) => {
    const progress = progressByBadge.get(badge.badgeId) || {};
    const target = progress.target || badge.target || 1;
    return {
      badgeId: badge.badgeId,
      name: badge.name || "Learning badge",
      description: badge.description || "Keep learning to unlock this badge.",
      category: badge.category || "learning",
      icon: badge.icon || "🏆",
      rewardStars: Math.max(0, Math.min(badge.rewardStars || 0, 100)),
      progress: progress.progress || 0,
      target,
      isUnlocked: progress.isUnlocked === true,
      unlockedAt: progress.unlockedAt || "",
      updatedAt: progress.updatedAt || "",
    };
  });
  const recentRewards = rewardsResult.documents
    .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0))
    .slice(0, 20)
    .map((reward) => ({
      rewardEventId: reward.rewardEventId || reward.$id,
      sourceType: reward.sourceType || "",
      sourceId: reward.sourceId || "",
      starsAwarded: reward.starsAwarded || 0,
      badgeId: reward.badgeId || "",
      reason: reward.reason || "",
      createdAt: reward.createdAt || "",
    }));

  return { badges, recentRewards };
}

export default async ({ req, res, error }) => {
  if (req.method !== "POST") {
    return res.json({ ok: false, message: "Method not allowed" }, 405);
  }

  const userId = String(req.headers["x-appwrite-user-id"] || "").trim();
  if (!userId) {
    return res.json({ ok: false, message: "Unauthenticated" }, 401);
  }

  try {
    const databases = new Databases(appwriteClient(req));
    const body = parseBody(req.bodyJson ?? req.bodyText ?? req.body);
    if (body.scope === "leaderboard") {
      const leaderboard = await buildWeeklyLeaderboard(databases, userId);
      return res.json({ ok: true, leaderboard });
    }

    const summary = await loadGamificationSummary(databases, userId);
    return res.json({ ok: true, ...summary });
  } catch (err) {
    error(`getUserGamificationSummary error: ${err?.message || String(err)}`);
    return res.json(
      { ok: false, message: "Unable to load live leaderboard data." },
      500,
    );
  }
};
