<?php
/**
 * Rhyme Categories API Endpoint
 */

require_once '../core/db.php';
require_once '../core/response.php';
require_once '../core/field_mapper.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        $query = "SELECT * FROM rhyme_categories ORDER BY order_index ASC";
        $stmt = $db->prepare($query);
        $stmt->execute();
        $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);
        sendResponse(mapRowsToCamel($categories));
        break;

    case 'POST':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        
        if (!isset($data['id']) || !isset($data['name_latin'])) {
            sendResponse(null, 400, "Missing required fields");
        }

        $query = "INSERT INTO rhyme_categories 
                  (id, name_ol_chiki, name_latin, icon_name, order_index) 
                  VALUES 
                  (:id, :name_ol_chiki, :name_latin, :icon_name, :order_index)";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':name_ol_chiki', $data['name_ol_chiki']);
        $stmt->bindParam(':name_latin', $data['name_latin']);
        $stmt->bindParam(':icon_name', $data['icon_name']);
        $stmt->bindParam(':order_index', $data['order_index']);

        if($stmt->execute()) {
            sendResponse("Category created successfully", 201);
        } else {
            sendResponse(null, 500, "Failed to create category");
        }
        break;

    case 'PUT':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        if (!isset($data['id'])) sendResponse(null, 400, "Missing ID");

        $query = "UPDATE rhyme_categories SET 
                  name_ol_chiki = :name_ol_chiki, 
                  name_latin = :name_latin, 
                  icon_name = :icon_name,
                  order_index = :order_index
                  WHERE id = :id";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':name_ol_chiki', $data['name_ol_chiki']);
        $stmt->bindParam(':name_latin', $data['name_latin']);
        $stmt->bindParam(':icon_name', $data['icon_name']);
        $stmt->bindParam(':order_index', $data['order_index']);

        if($stmt->execute()) {
            sendResponse("Category updated successfully");
        } else {
            sendResponse(null, 500, "Failed to update category");
        }
        break;

    case 'DELETE':
        $id = isset($_GET['id']) ? $_GET['id'] : null;
        if (!$id) sendResponse(null, 400, "Missing ID");

        $query = "DELETE FROM rhyme_categories WHERE id = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':id', $id);

        if($stmt->execute()) {
            sendResponse("Category deleted successfully");
        } else {
            sendResponse(null, 500, "Failed to delete category");
        }
        break;
}
?>
