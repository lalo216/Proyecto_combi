import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> testConnection() async {
  try {
    final response = await http.get(Uri.parse("http://localhost/api/test.php"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return "✅ ${data['message']}";
    } else {
      return "❌ Error HTTP: ${response.statusCode}";
    }
  } catch (e) {
    return "❌ Error de conexión: $e";
  }
}
