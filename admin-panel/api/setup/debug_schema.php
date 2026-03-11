<?php
header('Content-Type: application/json');
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Test 1: db.php path
$dbPath = __DIR__ . '/../core/db.php';
echo "db.php exists: " . (file_exists($dbPath) ? 'yes' : 'no') . "\n";

// Test 2: autoloader path
$autoPath = dirname(__DIR__, 2) . '/vendor/autoload.php';
echo "autoload exists ($autoPath): " . (file_exists($autoPath) ? 'yes' : 'no') . "\n";

// Test 3: include db.php
require_once $dbPath;
$db = getDB();
echo "DB connected\n";

// Test 4: include autoloader
require_once $autoPath;
echo "Autoloader loaded\n";

// Test 5: check tables
$stmt = $db->query("DESCRIBE words");
$cols = array_column($stmt->fetchAll(PDO::FETCH_ASSOC), 'Field');
echo "words columns: " . implode(', ', $cols) . "\n";

$stmt = $db->query("DESCRIBE letters");
$cols = array_column($stmt->fetchAll(PDO::FETCH_ASSOC), 'Field');
echo "letters columns: " . implode(', ', $cols) . "\n";
