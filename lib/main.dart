import 'package:flutter/material.dart';
import 'dialpad.dart';
import 'services/api_service.dart';
import 'services/webrtc_service.dart';  // ✅ Nouveau
import 'pages/login_page.dart';
import 'pages/schedules_page.dart';
import 'pages/contacts_page.dart';  // ✅ Nouveau
import 'pages/call_screen.dart';  // ✅ Nouveau

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        useMaterial3: true,
      ),
      home: const AuthChecker(),
    );
  }
}

// Vérificateur d'authentification
class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await ApiService.isLoggedIn();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isLoggedIn ? const HomePage() : const LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _user;
  final WebRTCService _webrtcService = WebRTCService();  // ✅ Nouveau

  @override
  void initState() {
    super.initState();
    _loadUser();
    _setupWebRTC();  // ✅ Nouveau
  }

  Future<void> _loadUser() async {
    final user = await ApiService.getUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  // ✅ Configuration WebRTC
  Future<void> _setupWebRTC() async {
    final user = await ApiService.getUser();
    if (user != null) {
      await _webrtcService.connect(
        serverUrl: 'http://10.0.2.2:3000',  // Changez pour votre IP
        user: user,
      );

      // Écouter les appels entrants
      _webrtcService.onIncomingCall = (fromId, fromName, fromNumber) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.call, color: Colors.green.shade600),
                SizedBox(width: 12),
                Text('Appel entrant'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 60, color: Colors.cyan.shade600),
                SizedBox(height: 16),
                Text(
                  fromName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  fromNumber,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _webrtcService.rejectCall();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text('Refuser'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CallScreen(
                        destinationName: fromName,
                        isIncoming: true,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text('Accepter'),
              ),
            ],
          ),
        );
      };
    }
  }

  Future<void> _logout() async {
    _webrtcService.dispose();  // ✅ Déconnecter WebRTC
    await ApiService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // Header Section (identique)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.cyan.shade400,
                    Colors.cyan.shade600,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: Colors.cyan.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _user?['numero'] ?? 'Chargement...',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _user != null
                                  ? '${_user!['nom']} ${_user!['prenom'] ?? ''}'.trim()
                                  : '',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (_user?['fonction'] != null)
                              Text(
                                _user!['fonction'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Déconnexion'),
                                content: const Text('Voulez-vous vous déconnecter ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _logout();
                                    },
                                    child: const Text(
                                      'Déconnexion',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.exit_to_app,
                            color: Colors.white,
                            size: 26,
                          ),
                          tooltip: 'Déconnexion',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Tab Bar Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                labelColor: Colors.cyan.shade700,
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: Colors.cyan.shade600,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.schedule, size: 24),
                    text: 'Schedules',
                    height: 70,
                  ),
                  Tab(
                    icon: Icon(Icons.contacts, size: 24),
                    text: 'Contacts',
                    height: 70,
                  ),
                  Tab(
                    icon: Icon(Icons.history, size: 24),
                    text: 'History',
                    height: 70,
                  ),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  SchedulesPage(userRole: _user?['role']),
                  ContactsPage(),  // ✅ Page Contacts avec appels
                  _buildTabContent(Icons.history, 'No call history'),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            DialpadBottomSheet.show(context);
          },
          backgroundColor: Colors.cyan.shade600,
          elevation: 6,
          child: const Icon(
            Icons.dialpad,
            size: 28,
            color: Colors.white,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildTabContent(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _webrtcService.dispose();  // ✅ Nettoyer à la fermeture
    super.dispose();
  }
}
