<?php
/**
 * Words API Endpoint
 */

require_once '../core/db.php';
require_once '../core/response.php';
require_once '../core/field_mapper.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        $stmt = $db->prepare("SELECT * FROM words ORDER BY order_index ASC");
        $stmt->execute();
        $words = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach($words as &$item) {
            $item['order_index'] = (int)$item['order_index'];
        }

        sendResponse(mapRowsToCamel($words));
        break;

    case 'POST':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        
        if (!isset($data['id']) || !isset($data['word_latin'])) {
            sendResponse(null, 400, "Missing required fields");
        }

        $stmt = $db->prepare("INSERT INTO words 
                  (id, word_ol_chiki, word_latin, meaning, usage_example, category, order_index, audio_url, image_url) 
                  VALUES 
                  (:id, :word_ol_chiki, :word_latin, :meaning, :usage_example, :category, :order_index, :audio_url, :image_url)");
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':word_ol_chiki', $data['word_ol_chiki']);
        $stmt->bindParam(':word_latin', $data['word_latin']);
        $stmt->bindParam(':meaning', $data['meaning']);
        $stmt->bindParam(':usage_example', $data['usage_example']);
        $stmt->bindParam(':category', $data['category']);
        $stmt->bindParam(':order_index', $data['order_index']);
        $stmt->bindParam(':audio_url', $data['audio_url']);
        $stmt->bindParam(':image_url', $data['image_url']);

        if($stmt->execute()) {
            sendResponse("Word created successfully", 201);
        } else {
            sendResponse(null, 500, "Failed to create word");
        }
        break;

    case 'PUT':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        if (!isset($data['id'])) sendResponse(null, 400, "Missing ID");

        $stmt = $db->prepare("UPDATE words SET 
                  word_ol_chiki = :word_ol_chiki, 
                  word_latin = :word_latin, 
                  meaning = :meaning, 
                  usage_example = :usage_example, 
                  category = :category, 
                  order_index = :order_index, 
                  audio_url = :audio_url, 
                  image_url = :image_url
                  WHERE id = :id");
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':word_ol_chiki', $data['word_ol_chiki']);
        $stmt->bindParam(':word_latin', $data['word_latin']);
        $stmt->bindParam(':meaning', $data['meaning']);
        $stmt->bindParam(':usage_example', $data['usage_example']);
        $stmt->bindParam(':category', $data['category']);
        $stmt->bindParam(':order_index', $data['order_index']);
        $stmt->bindParam(':audio_url', $data['audio_url']);
        $stmt->bindParam(':image_url', $data['image_url']);

        if($stmt->execute()) {
            sendResponse("Word updated successfully");
        } else {
            sendResponse(null, 500, "Failed to update word");
        }
        break;

    case 'DELETE':
        $id = isset($_GET['id']) ? $_GET['id'] : null;
        if (!$id) sendResponse(null, 400, "Missing ID");

        $stmt = $db->prepare("DELETE FROM words WHERE id = :id");
        $stmt->bindParam(':id', $id);

        if($stmt->execute()) {
            sendResponse("Word deleted successfully");
        } else {
            sendResponse(null, 500, "Failed to delete word");
        }
        break;
}
?>
