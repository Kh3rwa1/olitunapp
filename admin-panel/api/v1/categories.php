<?php
/**
 * Categories API Endpoint
 */

require_once '../core/db.php';
require_once '../core/response.php';
require_once '../core/field_mapper.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        $stmt = $db->prepare("SELECT * FROM categories ORDER BY order_index ASC");
        $stmt->execute();
        $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach($categories as &$cat) {
            $cat['is_active'] = (bool)$cat['is_active'];
            $cat['order_index'] = (int)$cat['order_index'];
            $cat['total_lessons'] = (int)$cat['total_lessons'];
        }
        
        sendResponse(mapRowsToCamel($categories));
        break;

    case 'POST':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        
        if (!isset($data['id']) || !isset($data['title_latin'])) {
            sendResponse(null, 400, "Missing required fields");
        }

        $stmt = $db->prepare("INSERT INTO categories 
                  (id, title_ol_chiki, title_latin, icon_name, icon_url, lottie_url, gradient_preset, order_index, is_active, total_lessons, description) 
                  VALUES 
                  (:id, :title_ol_chiki, :title_latin, :icon_name, :icon_url, :lottie_url, :gradient_preset, :order_index, :is_active, :total_lessons, :description)");
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':title_ol_chiki', $data['title_ol_chiki']);
        $stmt->bindParam(':title_latin', $data['title_latin']);
        $stmt->bindParam(':icon_name', $data['icon_name']);
        $stmt->bindParam(':icon_url', $data['icon_url']);
        $stmt->bindParam(':lottie_url', $data['lottie_url']);
        $stmt->bindParam(':gradient_preset', $data['gradient_preset']);
        $stmt->bindParam(':order_index', $data['order_index']);
        $stmt->bindValue(':is_active', getField($data, 'is_active', true) ? 1 : 0, PDO::PARAM_INT);
        $stmt->bindParam(':total_lessons', $data['total_lessons']);
        $stmt->bindParam(':description', $data['description']);

        if($stmt->execute()) {
            sendResponse("Category created successfully", 201);
        } else {
            sendResponse(null, 500, "Failed to create category");
        }
        break;

    case 'PUT':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        
        if (!isset($data['id'])) {
            sendResponse(null, 400, "Missing ID");
        }

        $stmt = $db->prepare("UPDATE categories SET 
                  title_ol_chiki = :title_ol_chiki, 
                  title_latin = :title_latin, 
                  icon_name = :icon_name, 
                  icon_url = :icon_url,
                  lottie_url = :lottie_url,
                  gradient_preset = :gradient_preset, 
                  order_index = :order_index, 
                  is_active = :is_active, 
                  total_lessons = :total_lessons,
                  description = :description
                  WHERE id = :id");
        
        $stmt->bindParam(':id', $data['id']);
        $stmt->bindParam(':title_ol_chiki', $data['title_ol_chiki']);
        $stmt->bindParam(':title_latin', $data['title_latin']);
        $stmt->bindParam(':icon_name', $data['icon_name']);
        $stmt->bindParam(':icon_url', $data['icon_url']);
        $stmt->bindParam(':lottie_url', $data['lottie_url']);
        $stmt->bindParam(':gradient_preset', $data['gradient_preset']);
        $stmt->bindParam(':order_index', $data['order_index']);
        $stmt->bindValue(':is_active', getField($data, 'is_active', true) ? 1 : 0, PDO::PARAM_INT);
        $stmt->bindParam(':total_lessons', $data['total_lessons']);
        $stmt->bindParam(':description', $data['description']);

        if($stmt->execute()) {
            sendResponse("Category updated successfully");
        } else {
            sendResponse(null, 500, "Failed to update category");
        }
        break;

    case 'DELETE':
        $id = isset($_GET['id']) ? $_GET['id'] : null;
        
        if (!$id) {
            sendResponse(null, 400, "Missing ID parameter");
        }

        $stmt = $db->prepare("DELETE FROM categories WHERE id = :id");
        $stmt->bindParam(':id', $id);

        if($stmt->execute()) {
            sendResponse("Category deleted successfully");
        } else {
            sendResponse(null, 500, "Failed to delete category");
        }
        break;
}
?>
