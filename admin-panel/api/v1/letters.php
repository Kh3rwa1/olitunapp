<?php
/**
 * Letters API Endpoint
 */

require_once '../core/db.php';
require_once '../core/response.php';
require_once '../core/field_mapper.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        $stmt = $db->prepare("SELECT * FROM letters ORDER BY order_index ASC");
        $stmt->execute();
        $letters = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach($letters as &$item) {
            $item['is_active'] = (bool)$item['is_active'];
            $item['order_index'] = (int)$item['order_index'];
        }
        
        sendResponse(mapRowsToCamel($letters));
        break;

    case 'POST':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        
        if (!isset($data['id']) || !isset($data['char_ol_chiki'])) {
            sendResponse(null, 400, "Missing required fields");
        }

        $stmt = $db->prepare("INSERT INTO letters 
                  (id, char_ol_chiki, transliteration_latin, order_index, is_active, example_word, audio_url, image_url, lottie_url) 
                  VALUES 
                  (:id, :char_ol_chiki, :transliteration_latin, :order_index, :is_active, :example_word, :audio_url, :image_url, :lottie_url)");
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':char_ol_chiki', $data['char_ol_chiki']);
        $stmt->bindParam(':transliteration_latin', $data['transliteration_latin']);
        $stmt->bindParam(':order_index', $data['order_index']);
        $stmt->bindValue(':is_active', getField($data, 'is_active', true) ? 1 : 0, PDO::PARAM_INT);
        $stmt->bindParam(':example_word', $data['example_word']);
        $stmt->bindParam(':audio_url', $data['audio_url']);
        $stmt->bindParam(':image_url', $data['image_url']);
        $stmt->bindParam(':lottie_url', $data['lottie_url']);

        if($stmt->execute()) {
            sendResponse("Letter created successfully", 201);
        } else {
            sendResponse(null, 500, "Failed to create letter");
        }
        break;

    case 'PUT':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        
        if (!isset($data['id'])) {
            sendResponse(null, 400, "Missing ID");
        }

        $stmt = $db->prepare("UPDATE letters SET 
                  char_ol_chiki = :char_ol_chiki, 
                  transliteration_latin = :transliteration_latin, 
                  order_index = :order_index, 
                  is_active = :is_active, 
                  example_word = :example_word, 
                  audio_url = :audio_url, 
                  image_url = :image_url,
                  lottie_url = :lottie_url
                  WHERE id = :id");
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':char_ol_chiki', $data['char_ol_chiki']);
        $stmt->bindParam(':transliteration_latin', $data['transliteration_latin']);
        $stmt->bindParam(':order_index', $data['order_index']);
        $stmt->bindValue(':is_active', getField($data, 'is_active', true) ? 1 : 0, PDO::PARAM_INT);
        $stmt->bindParam(':example_word', $data['example_word']);
        $stmt->bindParam(':audio_url', $data['audio_url']);
        $stmt->bindParam(':image_url', $data['image_url']);
        $stmt->bindParam(':lottie_url', $data['lottie_url']);

        if($stmt->execute()) {
            sendResponse("Letter updated successfully");
        } else {
            sendResponse(null, 500, "Failed to update letter");
        }
        break;

    case 'DELETE':
        $id = isset($_GET['id']) ? $_GET['id'] : null;
        if (!$id) sendResponse(null, 400, "Missing ID");

        $stmt = $db->prepare("DELETE FROM letters WHERE id = :id");
        $stmt->bindParam(':id', $id);

        if($stmt->execute()) {
            sendResponse("Letter deleted successfully");
        } else {
            sendResponse(null, 500, "Failed to delete letter");
        }
        break;
}
?>
