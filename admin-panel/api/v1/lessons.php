<?php
/**
 * Lessons API Endpoint
 * Handles Lessons AND Lesson Blocks
 */

require_once '../core/db.php';
require_once '../core/response.php';
require_once '../core/field_mapper.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        // Optional: Filter by category_id
        $categoryId = isset($_GET['category_id']) ? $_GET['category_id'] : null;
        // Optional: Get single lesson details with blocks
        $lessonId = isset($_GET['id']) ? $_GET['id'] : null;

        if ($lessonId) {
            // Get single lesson
            $stmt = $db->prepare("SELECT * FROM lessons WHERE id = :id");
            $stmt->bindParam(':id', $lessonId);
            $stmt->execute();
            $lesson = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($lesson) {
                // Get blocks for this lesson
                $blockStmt = $db->prepare("SELECT * FROM lesson_blocks WHERE lesson_id = :lesson_id ORDER BY order_index ASC");
                $blockStmt->bindParam(':lesson_id', $lessonId);
                $blockStmt->execute();
                $blocks = $blockStmt->fetchAll(PDO::FETCH_ASSOC);

                // Decode JSON content and flatten onto block
                foreach($blocks as &$block) {
                    $decoded = json_decode($block['content_json'], true);
                    // Unwrap any nesting: {type, contentJson: {textOlChiki...}} -> {textOlChiki...}
                    if (is_array($decoded)) {
                        if (isset($decoded['contentJson']) && is_array($decoded['contentJson'])) {
                            $decoded = $decoded['contentJson'];
                        }
                        // Merge content fields directly onto block
                        foreach ($decoded as $key => $val) {
                            if ($key !== 'type') {
                                $block[$key] = $val;
                            }
                        }
                    }
                    unset($block['content_json']);
                }

                $lesson['blocks'] = mapRowsToCamel($blocks);
                
                // Type casting
                $lesson['is_active'] = (bool)$lesson['is_active'];
                $lesson['is_premium'] = (bool)$lesson['is_premium'];
                $lesson['order_index'] = (int)$lesson['order_index'];
                $lesson['estimated_minutes'] = (int)$lesson['estimated_minutes'];

                sendResponse(mapRowToCamel($lesson));
            } else {
                sendResponse(null, 404, "Lesson not found");
            }
        } else {
            // List lessons
            if ($categoryId) {
                $stmt = $db->prepare("SELECT * FROM lessons WHERE category_id = :category_id ORDER BY order_index ASC");
                $stmt->bindParam(':category_id', $categoryId);
            } else {
                $stmt = $db->prepare("SELECT * FROM lessons ORDER BY order_index ASC");
            }
            $stmt->execute();
            $lessons = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            foreach($lessons as &$lesson) {
                $blockStmt = $db->prepare("SELECT * FROM lesson_blocks WHERE lesson_id = :lesson_id ORDER BY order_index ASC");
                $blockStmt->bindParam(':lesson_id', $lesson['id']);
                $blockStmt->execute();
                $blocks = $blockStmt->fetchAll(PDO::FETCH_ASSOC);

                foreach($blocks as &$block) {
                    $decoded = json_decode($block['content_json'], true);
                    if (is_array($decoded)) {
                        if (isset($decoded['contentJson']) && is_array($decoded['contentJson'])) {
                            $decoded = $decoded['contentJson'];
                        }
                        foreach ($decoded as $key => $val) {
                            if ($key !== 'type') {
                                $block[$key] = $val;
                            }
                        }
                    }
                    unset($block['content_json']);
                }

                $lesson['blocks'] = mapRowsToCamel($blocks);
                
                $lesson['is_active'] = (bool)$lesson['is_active'];
                $lesson['is_premium'] = (bool)$lesson['is_premium'];
                $lesson['order_index'] = (int)$lesson['order_index'];
                $lesson['estimated_minutes'] = (int)$lesson['estimated_minutes'];
            }

            sendResponse(mapRowsToCamel($lessons));
        }
        break;

    case 'POST':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        
        if (!isset($data['id']) || !isset($data['category_id']) || !isset($data['title_latin'])) {
            sendResponse(null, 400, "Missing required fields");
        }

        try {
            $db->beginTransaction();

            // Insert Lesson
            $stmt = $db->prepare("INSERT INTO lessons 
                      (id, category_id, title_ol_chiki, title_latin, level, order_index, is_active, estimated_minutes, description, thumbnail_url, is_premium) 
                      VALUES 
                      (:id, :category_id, :title_ol_chiki, :title_latin, :level, :order_index, :is_active, :estimated_minutes, :description, :thumbnail_url, :is_premium)");
            
            $stmt->bindParam(':id', $data['id']);
            $stmt->bindParam(':category_id', $data['category_id']);
            $stmt->bindParam(':title_ol_chiki', $data['title_ol_chiki']);
            $stmt->bindParam(':title_latin', $data['title_latin']);
            $stmt->bindParam(':level', $data['level']);
            $stmt->bindParam(':order_index', $data['order_index']);
            $stmt->bindValue(':is_active', getField($data, 'is_active', true) ? 1 : 0, PDO::PARAM_INT);
            $stmt->bindParam(':estimated_minutes', $data['estimated_minutes']);
            $stmt->bindParam(':description', $data['description']);
            $stmt->bindParam(':thumbnail_url', $data['thumbnail_url']);
            $stmt->bindValue(':is_premium', getField($data, 'is_premium', false) ? 1 : 0, PDO::PARAM_INT);

            $stmt->execute();

            // Insert Blocks if present
            if (isset($raw['blocks']) && is_array($raw['blocks'])) {
                $blockStmt = $db->prepare("INSERT INTO lesson_blocks (id, lesson_id, type, content_json, order_index) VALUES (:id, :lesson_id, :type, :content_json, :order_index)");

                foreach($raw['blocks'] as $i => $block) {
                    $blockId = isset($block['id']) ? $block['id'] : uniqid('blk_');
                    // Store only the content payload, not the whole block with type
                    $contentPayload = isset($block['contentJson']) ? $block['contentJson'] : $block;
                    unset($contentPayload['type'], $contentPayload['id']);
                    $contentJson = json_encode($contentPayload);

                    $blockStmt->bindParam(':id', $blockId);
                    $blockStmt->bindParam(':lesson_id', $data['id']);
                    $blockStmt->bindParam(':type', $block['type']);
                    $blockStmt->bindParam(':content_json', $contentJson);
                    $blockStmt->bindValue(':order_index', $i, PDO::PARAM_INT);
                    $blockStmt->execute();
                }
            }

            $db->commit();
            sendResponse("Lesson created successfully", 201);

        } catch (Exception $e) {
            $db->rollBack();
            sendResponse(null, 500, "Failed to create lesson: " . $e->getMessage());
        }
        break;

    case 'PUT':
        $raw = getJsonInput();
        $data = mapInputToSnake($raw);
        
        if (!isset($data['id'])) {
            sendResponse(null, 400, "Missing ID");
        }

        try {
            $db->beginTransaction();

            // Update Lesson
            $stmt = $db->prepare("UPDATE lessons SET 
                      category_id = :category_id, 
                      title_ol_chiki = :title_ol_chiki, 
                      title_latin = :title_latin, 
                      level = :level, 
                      order_index = :order_index, 
                      is_active = :is_active, 
                      estimated_minutes = :estimated_minutes,
                      description = :description,
                      thumbnail_url = :thumbnail_url,
                      is_premium = :is_premium
                      WHERE id = :id");
            
            $stmt->bindParam(':id', $data['id']);
            $stmt->bindParam(':category_id', $data['category_id']);
            $stmt->bindParam(':title_ol_chiki', $data['title_ol_chiki']);
            $stmt->bindParam(':title_latin', $data['title_latin']);
            $stmt->bindParam(':level', $data['level']);
            $stmt->bindParam(':order_index', $data['order_index']);
            $stmt->bindValue(':is_active', getField($data, 'is_active', true) ? 1 : 0, PDO::PARAM_INT);
            $stmt->bindParam(':estimated_minutes', $data['estimated_minutes']);
            $stmt->bindParam(':description', $data['description']);
            $stmt->bindParam(':thumbnail_url', $data['thumbnail_url']);
            $stmt->bindValue(':is_premium', getField($data, 'is_premium', false) ? 1 : 0, PDO::PARAM_INT);

            $stmt->execute();

            // Update blocks: Delete all and re-insert
            if (isset($raw['blocks']) && is_array($raw['blocks'])) {
                // Delete existing
                $delStmt = $db->prepare("DELETE FROM lesson_blocks WHERE lesson_id = :lesson_id");
                $delStmt->bindParam(':lesson_id', $data['id']);
                $delStmt->execute();

                // Re-insert
                $blockStmt = $db->prepare("INSERT INTO lesson_blocks (id, lesson_id, type, content_json, order_index) VALUES (:id, :lesson_id, :type, :content_json, :order_index)");

                foreach($raw['blocks'] as $i => $block) {
                    $blockId = isset($block['id']) ? $block['id'] : uniqid('blk_');
                    $contentPayload = isset($block['contentJson']) ? $block['contentJson'] : $block;
                    unset($contentPayload['type'], $contentPayload['id']);
                    $contentJson = json_encode($contentPayload);

                    $blockStmt->bindParam(':id', $blockId);
                    $blockStmt->bindParam(':lesson_id', $data['id']);
                    $blockStmt->bindParam(':type', $block['type']);
                    $blockStmt->bindParam(':content_json', $contentJson);
                    $blockStmt->bindValue(':order_index', $i, PDO::PARAM_INT);
                    $blockStmt->execute();
                }
            }

            $db->commit();
            sendResponse("Lesson updated successfully");

        } catch (Exception $e) {
            $db->rollBack();
            sendResponse(null, 500, "Failed to update lesson: " . $e->getMessage());
        }
        break;

    case 'DELETE':
        $id = isset($_GET['id']) ? $_GET['id'] : null;
        
        if (!$id) {
            sendResponse(null, 400, "Missing ID parameter");
        }

        // Blocks cascade delete automatically via foreign key
        $stmt = $db->prepare("DELETE FROM lessons WHERE id = :id");
        $stmt->bindParam(':id', $id);

        if($stmt->execute()) {
            sendResponse("Lesson deleted successfully");
        } else {
            sendResponse(null, 500, "Failed to delete lesson");
        }
        break;
}
?>
