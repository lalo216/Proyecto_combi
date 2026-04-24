<?php
// Permitir acceso desde cualquier origen (puedes restringirlo a tu dominio si quieres)
header("Access-Control-Allow-Origin: *");

// Permitir métodos HTTP
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");

// Permitir ciertos headers
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Responder rápido a preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Tipo de contenido JSON
header("Content-Type: application/json; charset=UTF-8");


include_once 'Database.php';
include_once 'RutaParadas.php';
include_once 'Paradas.php';

$db = (new Database())->getConnection();
$rutaParadas = new RutaParadas($db);
$paradasObj = new Paradas($db);

if (!isset($_GET['id'])) {
    echo json_encode(["error" => "Falta el parámetro id"]);
    exit;
}

$ruta_id = intval($_GET['id']);
$stmt = $rutaParadas->obtenerParadasPorRuta($ruta_id);

$paradas = [];
while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    $parada = $paradasObj->obtenerParadaPorId($row['parada_id']);
    // Conversión explícita a float y entero
    $parada['latitud'] = (float)$parada['latitud'];
    $parada['longitud'] = (float)$parada['longitud'];
    $parada['orden'] = (int)$row['orden'];
    $paradas[] = $parada;
}


echo json_encode([
    "ruta_id" => $ruta_id,
    "paradas" => $paradas
]);
?>
