<?php
/**
 * Olitun Data Export Script
 * Run this on Hostinger to export all MySQL data as JSON.
 * 
 * Upload to: olitun.in/admin-panel/api/export_data.php
 * Access via: https://olitun.in/admin-panel/api/export_data.php?key=olitun_export_2025
 * 
 * The output is a single JSON file with all tables.
 */

header('Content-Type: application/json; charset=utf-8');

// Simple auth key to prevent unauthorized access
$key = $_GET['key'] ?? '';
$expectedKey = getenv('EXPORT_API_KEY') ?: '';
if ($expectedKey === '' || !hash_equals($expectedKey, $key)) {
    http_response_code(403);
    echo json_encode(['error' => 'Invalid key']);
    exit;
}

// Database connection (same as your db.php)
try {
    $pdo = new PDO(
        "mysql:host=localhost;dbname=u236276440_olitun;charset=utf8mb4",
        "u236276440_olitun",
        getenv('DB_PASSWORD') ?: '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'DB connection failed: ' . $e->getMessage()]);
    exit;
}

$tables = [
    'categories',
    'lessons',
    'lesson_blocks',
    'letters',
    'numbers',
    'words',
    'rhymes',
    'banners',
    'rhyme_categories',
    'rhyme_subcategories',
    'app_settings',
];

$export = [];

foreach ($tables as $table) {
    try {
        $stmt = $pdo->prepare("SELECT * FROM `$table`");
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $export[$table] = $rows;
    } catch (PDOException $e) {
        $export[$table] = ['_error' => $e->getMessage()];
    }
}

echo json_encode($export, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
