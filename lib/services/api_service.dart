import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://backend-00.netlify.app/api';
  static const String apiKey = 'TU_API_KEY';

  Future<List<Map<String, dynamic>>> getEvents({String? category}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events?category=$category'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Error al cargar eventos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al conectar con la API: $e');
    }
  }

  Future<void> toggleFavorite(String eventId, bool isFavorite) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'isFavorite': isFavorite,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar favorito: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar favorito: $e');
    }
  }

  Future<void> shareEvent(String eventId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/share/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error al compartir evento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al compartir evento: $e');
    }
  }
}
