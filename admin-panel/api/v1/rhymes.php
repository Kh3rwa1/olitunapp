<?php
/**
 * Rhymes API Endpoint
 */

require_once '../core/db.php';
require_once '../core/response.php';
require_once '../core/field_mapper.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        $query = "SELECT * FROM rhymes ORDER BY created_at DESC";
        $stmt = $db->prepare($query);
        $stmt->execute();
        $rhymes = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach($rhymes as &$item) {
            $item['duration_seconds'] = (int)$item['duration_seconds'];
            $item['is_premium'] = (bool)$item['is_premium'];
        }

        sendResponse(mapRowsToCamel($rhymes));
        break;

    case 'POST':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        
        if (!isset($data['id']) || !isset($data['title_latin'])) {
            sendResponse(null, 400, "Missing required fields");
        }

        $query = "INSERT INTO rhymes 
                  (id, title_ol_chiki, title_latin, content_ol_chiki, content_latin, audio_url, thumbnail_url, category, subcategory, difficulty, duration_seconds, is_premium) 
                  VALUES 
                  (:id, :title_ol_chiki, :title_latin, :content_ol_chiki, :content_latin, :audio_url, :thumbnail_url, :category, :subcategory, :difficulty, :duration_seconds, :is_premium)";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':title_ol_chiki', $data['title_ol_chiki']);
        $stmt->bindParam(':title_latin', $data['title_latin']);
        $stmt->bindParam(':content_ol_chiki', $data['content_ol_chiki']);
        $stmt->bindParam(':content_latin', $data['content_latin']);
        $stmt->bindParam(':audio_url', $data['audio_url']);
        $stmt->bindParam(':thumbnail_url', $data['thumbnail_url']);
        $stmt->bindParam(':category', $data['category']);
        $stmt->bindParam(':subcategory', $data['subcategory']);
        $stmt->bindParam(':difficulty', $data['difficulty']);
        $stmt->bindParam(':duration_seconds', $data['duration_seconds']);
        $stmt->bindValue(':is_premium', getField($data, 'is_premium', false) ? 1 : 0, PDO::PARAM_INT);

        if($stmt->execute()) {
            sendResponse("Rhyme created successfully", 201);
        } else {
            sendResponse(null, 500, "Failed to create rhyme");
        }
        break;

    case 'PUT':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        if (!isset($data['id'])) sendResponse(null, 400, "Missing ID");

        $query = "UPDATE rhymes SET 
                  title_ol_chiki = :title_ol_chiki, 
                  title_latin = :title_latin, 
                  content_ol_chiki = :content_ol_chiki, 
                  content_latin = :content_latin, 
                  audio_url = :audio_url, 
                  thumbnail_url = :thumbnail_url,
                  category = :category,
                  subcategory = :subcategory,
                  difficulty = :difficulty,
                  duration_seconds = :duration_seconds,
                  is_premium = :is_premium
                  WHERE id = :id";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':title_ol_chiki', $data['title_ol_chiki']);
        $stmt->bindParam(':title_latin', $data['title_latin']);
        $stmt->bindParam(':content_ol_chiki', $data['content_ol_chiki']);
        $stmt->bindParam(':content_latin', $data['content_latin']);
        $stmt->bindParam(':audio_url', $data['audio_url']);
        $stmt->bindParam(':thumbnail_url', $data['thumbnail_url']);
        $stmt->bindParam(':category', $data['category']);
        $stmt->bindParam(':subcategory', $data['subcategory']);
        $stmt->bindParam(':difficulty', $data['difficulty']);
        $stmt->bindParam(':duration_seconds', $data['duration_seconds']);
        $stmt->bindValue(':is_premium', getField($data, 'is_premium', false) ? 1 : 0, PDO::PARAM_INT);

        if($stmt->execute()) {
            sendResponse("Rhyme updated successfully");
        } else {
            sendResponse(null, 500, "Failed to update rhyme");
        }
        break;

    case 'DELETE':
        $id = isset($_GET['id']) ? $_GET['id'] : null;
        if (!$id) sendResponse(null, 400, "Missing ID");

        $query = "DELETE FROM rhymes WHERE id = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':id', $id);

        if($stmt->execute()) {
            sendResponse("Rhyme deleted successfully");
        } else {
            sendResponse(null, 500, "Failed to delete rhyme");
        }
        break;
}
?>
