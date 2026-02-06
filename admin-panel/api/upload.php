<?php
/**
 * Audio File Upload API for Olitun Admin Panel
 * Host: Hostinger Business Web Hosting
 * 
 * Endpoints:
 * POST /api/upload.php - Upload audio file
 * 
 * Returns JSON: { "success": bool, "url": string, "error": string }
 */

// CORS headers for Flutter web
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

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

// Configuration
$uploadDir = '../audio/';
$allowedTypes = ['audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/aac', 'audio/mp4'];
$maxFileSize = 10 * 1024 * 1024; // 10MB

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
    echo json_encode(['success' => false, 'error' => 'File too large (max 10MB)']);
    exit();
}

// Validate file type
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mimeType = finfo_file($finfo, $file['tmp_name']);
finfo_close($finfo);

if (!in_array($mimeType, $allowedTypes)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => "Invalid file type: $mimeType"]);
    exit();
}

// Get folder from POST (letters, lessons, etc.)
$folder = isset($_POST['folder']) ? preg_replace('/[^a-z0-9]/', '', $_POST['folder']) : 'misc';
$targetDir = $uploadDir . $folder . '/';

// Create folder if needed
if (!is_dir($targetDir)) {
    mkdir($targetDir, 0755, true);
}

// Generate unique filename
$extension = pathinfo($file['name'], PATHINFO_EXTENSION);
$filename = time() . '_' . bin2hex(random_bytes(4)) . '.' . $extension;
$targetPath = $targetDir . $filename;

// Move file
if (move_uploaded_file($file['tmp_name'], $targetPath)) {
    // Build public URL (adjust base URL as needed)
    $baseUrl = (isset($_SERVER['HTTPS']) ? 'https://' : 'http://') . $_SERVER['HTTP_HOST'];
    $publicUrl = $baseUrl . '/audio/' . $folder . '/' . $filename;
    
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
