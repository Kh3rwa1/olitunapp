<?php
/**
 * Banners API Endpoint
 */

require_once '../core/db.php';
require_once '../core/response.php';
require_once '../core/field_mapper.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        $query = "SELECT * FROM banners ORDER BY order_index ASC";
        $stmt = $db->prepare($query);
        $stmt->execute();
        $banners = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach($banners as &$item) {
            $item['is_active'] = (bool)$item['is_active'];
            $item['order_index'] = (int)$item['order_index'];
        }

        sendResponse(mapRowsToCamel($banners));
        break;

    case 'POST':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        
        if (!isset($data['id']) || !isset($data['title'])) {
            sendResponse(null, 400, "Missing required fields");
        }

        $query = "INSERT INTO banners 
                  (id, title, subtitle, image_url, lottie_url, button_text, action_url, gradient_preset, bg_color, text_color, order_index, is_active) 
                  VALUES 
                  (:id, :title, :subtitle, :image_url, :lottie_url, :button_text, :action_url, :gradient_preset, :bg_color, :text_color, :order_index, :is_active)";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':title', $data['title']);
        $stmt->bindParam(':subtitle', $data['subtitle']);
        $stmt->bindParam(':image_url', $data['image_url']);
        $stmt->bindParam(':lottie_url', $data['lottie_url']);
        $stmt->bindParam(':button_text', $data['button_text']);
        $stmt->bindParam(':action_url', $data['action_url']);
        $stmt->bindParam(':gradient_preset', $data['gradient_preset']);
        $stmt->bindParam(':bg_color', $data['bg_color']);
        $stmt->bindParam(':text_color', $data['text_color']);
        $stmt->bindParam(':order_index', $data['order_index']);
        $stmt->bindValue(':is_active', getField($data, 'is_active', true) ? 1 : 0, PDO::PARAM_INT);

        if($stmt->execute()) {
            sendResponse("Banner created successfully", 201);
        } else {
            sendResponse(null, 500, "Failed to create banner");
        }
        break;

    case 'PUT':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        if (!isset($data['id'])) sendResponse(null, 400, "Missing ID");

        $query = "UPDATE banners SET 
                  title = :title, 
                  subtitle = :subtitle, 
                  image_url = :image_url, 
                  lottie_url = :lottie_url, 
                  button_text = :button_text, 
                  action_url = :action_url, 
                  gradient_preset = :gradient_preset, 
                  bg_color = :bg_color,
                  text_color = :text_color,
                  order_index = :order_index, 
                  is_active = :is_active
                  WHERE id = :id";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':title', $data['title']);
        $stmt->bindParam(':subtitle', $data['subtitle']);
        $stmt->bindParam(':image_url', $data['image_url']);
        $stmt->bindParam(':lottie_url', $data['lottie_url']);
        $stmt->bindParam(':button_text', $data['button_text']);
        $stmt->bindParam(':action_url', $data['action_url']);
        $stmt->bindParam(':gradient_preset', $data['gradient_preset']);
        $stmt->bindParam(':bg_color', $data['bg_color']);
        $stmt->bindParam(':text_color', $data['text_color']);
        $stmt->bindParam(':order_index', $data['order_index']);
        $stmt->bindValue(':is_active', getField($data, 'is_active', true) ? 1 : 0, PDO::PARAM_INT);

        if($stmt->execute()) {
            sendResponse("Banner updated successfully");
        } else {
            sendResponse(null, 500, "Failed to update banner");
        }
        break;

    case 'DELETE':
        $id = isset($_GET['id']) ? $_GET['id'] : null;
        if (!$id) sendResponse(null, 400, "Missing ID");

        $query = "DELETE FROM banners WHERE id = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':id', $id);

        if($stmt->execute()) {
            sendResponse("Banner deleted successfully");
        } else {
            sendResponse(null, 500, "Failed to delete banner");
        }
        break;
}
?>
