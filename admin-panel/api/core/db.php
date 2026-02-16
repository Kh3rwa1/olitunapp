<?php
/**
 * Database Configuration
 * Hostinger MySQL Connection
 */

class Database {
    // Hostinger settings - to be updated by user on deployment
    private $host = "localhost";
    private $db_name = "u236276440_olitun";
    private $username = "u236276440_olitun";
    private $password = "Heysusanta@2025";
    public $conn;

    public function getConnection() {
        $this->conn = null;

        try {
            $this->conn = new PDO("mysql:host=" . $this->host . ";dbname=" . $this->db_name, $this->username, $this->password);
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conn->exec("set names utf8mb4");
        } catch(PDOException $exception) {
            // In production, log this instead of showing full error
            error_log("Connection error: " . $exception->getMessage());
            echo json_encode(["message" => "Database connection error."]);
            exit;
        }

        return $this->conn;
    }
}
?>
