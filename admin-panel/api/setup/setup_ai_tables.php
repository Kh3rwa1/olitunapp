<?php
/**
 * Setup AI-related database tables
 * URL: /admin-panel/api/setup/setup_ai_tables.php
 */

require_once '../core/db.php';
require_once '../core/response.php';

$database = new Database();
$db = $database->getConnection();

$queries = [
    "CREATE TABLE IF NOT EXISTS translation_cache (
        id INT AUTO_INCREMENT PRIMARY KEY,
        cache_key VARCHAR(64) UNIQUE NOT NULL,
        source_lang VARCHAR(10) NOT NULL,
        target_lang VARCHAR(10) NOT NULL,
        source_text TEXT NOT NULL,
        translated_text TEXT NOT NULL,
        detected_lang VARCHAR(10) DEFAULT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4",

    "CREATE TABLE IF NOT EXISTS rate_limits (
        client_ip VARCHAR(45) PRIMARY KEY,
        request_count INT DEFAULT 0,
        window_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4",

    "ALTER TABLE translation_cache ADD COLUMN IF NOT EXISTS detected_lang VARCHAR(10) DEFAULT NULL AFTER translated_text"
];

$results = [];
foreach ($queries as $q) {
    try {
        $stmt = $db->prepare($q);
        $stmt->execute();
        $results[] = ['query' => substr($q, 0, 60) . '...', 'status' => 'OK'];
    } catch (Exception $e) {
        $results[] = ['query' => substr($q, 0, 60) . '...', 'status' => 'ERROR', 'error' => $e->getMessage()];
    }
}

sendResponse($results);
