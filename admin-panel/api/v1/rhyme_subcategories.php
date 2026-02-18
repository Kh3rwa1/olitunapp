<?php
/**
 * Rhyme Subcategories API Endpoint
 */

require_once '../core/db.php';
require_once '../core/response.php';
require_once '../core/field_mapper.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        $catId = isset($_GET['categoryId']) ? $_GET['categoryId'] : null;
        if ($catId) {
            $query = "SELECT * FROM rhyme_subcategories WHERE category_id = :category_id ORDER BY order_index ASC";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':category_id', $catId);
        } else {
            $query = "SELECT * FROM rhyme_subcategories ORDER BY order_index ASC";
            $stmt = $db->prepare($query);
        }
        $stmt->execute();
        $subcategories = $stmt->fetchAll(PDO::FETCH_ASSOC);
        sendResponse(mapRowsToCamel($subcategories));
        break;

    case 'POST':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        
        if (!isset($data['id']) || !isset($data['category_id']) || !isset($data['name_latin'])) {
            sendResponse(null, 400, "Missing required fields");
        }

        $query = "INSERT INTO rhyme_subcategories 
                  (id, category_id, name_ol_chiki, name_latin, order_index) 
                  VALUES 
                  (:id, :category_id, :name_ol_chiki, :name_latin, :order_index)";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':category_id', $data['category_id']);
        $stmt->bindParam(':name_ol_chiki', $data['name_ol_chiki']);
        $stmt->bindParam(':name_latin', $data['name_latin']);
        $stmt->bindParam(':order_index', $data['order_index']);

        if($stmt->execute()) {
            sendResponse("Subcategory created successfully", 201);
        } else {
            sendResponse(null, 500, "Failed to create subcategory");
        }
        break;

    case 'PUT':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        if (!isset($data['id'])) sendResponse(null, 400, "Missing ID");

        $query = "UPDATE rhyme_subcategories SET 
                  category_id = :category_id,
                  name_ol_chiki = :name_ol_chiki, 
                  name_latin = :name_latin, 
                  order_index = :order_index
                  WHERE id = :id";
        
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':category_id', $data['category_id']);
        $stmt->bindParam(':name_ol_chiki', $data['name_ol_chiki']);
        $stmt->bindParam(':name_latin', $data['name_latin']);
        $stmt->bindParam(':order_index', $data['order_index']);

        if($stmt->execute()) {
            sendResponse("Subcategory updated successfully");
        } else {
            sendResponse(null, 500, "Failed to update subcategory");
        }
        break;

    case 'DELETE':
        $id = isset($_GET['id']) ? $_GET['id'] : null;
        if (!$id) sendResponse(null, 400, "Missing ID");

        $query = "DELETE FROM rhyme_subcategories WHERE id = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':id', $id);

        if($stmt->execute()) {
            sendResponse("Subcategory deleted successfully");
        } else {
            sendResponse(null, 500, "Failed to delete subcategory");
        }
        break;
}
?>
