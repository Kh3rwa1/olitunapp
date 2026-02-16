<?php
/**
 * App Settings API Endpoint
 * GET    - Returns all settings
 * PUT    - Updates a setting (key + value in JSON body)
 */

require_once '../core/db.php';
require_once '../core/response.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        // Optional: filter by key
        $key = isset($_GET['key']) ? $_GET['key'] : null;
        
        if ($key) {
            $query = "SELECT setting_key, setting_value FROM app_settings WHERE setting_key = :key";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':key', $key);
            $stmt->execute();
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($row) {
                sendResponse([
                    'key' => $row['setting_key'],
                    'value' => $row['setting_value']
                ]);
            } else {
                sendResponse(null, 404, "Setting not found");
            }
        } else {
            $query = "SELECT setting_key, setting_value FROM app_settings ORDER BY setting_key";
            $stmt = $db->prepare($query);
            $stmt->execute();
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Convert to key-value map
            $settings = [];
            foreach ($rows as $row) {
                $settings[$row['setting_key']] = $row['setting_value'];
            }
            sendResponse($settings);
        }
        break;

    case 'PUT':
        $data = getJsonInput();
        
        if (!isset($data['key'])) {
            sendResponse(null, 400, "Missing 'key' field");
        }

        $key = $data['key'];
        $value = isset($data['value']) ? $data['value'] : null;

        $query = "INSERT INTO app_settings (setting_key, setting_value) 
                  VALUES (:key, :value) 
                  ON DUPLICATE KEY UPDATE setting_value = :value2, updated_at = CURRENT_TIMESTAMP";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(':key', $key);
        $stmt->bindParam(':value', $value);
        $stmt->bindParam(':value2', $value);

        if ($stmt->execute()) {
            sendResponse("Setting updated successfully");
        } else {
            sendResponse(null, 500, "Failed to update setting");
        }
        break;

    default:
        sendResponse(null, 405, "Method not allowed");
        break;
}
?>
