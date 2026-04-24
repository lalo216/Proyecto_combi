<?php
/**
 * paradas.php — Endpoint de paradas.
 *
 * GET /combiapi/paradas.php              → todas las paradas
 * GET /combiapi/paradas.php?ruta_id=1    → paradas de una ruta específica
 *
 * Respuesta: {"status":"ok","data":[...]}
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {
    require_once __DIR__ . '/config/database.php';
    $pdo = getDbConnection();

    $rutaId = isset($_GET['ruta_id']) ? intval($_GET['ruta_id']) : null;

    if ($rutaId) {
        $stmt = $pdo->prepare(
            "SELECT p.id, p.name, p.latitude, p.longitude, p.order_in_route as `order`,
                    r.number_code as ruta_number, r.name as ruta_name, r.color as ruta_color
             FROM paradas p
             JOIN rutas r ON p.route_id = r.id
             WHERE p.route_id = ?
             ORDER BY p.order_in_route ASC"
        );
        $stmt->execute([$rutaId]);
    } else {
        $stmt = $pdo->query(
            "SELECT p.id, p.name, p.latitude, p.longitude, p.order_in_route as `order`,
                    r.number_code as ruta_number, r.name as ruta_name, r.color as ruta_color
             FROM paradas p
             JOIN rutas r ON p.route_id = r.id
             ORDER BY r.number_code, p.order_in_route ASC"
        );
    }

    $paradas = $stmt->fetchAll();

    $resultado = array_map(function($p) {
        return [
            'id'          => intval($p['id']),
            'name'        => $p['name'],
            'lat'         => floatval($p['latitude']),
            'lng'         => floatval($p['longitude']),
            'order'       => intval($p['order']),
            'ruta_number' => $p['ruta_number'],
            'ruta_name'   => $p['ruta_name'],
            'ruta_color'  => $p['ruta_color'],
        ];
    }, $paradas);

    echo json_encode([
        'status' => 'ok',
        'data'   => $resultado,
        'count'  => count($resultado),
    ], JSON_PRETTY_PRINT);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status'  => 'error',
        'message' => $e->getMessage(),
    ]);
}
