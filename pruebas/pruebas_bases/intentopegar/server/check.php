<?php
// check.php
require_once __DIR__ . '/common/bootstrap.php';
require_once __DIR__ . '/common/db.php';

// Only accept GET
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendJson(405, 'error', null, 'Method not allowed');
}

$health = [
    'server' => [
        'hostname'    => gethostname(),
        'php_version' => PHP_VERSION,
        'timestamp'   => date('c'),
    ],
    'sqlite'  => ['status' => 'unknown', 'row_count' => null],
    'mysql'   => ['status' => 'unknown'],
];

// --- SQLite check ---
try {
    $sqlite = getSqliteConnection();
    $stmt   = $sqlite->query('SELECT COUNT(*) AS c FROM rutas');
    $row    = $stmt->fetch();
    $health['sqlite'] = [
        'status'    => 'ok',
        'row_count' => (int) $row['c'],
    ];
} catch (Exception $e) {
    $health['sqlite'] = [
        'status'  => 'error',
        'detail'  => 'SQLite unreachable',   // Never expose $e->getMessage() externally
    ];
}

// --- MySQL check ---
try {
    $mysql = getMysqlConnection();
    $mysql->query('SELECT 1');
    $health['mysql'] = ['status' => 'ok'];
} catch (Exception $e) {
    $health['mysql'] = [
        'status' => 'error',
        'detail' => 'MySQL unreachable',
    ];
}

// Derive overall status: ok only if SQLite is reachable (MySQL is optional in V1)
$overallStatus = ($health['sqlite']['status'] === 'ok') ? 'ok' : 'degraded';

sendJson(200, $overallStatus, $health);
