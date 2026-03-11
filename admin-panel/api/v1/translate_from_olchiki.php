<?php
/**
 * Google Translate Proxy → Ol Chiki to Any Language
 * POST /api/v1/translate_from_olchiki.php
 * Body: { "text": "ᱡᱚᱦᱟᱨ", "to": "en" }
 */

require_once '../core/db.php';
require_once '../core/response.php';
require_once dirname(__DIR__, 2) . '/vendor/autoload.php';

use Stichoza\GoogleTranslate\GoogleTranslate;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(null, 405, 'Method not allowed');
}

$input = getJsonInput();
$text = trim($input['text'] ?? '');
$to   = $input['to'] ?? 'en';

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
$cacheKey = md5("sat:$to:$text");

$stmt = $db->prepare("SELECT translated_text FROM translation_cache WHERE cache_key = ?");
$stmt->execute([$cacheKey]);
$cached = $stmt->fetch(PDO::FETCH_ASSOC);

if ($cached) {
    sendResponse([
        'translation' => $cached['translated_text'],
        'cached' => true,
    ]);
}

// --- Translate via Google ---
try {
    $tr = new GoogleTranslate($to);
    $tr->setSource('sat');

    $translated = $tr->translate($text);

    $stmt = $db->prepare(
        "INSERT INTO translation_cache (cache_key, source_lang, target_lang, source_text, translated_text, detected_lang)
         VALUES (?, 'sat', ?, ?, ?, 'sat')
         ON DUPLICATE KEY UPDATE translated_text = VALUES(translated_text)"
    );
    $stmt->execute([$cacheKey, $to, $text, $translated]);

    sendResponse([
        'translation' => $translated,
        'cached' => false,
    ]);
} catch (Exception $e) {
    error_log("Google Translate error: " . $e->getMessage());
    sendResponse(null, 500, 'Translation failed');
}
