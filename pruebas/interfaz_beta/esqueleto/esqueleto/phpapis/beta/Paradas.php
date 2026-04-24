<?php
class Paradas {
    private $conn;
    private $table_name = "paradas";

    public function __construct($db) {
        $this->conn = $db;
    }

    public function obtenerParadaPorId($id) {
        $query = "SELECT id, nombre, latitud, longitud 
                  FROM " . $this->table_name . " 
                  WHERE id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":id", $id);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
}
?>
