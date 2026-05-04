<?php
/**
 * Media File Upload API for Olitun Admin Panel
 * Host: Hostinger Business Web Hosting
 * 
 * Endpoints:
 * POST /api/upload.php - Upload media file (audio, image, video, lottie)
 * 
 * Returns JSON: { "success": bool, "url": string, "error": string }
 */

// CORS headers for Flutter web
$allowedOrigins = array_filter(array_map('trim', explode(',', getenv('ALLOWED_ORIGINS') ?: '')));
$requestOrigin = $_SERVER['HTTP_ORIGIN'] ?? '';
if ($requestOrigin && in_array($requestOrigin, $allowedOrigins, true)) {
    header('Access-Control-Allow-Origin: ' . $requestOrigin);
    header('Vary: Origin');
}
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Debug logging
function debugLog($msg) {
    file_put_contents('debug.log', date('[Y-m-d H:i:s] ') . $msg . "\n", FILE_APPEND);
}
debugLog("Request from " . $_SERVER['REMOTE_ADDR'] . " Method: " . $_SERVER['REQUEST_METHOD']);

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only allow POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit();
}


// Require upload token.
// IMPORTANT: Set UPLOAD_API_TOKEN in hosting environment.
// This is a temporary hardening layer until uploads are moved to Appwrite Storage.
$expectedToken = getenv('UPLOAD_API_TOKEN') ?: '';
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';

$providedToken = '';
if (preg_match('/Bearer\s+(.+)/', $authHeader, $matches)) {
    $providedToken = trim($matches[1]);
}

if ($expectedToken === '' || $providedToken === '' || !hash_equals($expectedToken, $providedToken)) {
    http_response_code(401);
    echo json_encode(['success' => false, 'error' => 'Unauthorized']);
    exit();
}

// Configuration
$uploadDir = '../audio/';
$allowedMimeByExtension = [
    // Audio
    'mp3' => ['audio/mpeg'],
    'wav' => ['audio/wav', 'audio/x-wav'],
    'ogg' => ['audio/ogg'],
    'aac' => ['audio/aac'],
    'm4a' => ['audio/mp4'],
    // Images
    'jpg' => ['image/jpeg'],
    'jpeg' => ['image/jpeg'],
    'png' => ['image/png'],
    'gif' => ['image/gif'],
    'webp' => ['image/webp'],
    // SVG disabled for security. Use PNG/WebP instead.
    // Video
    'mp4' => ['video/mp4'],
    'webm' => ['video/webm'],
    'mov' => ['video/quicktime'],
    // Lottie
    'json' => ['application/json', 'text/plain'],
];
$maxFileSize = 50 * 1024 * 1024; // 50MB (videos can be larger)

// Check if file was uploaded
if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
    $errorCode = isset($_FILES['file']) ? $_FILES['file']['error'] : 'No file';
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => "Upload error: $errorCode"]);
    exit();
}

$file = $_FILES['file'];

// Validate file size
if ($file['size'] > $maxFileSize) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'File too large (max 50MB)']);
    exit();
}

// Validate file type
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mimeType = finfo_file($finfo, $file['tmp_name']);
finfo_close($finfo);

$extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
$allowedMimes = $allowedMimeByExtension[$extension] ?? [];
debugLog("File: " . $file['name'] . " MIME: $mimeType EXT: $extension");
if (empty($allowedMimes) || !in_array($mimeType, $allowedMimes, true)) {
    debugLog("REJECTED: Invalid type $mimeType");
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => "Invalid file type for extension .$extension"]);
    exit();
}

// Get folder from POST (letters, lessons, animations, etc.)
$folder = isset($_POST['folder']) ? preg_replace('/[^a-z0-9\-]/', '', $_POST['folder']) : 'misc';
$targetDir = $uploadDir . $folder . '/';

// Create folder if needed
if (!is_dir($targetDir)) {
    mkdir($targetDir, 0755, true);
}

// Generate unique filename
$filename = time() . '_' . bin2hex(random_bytes(4)) . '.' . $extension;
$targetPath = $targetDir . $filename;

// Move file
if (move_uploaded_file($file['tmp_name'], $targetPath)) {
    // Build public URL (adjust base URL as needed)
    $baseUrl = (isset($_SERVER['HTTPS']) ? 'https://' : 'http://') . $_SERVER['HTTP_HOST'];
    $publicUrl = $baseUrl . '/admin-panel/audio/' . $folder . '/' . $filename;
    
    debugLog("SUCCESS: " . $publicUrl);
    echo json_encode([
        'success' => true,
        'url' => $publicUrl,
        'filename' => $filename
    ]);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Failed to save file']);
}
?>
