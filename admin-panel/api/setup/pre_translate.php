<?php
/**
 * Pre-translate all lesson content (English → Santali)
 * Run once to warm the translation cache
 * URL: /admin-panel/api/setup/pre_translate.php
 */

header('Content-Type: application/json; charset=UTF-8');
set_time_limit(0);

require_once '../core/db.php';
require_once dirname(__DIR__, 2) . '/vendor/autoload.php';

use Stichoza\GoogleTranslate\GoogleTranslate;

try {
    $database = new Database();
    $db = $database->getConnection();

    $tr = new GoogleTranslate('sat');
    $tr->setSource('en');

    $results = [];
    $errors = [];
    $newCount = 0;
    $cachedCount = 0;

    // 1. Words: translate 'meaning' (English) → Santali
    try {
        $stmt = $db->query("SELECT id, meaning FROM words WHERE meaning IS NOT NULL AND meaning != ''");
        $words = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($words as $word) {
            $text = trim($word['meaning']);
            if (empty($text)) continue;

            $cacheKey = md5("en:sat:$text");
            $check = $db->prepare("SELECT translated_text FROM translation_cache WHERE cache_key = ?");
            $check->execute([$cacheKey]);

            if ($check->fetch()) {
                $cachedCount++;
                continue;
            }

            $translated = $tr->translate($text);
            if ($translated) {
                $ins = $db->prepare("INSERT INTO translation_cache (cache_key, source_lang, target_lang, source_text, translated_text, detected_lang) VALUES (?, 'en', 'sat', ?, ?, 'en')");
                $ins->execute([$cacheKey, $text, $translated]);
                $results[] = ['source' => $text, 'translated' => $translated, 'table' => 'words'];
                $newCount++;
                sleep(1);
            }
        }
    } catch (Exception $e) {
        $errors[] = "Words: " . $e->getMessage();
    }

    // 2. Letters: translate pronunciation → Santali
    try {
        $stmt = $db->query("SELECT id, transliteration_latin FROM letters WHERE transliteration_latin IS NOT NULL");
        $letters = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($letters as $letter) {
            $text = trim($letter['transliteration_latin']);
            if (empty($text)) continue;

            $cacheKey = md5("en:sat:$text");
            $check = $db->prepare("SELECT translated_text FROM translation_cache WHERE cache_key = ?");
            $check->execute([$cacheKey]);

            if ($check->fetch()) {
                $cachedCount++;
                continue;
            }

            $translated = $tr->translate($text);
            if ($translated) {
                $ins = $db->prepare("INSERT INTO translation_cache (cache_key, source_lang, target_lang, source_text, translated_text, detected_lang) VALUES (?, 'en', 'sat', ?, ?, 'en')");
                $ins->execute([$cacheKey, $text, $translated]);
                $results[] = ['source' => $text, 'translated' => $translated, 'table' => 'letters'];
                $newCount++;
                sleep(1);
            }
        }
    } catch (Exception $e) {
        $errors[] = "Letters: " . $e->getMessage();
    }

    echo json_encode([
        'success' => true,
        'summary' => [
            'newly_translated' => $newCount,
            'already_cached' => $cachedCount,
            'errors' => count($errors),
        ],
        'translations' => $results,
        'errors' => $errors,
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
