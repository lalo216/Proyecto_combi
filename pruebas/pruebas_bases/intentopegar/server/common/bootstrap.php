<?php

if (ob_get_level() === 0) ob_start();

error_reporting(E_ALL);
ini_set('display_errors', '0');
ini_set('log_errors', '1');

header('Content-Type: application/json; charset=UTF-8');
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function sendJson(int $httpCode, string $status, $data = null, string $message = ''): void {
    http_response_code($httpCode);
    $payload = [
        'status' => $status,
        'data'   => $data,
        'meta'   => [
            'timestamp' => date('c'),
            'version'   => '1.0',
        ],
    ];
    if ($message !== '') {
        $payload['message'] = $message;
    }
    ob_end_clean();
    echo json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    exit;
}

// 6. Fatal error catcher — returns JSON instead of HTML
register_shutdown_function(function () {
    $error = error_get_last();
    if ($error && in_array($error['type'], [E_ERROR, E_PARSE, E_CORE_ERROR])) {
        if (!headers_sent()) {
            header('Content-Type: application/json; charset=UTF-8');
            http_response_code(500);
        }
        echo json_encode(['status' => 'error', 'message' => 'Internal server error']);
    }
});

define('SQLITE_PATH', __DIR__ . '/../db/combis_cache.db');
define('MYSQL_HOST', '127.0.0.1');
define('MYSQL_PORT', '3306');
define('MYSQL_DBNAME', 'combis_db');
define('MYSQL_USER', 'combis_api');      // Solo debe tener acceso a SELECT, INSERT y UPDATE, esto es buena seguridad
define('MYSQL_PASS', 'CHANGE_ME');       // Debe ser movida a una variable ambiental afuera del directorio donde esta.
function getSqliteConnection(): PDO {
    try {
        $pdo = new PDO('sqlite:' . SQLITE_PATH);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        $pdo->exec('PRAGMA journal_mode=WAL;');  // Safe concurrent reads
        $pdo->exec('PRAGMA foreign_keys=ON;');
        return $pdo;
    } catch (PDOException $e) {
        // Log full error, return generic message
        error_log('SQLite connection failed: ' . $e->getMessage());
        throw new RuntimeException('Database unavailable');
    }
}

function getMysqlConnection(): PDO {
    try {
        $dsn = sprintf(
            'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
            MYSQL_HOST, MYSQL_PORT, MYSQL_DBNAME
        );
        $pdo = new PDO($dsn, MYSQL_USER, MYSQL_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
        return $pdo;
    } catch (PDOException $e) {
        error_log('MySQL connection failed: ' . $e->getMessage());
        throw new RuntimeException('Database unavailable');
    }
}