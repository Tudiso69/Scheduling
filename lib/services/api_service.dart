import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ URL de base modifiable
  static String _baseUrl = 'http://192.168.46.79:3000/api';

  static const storage = FlutterSecureStorage();

  // ✅ Getter pour accéder à baseUrl
  static String get baseUrl => _baseUrl;

  // ✅ Initialiser l'URL au démarrage de l'app
  static Future<void> initializeServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('server_ip') ?? '192.168.46.79';
    final port = prefs.getString('server_port') ?? '3000';
    _baseUrl = 'http://$ip:$port/api';
    print('📡 Server URL initialisé: $_baseUrl');
  }

  // ✅ Mettre à jour l'URL manuellement
  static Future<void> updateServerUrl(String newIp, String newPort) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', newIp);
    await prefs.setString('server_port', newPort);
    _baseUrl = 'http://$newIp:$newPort/api';
    print('📡 Server URL mis à jour: $_baseUrl');
  }

  // ✅ Récupérer l'IP et le port actuels
  static Future<Map<String, String>> getCurrentServerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'ip': prefs.getString('server_ip') ?? '192.168.46.79',
      'port': prefs.getString('server_port') ?? '3000',
    };
  }

  // ============================================
  // HISTORY METHODS
  // ============================================

  /// Récupérer l'historique des schedules
  static Future<Map<String, dynamic>> getSchedulesHistory({
    String period = 'all'
  }) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/history/schedules?period=$period'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'history': data['history']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Récupérer l'historique des appels
  static Future<Map<String, dynamic>> getCallsHistory({
    String period = 'all',
    String type = 'all'
  }) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/history/calls?period=$period&type=$type'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'calls': data['calls']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Enregistrer un appel dans l'historique
  static Future<Map<String, dynamic>> saveCallHistory({
    required int receiverId,
    required String callStatus,
    required int durationSeconds,
    required DateTime startedAt,
    DateTime? endedAt,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/history/calls'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'receiverId': receiverId,
          'callStatus': callStatus,
          'durationSeconds': durationSeconds,
          'startedAt': startedAt.toIso8601String(),
          'endedAt': endedAt?.toIso8601String(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'call': data['call']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Récupérer les statistiques d'historique
  static Future<Map<String, dynamic>> getHistoryStats() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/history/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'stats': data['stats']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Archiver les schedules expirés (Admin/Secrétaire uniquement)
  static Future<Map<String, dynamic>> archiveExpiredSchedules() async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/history/archive-expired'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'archived_count': data['archived_count']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Nettoyer l'historique > 7 jours (Admin uniquement)
  static Future<Map<String, dynamic>> cleanupOldHistory() async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/history/cleanup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'schedules_deleted': data['schedules_deleted'],
          'calls_deleted': data['calls_deleted']
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ============================================
  // USER METHODS
  // ============================================

  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/users'),
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

  // ============================================
  // AUTH METHODS
  // ============================================

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
        Uri.parse('$_baseUrl/auth/register'),
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
        Uri.parse('$_baseUrl/auth/login'),
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

  // ============================================
  // SCHEDULE METHODS
  // ============================================

  static Future<Map<String, dynamic>> getSchedules() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/schedules'),
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
        Uri.parse('$_baseUrl/schedules'),
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
        Uri.parse('$_baseUrl/schedules/$scheduleId'),
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
        Uri.parse('$_baseUrl/schedules/$scheduleId'),
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

  // ============================================
  // UTILITY METHODS
  // ============================================

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
    try {
      final token = await storage.read(key: 'token')
          .timeout(Duration(seconds: 3), onTimeout: () => null);
      return token != null;
    } catch (e) {
      return false;
    }
  }
}
