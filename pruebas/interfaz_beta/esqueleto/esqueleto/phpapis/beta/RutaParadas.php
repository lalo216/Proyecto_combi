<?php
class RutaParadas {
    private $conn;
    private $table_name = "rutas_paradas";

    public function __construct($db) {
        $this->conn = $db;
    }

    public function obtenerParadasPorRuta($ruta_id) {
        $query = "SELECT parada_id, orden 
                  FROM " . $this->table_name . " 
                  WHERE ruta_id = :ruta_id 
                  ORDER BY orden ASC";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":ruta_id", $ruta_id);
        $stmt->execute();
        return $stmt;
    }
}
?>
