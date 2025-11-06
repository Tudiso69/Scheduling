import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const storage = FlutterSecureStorage();


  // ✅ Ajouter cette méthode dans la classe ApiService
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'users': data['users']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }


  // Auth methods (identiques à avant mais avec 'numero' au lieu de 'telephone')
  static Future<Map<String, dynamic>> register({
    required String numero,
    required String nom,
    String? prenom,
    required String fonction,
    String? email,
    String? telephone,
    required String motDePasse,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'numero': numero,
          'nom': nom,
          'prenom': prenom,
          'fonction': fonction,
          'email': email,
          'telephone': telephone,
          'mot_de_passe': motDePasse,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await storage.write(key: 'token', value: data['token']);
        await storage.write(key: 'user', value: jsonEncode(data['user']));
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur d\'inscription'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String numero,
    required String motDePasse,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'numero': numero,
          'mot_de_passe': motDePasse,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await storage.write(key: 'token', value: data['token']);
        await storage.write(key: 'user', value: jsonEncode(data['user']));
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Identifiants incorrects'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  // Schedule methods
  static Future<Map<String, dynamic>> getSchedules() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/schedules'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'schedules': data['schedules']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  static Future<Map<String, dynamic>> createSchedule({
    required String titre,
    String? description,
    required DateTime dateDebut,
    required DateTime dateFin,
    required String heureDebut,
    required String heureFin,
    String? lieu,
    List<int>? participants,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/schedules'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'titre': titre,
          'description': description,
          'date_debut': dateDebut.toIso8601String().split('T')[0],
          'date_fin': dateFin.toIso8601String().split('T')[0],
          'heure_debut': heureDebut,
          'heure_fin': heureFin,
          'lieu': lieu,
          'participants': participants,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'schedule': data['schedule']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  static Future<Map<String, dynamic>> updateSchedule(
      int scheduleId,
      Map<String, dynamic> updates,
      ) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/schedules/$scheduleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'schedule': data['schedule']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  static Future<Map<String, dynamic>> deleteSchedule(int scheduleId) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/schedules/$scheduleId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Utility methods
  static Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final userString = await storage.read(key: 'user');
    if (userString != null) {
      return jsonDecode(userString);
    }
    return null;
  }

  static Future<void> logout() async {
    await storage.deleteAll();
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
