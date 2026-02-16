<?php
/**
 * Numbers API Endpoint
 */

require_once '../core/db.php';
require_once '../core/response.php';
require_once '../core/field_mapper.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        $query = "SELECT * FROM numbers ORDER BY order_index ASC";
        $stmt = $db->prepare($query);
        $stmt->execute();
        $numbers = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach($numbers as &$item) {
            $item['value'] = (int)$item['value'];
            $item['order_index'] = (int)$item['order_index'];
        }

        sendResponse(mapRowsToCamel($numbers));
        break;

    case 'POST':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        
        if (!isset($data['id']) || !isset($data['numeral'])) {
            sendResponse(null, 400, "Missing required fields");
        }

        $query = "INSERT INTO numbers 
                  (id, numeral, value, name_ol_chiki, name_latin, order_index, audio_url, image_url) 
                  VALUES 
                  (:id, :numeral, :value, :name_ol_chiki, :name_latin, :order_index, :audio_url, :image_url)";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':numeral', $data['numeral']);
        $stmt->bindParam(':value', $data['value']);
        $stmt->bindParam(':name_ol_chiki', $data['name_ol_chiki']);
        $stmt->bindParam(':name_latin', $data['name_latin']);
        $stmt->bindParam(':order_index', $data['order_index']);
        $stmt->bindParam(':audio_url', $data['audio_url']);
        $stmt->bindParam(':image_url', $data['image_url']);

        if($stmt->execute()) {
            sendResponse("Number created successfully", 201);
        } else {
            sendResponse(null, 500, "Failed to create number");
        }
        break;

    case 'PUT':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        if (!isset($data['id'])) sendResponse(null, 400, "Missing ID");

        $query = "UPDATE numbers SET 
                  numeral = :numeral, 
                  value = :value, 
                  name_ol_chiki = :name_ol_chiki, 
                  name_latin = :name_latin, 
                  order_index = :order_index, 
                  audio_url = :audio_url, 
                  image_url = :image_url
                  WHERE id = :id";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':numeral', $data['numeral']);
        $stmt->bindParam(':value', $data['value']);
        $stmt->bindParam(':name_ol_chiki', $data['name_ol_chiki']);
        $stmt->bindParam(':name_latin', $data['name_latin']);
        $stmt->bindParam(':order_index', $data['order_index']);
        $stmt->bindParam(':audio_url', $data['audio_url']);
        $stmt->bindParam(':image_url', $data['image_url']);

        if($stmt->execute()) {
            sendResponse("Number updated successfully");
        } else {
            sendResponse(null, 500, "Failed to update number");
        }
        break;

    case 'DELETE':
        $id = isset($_GET['id']) ? $_GET['id'] : null;
        if (!$id) sendResponse(null, 400, "Missing ID");

        $query = "DELETE FROM numbers WHERE id = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':id', $id);

        if($stmt->execute()) {
            sendResponse("Number deleted successfully");
        } else {
            sendResponse(null, 500, "Failed to delete number");
        }
        break;
}
?>
