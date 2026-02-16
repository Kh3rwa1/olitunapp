<?php
/**
 * Sentences API Endpoint
 */

require_once '../core/db.php';
require_once '../core/response.php';
require_once '../core/field_mapper.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        $query = "SELECT * FROM sentences ORDER BY order_index ASC";
        $stmt = $db->prepare($query);
        $stmt->execute();
        $sentences = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach($sentences as &$item) {
            $item['order_index'] = (int)$item['order_index'];
        }

        sendResponse(mapRowsToCamel($sentences));
        break;

    case 'POST':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        
        if (!isset($data['id']) || !isset($data['sentence_latin'])) {
            sendResponse(null, 400, "Missing required fields");
        }

        $query = "INSERT INTO sentences 
                  (id, sentence_ol_chiki, sentence_latin, meaning, pronunciation, category, order_index, lesson_id) 
                  VALUES 
                  (:id, :sentence_ol_chiki, :sentence_latin, :meaning, :pronunciation, :category, :order_index, :lesson_id)";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':sentence_ol_chiki', $data['sentence_ol_chiki']);
        $stmt->bindParam(':sentence_latin', $data['sentence_latin']);
        $stmt->bindParam(':meaning', $data['meaning']);
        $stmt->bindParam(':pronunciation', $data['pronunciation']);
        $stmt->bindParam(':category', $data['category']);
        $stmt->bindParam(':order_index', $data['order_index']);
        $stmt->bindParam(':lesson_id', $data['lesson_id']);

        if($stmt->execute()) {
            sendResponse("Sentence created successfully", 201);
        } else {
            sendResponse(null, 500, "Failed to create sentence");
        }
        break;

    case 'PUT':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        if (!isset($data['id'])) sendResponse(null, 400, "Missing ID");

        $query = "UPDATE sentences SET 
                  sentence_ol_chiki = :sentence_ol_chiki, 
                  sentence_latin = :sentence_latin, 
                  meaning = :meaning, 
                  pronunciation = :pronunciation, 
                  category = :category, 
                  order_index = :order_index,
                  lesson_id = :lesson_id
                  WHERE id = :id";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':sentence_ol_chiki', $data['sentence_ol_chiki']);
        $stmt->bindParam(':sentence_latin', $data['sentence_latin']);
        $stmt->bindParam(':meaning', $data['meaning']);
        $stmt->bindParam(':pronunciation', $data['pronunciation']);
        $stmt->bindParam(':category', $data['category']);
        $stmt->bindParam(':order_index', $data['order_index']);
        $stmt->bindParam(':lesson_id', $data['lesson_id']);

        if($stmt->execute()) {
            sendResponse("Sentence updated successfully");
        } else {
            sendResponse(null, 500, "Failed to update sentence");
        }
        break;

    case 'DELETE':
        $id = isset($_GET['id']) ? $_GET['id'] : null;
        if (!$id) sendResponse(null, 400, "Missing ID");

        $query = "DELETE FROM sentences WHERE id = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':id', $id);

        if($stmt->execute()) {
            sendResponse("Sentence deleted successfully");
        } else {
            sendResponse(null, 500, "Failed to delete sentence");
        }
        break;
}
?>
