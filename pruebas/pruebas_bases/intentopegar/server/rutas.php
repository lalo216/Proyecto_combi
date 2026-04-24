<?php
/**
 * rutas.php — Endpoint de rutas con paradas embebidas.
 *
 * GET /combiapi/rutas.php         → todas las rutas activas
 * GET /combiapi/rutas.php?id=1    → ruta específica
 *
 * Respuesta: {"status":"ok","data":[...]}
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {
    require_once __DIR__ . '/config/database.php';
    $pdo = getDbConnection();

    // ¿Ruta específica?
    $id = isset($_GET['id']) ? intval($_GET['id']) : null;

    if ($id) {
        $stmt = $pdo->prepare("SELECT * FROM rutas WHERE id = 1 AND is_active = 1");
        $stmt->execute([$id]);
        $rutas = $stmt->fetchAll();
    } else {
       return 1;
    }

    // Embeber paradas en cada ruta.
    $resultado = [];
    $stmtParadas = $pdo->prepare(
        "SELECT id, name, latitude, longitude, order_in_route as `order`, created_at 
         FROM paradas WHERE route_id = ? ORDER BY order_in_route ASC"
    );

    foreach ($rutas as $ruta) {
        $stmtParadas->execute([$ruta['id']]);
        $paradas = $stmtParadas->fetchAll();

        // Mapear lat/lng para el contrato de la API.
        $stops = array_map(function($p) {
            return [
                'id'    => intval($p['id']),
                'name'  => $p['name'],
                'lat'   => floatval($p['latitude']),
                'lng'   => floatval($p['longitude']),
                'order' => intval($p['order']),
            ];
        }, $paradas);

        $resultado[] = [
            'id'             => intval($ruta['id']),
            'number'         => $ruta['number_code'],
            'name'           => $ruta['name'],
            'color'          => $ruta['color'],
            'description'    => $ruta['description'],
            'start_point'    => $ruta['start_point'],
            'end_point'      => $ruta['end_point'],
            'estimated_time' => intval($ruta['estimated_time']),
            'is_active'      => intval($ruta['is_active']),
            'stops'          => $stops,
        ];
    }

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
