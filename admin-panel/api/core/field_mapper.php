<?php
/**
 * Field Mapper Utility
 * Converts between snake_case (DB columns) and camelCase (API/Flutter)
 * 
 * Special rename maps handle cases where the DB column name
 * doesn't directly map via simple case conversion.
 */

// Special renames: DB column => API key (where simple snake_to_camel isn't enough)
$FIELD_RENAMES_TO_CAMEL = [
    'order_index'     => 'order',
    'usage_example'   => 'usage',
    'example_word'    => 'exampleWordOlChiki',
    'lottie_url'      => 'animationUrl',
    'action_url'      => 'targetRoute',
    'content_json'    => 'contentJson',
];

// Reverse map: API key => DB column
$FIELD_RENAMES_TO_SNAKE = [];
foreach ($FIELD_RENAMES_TO_CAMEL as $snake => $camel) {
    $FIELD_RENAMES_TO_SNAKE[$camel] = $snake;
}

/**
 * Convert a snake_case string to camelCase
 */
function snakeToCamelStr($str) {
    return lcfirst(str_replace('_', '', ucwords($str, '_')));
}

/**
 * Convert a camelCase string to snake_case
 */
function camelToSnakeStr($str) {
    return strtolower(preg_replace('/[A-Z]/', '_$0', $str));
}

/**
 * Transform a single DB row (snake_case keys) to API response (camelCase keys)
 * Applies special renames first, then generic snake_to_camel conversion
 */
function mapRowToCamel($row) {
    global $FIELD_RENAMES_TO_CAMEL;
    $result = [];
    
    foreach ($row as $key => $value) {
        if (isset($FIELD_RENAMES_TO_CAMEL[$key])) {
            $newKey = $FIELD_RENAMES_TO_CAMEL[$key];
        } else {
            $newKey = snakeToCamelStr($key);
        }
        $result[$newKey] = $value;
    }
    
    return $result;
}

/**
 * Transform an array of DB rows to camelCase
 */
function mapRowsToCamel($rows) {
    return array_map('mapRowToCamel', $rows);
}

/**
 * Transform API input (camelCase keys) to DB columns (snake_case keys)
 * Applies special renames first, then generic camel_to_snake conversion
 */
function mapInputToSnake($data) {
    global $FIELD_RENAMES_TO_SNAKE;
    $result = [];
    
    foreach ($data as $key => $value) {
        if (isset($FIELD_RENAMES_TO_SNAKE[$key])) {
            $newKey = $FIELD_RENAMES_TO_SNAKE[$key];
        } else {
            $newKey = camelToSnakeStr($key);
        }
        $result[$newKey] = $value;
    }
    
    return $result;
}

/**
 * Helper: safely get a value from data with fallback
 */
function getField($data, $key, $default = null) {
    return isset($data[$key]) ? $data[$key] : $default;
}
?>
