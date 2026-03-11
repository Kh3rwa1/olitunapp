<?php
/**
 * Google Translate Proxy → Any Language to Santali (Ol Chiki)
 * POST /api/v1/translate.php
 * Body: { "text": "Hello", "from": "auto", "to": "sat" }
 *
 * Features: MySQL caching, rate limiting (20/hour/IP)
 */

require_once '../core/db.php';
require_once '../core/response.php';
require_once dirname(__DIR__, 2) . '/vendor/autoload.php';

use Stichoza\GoogleTranslate\GoogleTranslate;

// Only POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(null, 405, 'Method not allowed');
}

$input = getJsonInput();
$text = trim($input['text'] ?? '');
$from = $input['from'] ?? 'auto';
$to   = $input['to'] ?? 'sat';

if (empty($text)) {
    sendResponse(null, 400, 'Missing "text" field');
}

$database = new Database();
$db = $database->getConnection();

// --- Rate limiting ---
$clientIp = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$maxRequests = 20;

$stmt = $db->prepare("SELECT request_count, window_start FROM rate_limits WHERE client_ip = ?");
$stmt->execute([$clientIp]);
$rateRow = $stmt->fetch(PDO::FETCH_ASSOC);

if ($rateRow) {
    $windowStart = strtotime($rateRow['window_start']);
    if (time() - $windowStart > 3600) {
        // Reset window
        $stmt = $db->prepare("UPDATE rate_limits SET request_count = 1, window_start = NOW() WHERE client_ip = ?");
        $stmt->execute([$clientIp]);
    } elseif ($rateRow['request_count'] >= $maxRequests) {
        sendResponse(null, 429, 'Rate limit exceeded. Try again later.');
    } else {
        $stmt = $db->prepare("UPDATE rate_limits SET request_count = request_count + 1 WHERE client_ip = ?");
        $stmt->execute([$clientIp]);
    }
} else {
    $stmt = $db->prepare("INSERT INTO rate_limits (client_ip, request_count, window_start) VALUES (?, 1, NOW())");
    $stmt->execute([$clientIp]);
}

// --- Check cache ---
$sourceLang = ($from === 'auto') ? 'auto' : $from;
$cacheKey = md5("$sourceLang:$to:$text");

$stmt = $db->prepare("SELECT translated_text, detected_lang FROM translation_cache WHERE cache_key = ?");
$stmt->execute([$cacheKey]);
$cached = $stmt->fetch(PDO::FETCH_ASSOC);

if ($cached) {
    sendResponse([
        'translation' => $cached['translated_text'],
        'detectedLanguage' => $cached['detected_lang'] ?? $from,
        'cached' => true,
    ]);
}

// --- Translate via Google ---
try {
    $tr = new GoogleTranslate($to);
    if ($from !== 'auto') {
        $tr->setSource($from);
    }

    $translated = $tr->translate($text);
    $detectedLang = $tr->getLastDetectedSource() ?? $from;

    // Cache result
    $stmt = $db->prepare(
        "INSERT INTO translation_cache (cache_key, source_lang, target_lang, source_text, translated_text, detected_lang) 
         VALUES (?, ?, ?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE translated_text = VALUES(translated_text), detected_lang = VALUES(detected_lang)"
    );
    $stmt->execute([$cacheKey, $sourceLang, $to, $text, $translated, $detectedLang]);

    sendResponse([
        'translation' => $translated,
        'detectedLanguage' => $detectedLang,
        'cached' => false,
    ]);
} catch (Exception $e) {
    error_log("Google Translate error: " . $e->getMessage());
    sendResponse(null, 500, 'Translation failed');
}
