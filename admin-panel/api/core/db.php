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
    private $password;
    public $conn;

    public function __construct() {
        $this->password = getenv('DB_PASSWORD') ?: '';
    }

    public function getConnection() {
        $this->conn = null;

        try {
            if ($this->password === '') {
                throw new PDOException("Database password is not configured");
            }
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8mb4",
                $this->username,
                $this->password
            );
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
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
