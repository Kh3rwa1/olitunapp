<?php
/**
 * Olitun API Core Response Helper
 */

// Global configuration
date_default_timezone_set('UTC');

// Security headers
$allowedOrigins = array_filter(array_map('trim', explode(',', getenv('ALLOWED_ORIGINS') ?: '')));
$requestOrigin = $_SERVER['HTTP_ORIGIN'] ?? '';
if ($requestOrigin && in_array($requestOrigin, $allowedOrigins, true)) {
    header("Access-Control-Allow-Origin: " . $requestOrigin);
    header("Vary: Origin");
}
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

/**
 * Send JSON response
 * @param mixed $data Data to send
 * @param int $code HTTP status code
 * @param string|null $message Optional message
 */
function sendResponse($data = null, $code = 200, $message = null) {
    http_response_code($code);
    
    $response = [
        'success' => $code >= 200 && $code < 300,
        'code' => $code
    ];

    if ($message !== null) {
        $response['message'] = $message;
    }

    if ($data !== null) {
        $response['data'] = $data;
    }

    echo json_encode($response);
    exit();
}

/**
 * Get request body as associative array
 * @return array
 */
function getJsonInput() {
    $input = json_decode(file_get_contents("php://input"), true);
    if (!is_array($input)) {
        return [];
    }
    return $input;
}
?>
