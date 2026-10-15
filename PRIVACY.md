# Olitun Privacy Policy

**Last updated:** 15 October 2026

Olitun is an educational app for learning Ol Chiki and Santali language and culture. This policy describes what data the Olitun app and its backend collect, why, where it is stored, who processes it, how long it is kept, and how you can delete it.

Olitun uses two backend systems:

- **Appwrite** (Appwrite Cloud, Singapore region) for sign-in and your account record.
- **Cloudflare** (Cloudflare Workers, the D1 database, and R2 file storage) for everything else. Cloudflare operates a global network; our D1 database currently runs in Cloudflare's Asia-Pacific region.

---

## 1. What We Collect, Why, and Where It Is Stored

| Data | Purpose | Stored in | Retention |
| :--- | :--- | :--- | :--- |
| **Account and sign-in data**: account ID; email address (email one-time-code sign-in, or the email and name shared by Google when you choose Google sign-in); display name; session records. Guest use creates an anonymous Appwrite account with no email. | Signing in, keeping you signed in, identifying your data on our servers | Appwrite (Singapore) | Until your account is deleted (see Section 5) |
| **Learner profile in account preferences**: onboarding choices (interface and teaching language, Santali proficiency, lesson audio mode, learning goals, daily goal minutes) and a copy of your progress statistics (completed lessons, practised letters, quiz history, stars, streaks, learning minutes, activity dates) | Syncing your profile and progress across devices | Appwrite account preferences (signed-in, non-guest accounts) | Until your account is deleted |
| **Learning progress**: word and sentence review states, quiz mistakes and mistake-review sessions, Bakhed listening progress, badges and reward events | Spaced review, mistake practice, resuming audio, badges and stars | Cloudflare D1, linked to your account ID | Until you delete it in the app (where offered) or delete your account |
| **Learning analytics events**: event name, event ID, content/source identifier, session ID, learner level, script mode, platform, timestamps, and event details such as content type, scores, attempt counts and stars awarded | Understanding feature use, daily usage totals, weekly leaderboard points | Cloudflare D1, linked to your account ID (including guest accounts) | Our server includes a cleanup job that deletes raw events older than 90 days. Daily totals (event counts and number of unique users) contain no account IDs. Weekly leaderboard scores derived from these events are cached by account ID. |
| **Binti / ceremony waitlist submissions**: full name, phone number, ceremony type, city, state, optional event date, optional notes, submission time, status; your account ID if you were signed in | Contacting you about ceremony recitation requests | Cloudflare D1 | Until deleted on request, or on account deletion for submissions linked to your account |
| **Purchases**: order ID, Razorpay payment ID and signature, amount, currency, status, receipt reference, purchased course category, refund records | Unlocking paid content, verifying payments, refunds, financial records | Cloudflare D1 | Kept for financial record-keeping; detached from your account ID on account deletion (see Section 5) |
| **Translation requests**: the text you submit, the source and target languages, the translation, and the engine used | Returning translations; caching repeat requests | Cloudflare D1 translation cache, keyed by a SHA-256 hash of the request. Not linked to your account ID. | Not deleted on a fixed schedule; administrators can clear the cache |
| **Santali voice (text-to-speech)**: text you ask to be spoken, voice, style | Generating Santali audio | The text is sent to Bodhan for synthesis. The generated audio is stored in Cloudflare R2 under a hash-based name, with a cache record (hash, voice, audio URL, duration). Neither is linked to your account ID, and the text itself is not stored in the cache record. | Not deleted on a fixed schedule; shared across learners and not deletable per user |
| **AI Studio audio** (speech-to-text) | Transcribing your recording | Sent through our server to Sarvam AI for transcription. We do not store the audio or the transcript. | Not stored by us |
| **AI Studio documents** (scan / OCR) | Document scanning feature | Sent to our server. We do not store the file and do not forward it to an external provider. | Not stored by us |
| **Rate-limit keys**: your account ID or your IP address (hashed for waitlist submissions) | Preventing abuse of paid AI, analytics and waitlist services | Cloudflare's rate-limiting service (short-lived counters, 60-second windows) | Short-lived counters only; not written to our database |
| **Account deletion requests**: request ID, status, timestamps, error code | Making sure deletion completes, resuming interrupted deletions | Cloudflare D1 | Kept with its status; your account ID is replaced with an anonymous marker once deletion completes (see Section 5) |
| **Crash and error reports** (release builds where crash reporting is configured) | Finding and fixing bugs | Sentry | Per Sentry's retention settings |
| **Server request logs** | Operating and securing the service | Cloudflare Workers logs | Per Cloudflare's log retention |

Administrators with authorised access can view and manage content, purchases, waitlist submissions and audit records through the admin tools. Administrator actions are recorded in an audit log.

---

## 2. Service Providers (Processors)

We share data with these providers only to run the features described above:

- **Appwrite**: authentication, sessions, account record and account preferences (Singapore region). Appwrite keeps session records, which may include information such as IP address and device or browser details.
- **Cloudflare**: Workers (API), D1 (database), R2 (file storage), rate limiting, request logs, hosting of the web app, and **Cloudflare Workers AI** for some translations (IndicTrans2, M2M100 and Llama models running on Cloudflare).
- **Google Translate**: the default translation engine, and the translation engine for AI Studio. The text to translate and the language codes are sent from our server.
- **Sarvam AI**: speech-to-text for AI Studio. Your audio recording is sent from our server.
- **Bodhan**: Santali text-to-speech. The text to be spoken is sent from our server.
- **Razorpay**: payments. Your card, UPI or bank details are entered directly into Razorpay's checkout and are handled by Razorpay; we never receive or store them. When we create an order, we send Razorpay the amount, a receipt reference, your account ID and the course category ID.
- **Google sign-in**: if you choose it, Google shares your name and email address with Appwrite to create your account.
- **Google AdMob** (Android and iOS apps only, not the web app): shows ads. AdMob may collect device identifiers and usage data under Google's policies. Where required (for example in the EEA and UK), the app asks for your ad consent through Google's consent tool, and you can change it later in **Settings > Ad Privacy Choices**.
- **Sentry**: crash and error reporting, only in builds configured with a Sentry key. Reports are sent with Sentry's default personal data collection turned off; before sending, the app removes user ID, email, username and IP address, request headers and cookies, URL query strings, and values that look like emails, tokens, passwords or IP addresses. Reports include error details, stack traces and a sample of performance traces.
- **timeapi.io / worldtimeapi.org**: the app requests the current time from these public services to check daily missions. No account data is sent, but these services receive your IP address as part of the request.

---

## 3. Data on Your Device

Olitun works offline. Lesson progress, settings, profile choices, cached content, downloaded audio and queued requests (such as analytics events waiting to be sent) are stored on your device using the app's local storage. This storage is not encrypted by the app; it relies on your operating system's app sandbox. You can reset your progress in **Settings**, and uninstalling the app removes this data. Daily reminders are scheduled locally on your device.

---

## 4. Children

Olitun does not ask for your age. Ad requests are not currently marked as directed at children.

---

## 5. Account Deletion and Your Choices

You can delete your account in **Settings > Delete Account**. When you do, our server:

1. Deletes all files stored under your account in Cloudflare R2.
2. Deletes every row linked to your account ID in our D1 database, including review states, mistakes, review sessions, Bakhed listening progress, badges, reward events, analytics events and their details, and waitlist submissions linked to your account.
3. Keeps purchase and payment-order records for financial record-keeping, but replaces your account ID in them with an anonymous marker.
4. Checks that no rows linked to your account ID remain.
5. Deletes your Appwrite account, including your account preferences. If the server cannot delete the account directly, it permanently blocks the account so it can no longer sign in; the blocked account record (including its email, name and preferences) stays in Appwrite until it is deleted later.

A record of the deletion request is kept with its status. When deletion fully completes, your account ID in that record is replaced with an anonymous marker; if the account was blocked instead of deleted, the account ID is kept so the account can be deleted later. Interrupted deletions are retried.

Data not linked to your account ID is not removed by account deletion: the shared translation and voice caches, daily analytics totals, weekly leaderboard caches, and waitlist submissions you made without signing in. To ask for removal of a waitlist submission, contact us (Section 6).

On the device, deleting your account also clears the app's local session data.

---

## 6. Contact

For privacy questions or data removal requests, contact the project maintainers through the GitHub repository: https://github.com/Kh3rwa1/olitunapp

We may update this policy as the app changes. The date at the top shows when it was last updated.
