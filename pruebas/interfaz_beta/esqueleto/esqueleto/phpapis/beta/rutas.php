<?php
header("Access-Control-Allow-Origin: *"); // Permite cualquier origen
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");
// Conexión a la base de datos
$servername = "localhost";
$username = "root"; // usuario por defecto en XAMPP
$password = "";     // contraseña vacía por defecto
$dbname = "transporte";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Error de conexión: " . $conn->connect_error);
}


// Obtener todos los registros
$sql = "SELECT * FROM ruta";
$result = $conn->query($sql);

$rutas = array();
while($row = $result->fetch_assoc()) {
    $rutas[] = $row;
}

// Devolver en formato JSON
header('Content-Type: application/json');
echo json_encode($rutas);

$conn->close();
?>
