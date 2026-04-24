import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://localhost/beta";

  Future<List<dynamic>> getParadasPorRuta(int rutaId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api_ruta.php?id=$rutaId"),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["paradas"];
    } else {
      throw Exception("Error al obtener paradas");
    }
  }
}
