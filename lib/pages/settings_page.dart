import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;  // ✅ Ajout de l'import
import '../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final config = await ApiService.getCurrentServerConfig();
    setState(() {
      _ipController.text = config['ip'] ?? '192.168.46.79';
      _portController.text = config['port'] ?? '3000';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    // ✅ Passer IP et Port séparément
    await ApiService.updateServerUrl(
      _ipController.text.trim(),
      _portController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Paramètres enregistrés. Redémarrez l\'app.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isLoading = true);

    final testUrl = 'http://${_ipController.text.trim()}:${_portController.text.trim()}';

    try {
      final response = await http.get(Uri.parse(testUrl)).timeout(
        Duration(seconds: 5),
      );

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 200
                  ? '✅ Connexion réussie !'
                  : '⚠️ Serveur accessible mais erreur ${response.statusCode}',
            ),
            backgroundColor: response.statusCode == 200
                ? Colors.green
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Connexion échouée: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres Serveur'),
        backgroundColor: Colors.cyan.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre et description
            const Text(
              'Configuration du Serveur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Modifiez ces paramètres si le serveur change d\'IP',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // IP du serveur
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'Adresse IP du Serveur',
                hintText: 'Ex: 192.168.1.100',
                prefixIcon: const Icon(Icons.computer),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // Port
            TextField(
              controller: _portController,
              decoration: InputDecoration(
                labelText: 'Port',
                hintText: 'Ex: 3000',
                prefixIcon: const Icon(Icons.settings_ethernet),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Demandez l\'IP du serveur à votre administrateur IT',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _testConnection,
                    icon: const Icon(Icons.wifi_find),
                    label: const Text('Tester'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
