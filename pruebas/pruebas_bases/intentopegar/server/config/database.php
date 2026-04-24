<?php
/**
 * database.php — Conexión PDO a MySQL.
 *
 * Centraliza la conexión para que todos los endpoints la reusen.
 * Cambiar las credenciales según tu entorno.
 */

function getDbConnection(): PDO {
    $host = 'localhost';
    $db   = 'combis_db';
    $user = 'combis_user';    // Crear este usuario en MySQL
    $pass = 'combis_pass';    // Cambiar en producción
    $charset = 'utf8mb4';

    $dsn = "mysql:host=$host;dbname=$db;charset=$charset";
    $options = [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ];

    return new PDO($dsn, $user, $pass, $options);
}
