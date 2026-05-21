import { Client, Databases, Query, Users } from 'node-appwrite';

export default async ({ req, res, log, error }) => {
  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT;
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;
  const apiKey = process.env.APPWRITE_API_KEY;

  if (!endpoint || !projectId || !apiKey) {
    error('Missing environment variables');
    return res.json({ ok: false, message: 'Server misconfiguration' }, 500);
  }

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);

  const databases = new Databases(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';

  try {
    const now = new Date();
    // 1. Fetch ended circles that are still open or full
    const endedCirclesResult = await databases.listDocuments(
      databaseId,
      'weekly_circles',
      [
        Query.lessThan('endsAt', now.toISOString()),
        Query.equal('status', ['open', 'full'])
      ]
    );

    log(`Found ${endedCirclesResult.total} circles to finalize`);

    for (const circle of endedCirclesResult.documents) {
      log(`Finalizing circle ${circle.$id}`);

      // 2. Fetch all members in this circle
      const membersResult = await databases.listDocuments(
        databaseId,
        'circle_members',
        [
          Query.equal('circleId', circle.$id)
        ]
      );

      const members = membersResult.documents;
      members.sort((a, b) => {
        if (b.circlePoints !== a.circlePoints) {
          return b.circlePoints - a.circlePoints;
        }
        if (b.missionDaysCompleted !== a.missionDaysCompleted) {
          return b.missionDaysCompleted - a.missionDaysCompleted;
        }
        if (b.quizzesTaken !== a.quizzesTaken) {
          return b.quizzesTaken - a.quizzesTaken;
        }
        return new Date(a.joinedAt) - new Date(b.joinedAt);
      });

      // 3. Assign final ranks and award rewards
      for (let i = 0; i < members.length; i++) {
        const member = members[i];
        const rank = i + 1;

        await databases.updateDocument(
          databaseId,
          'circle_members',
          member.$id,
          { rank: rank }
        );

        // Award stars and badges progress based on ranks
        let starsAwarded = 0;
        let badgeEarnedType = '';

        if (rank === 1) {
          starsAwarded = 100;
          badgeEarnedType = 'circle_champion';
        } else if (rank <= 3) {
          starsAwarded = 50;
          badgeEarnedType = 'top_learner';
        } else if (rank <= 5) {
          starsAwarded = 25;
          badgeEarnedType = 'weekly_climber';
        }

        try {
          const users = new Users(client);
          const user = await users.get(member.userId);
          const prefs = user.prefs || {};
          let progressData = {};
          try {
            progressData = JSON.parse(prefs.user_progress_data || '{}');
          } catch (_) {
            progressData = {};
          }
          
          const currentStars = progressData.totalStars || 0;
          progressData.totalStars = currentStars + starsAwarded;
          
          // Note: Badge unlocking on client is fully calculated client-side based on user stats,
          // so incrementing totalStars automatically unlocks the corresponding circle/stars badges.
          
          prefs.user_progress_data = JSON.stringify(progressData);
          await users.updatePrefs(member.userId, prefs);
          
          log(`Awarded ${starsAwarded} stars to user ${member.userId} in preferences`);
        } catch (e) {
          log(`Failed to update preferences for user ${member.userId}: ${e.message}`);
        }
      }

      // 4. Set circle status to closed
      await databases.updateDocument(
        databaseId,
        'weekly_circles',
        circle.$id,
        { status: 'closed' }
      );
      log(`Circle ${circle.$id} finalized successfully ✅`);
    }

    return res.json({ ok: true, finalizedCirclesCount: endedCirclesResult.total });
  } catch (err) {
    error('finalizeWeeklyCircles error: ' + err.message);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
