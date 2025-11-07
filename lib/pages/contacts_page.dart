import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/webrtc_service.dart';
import 'call_screen.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<dynamic> _contacts = [];
  Set<int> _onlineUserIds = {};
  bool _isLoading = false;
  String _searchQuery = '';
  int? _currentUserId;  // ✅ ID de l'utilisateur connecté

  final WebRTCService _webrtcService = WebRTCService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();  // ✅ Charger l'utilisateur actuel
    _loadContacts();
    _setupOnlineStatusListener();
  }

  // ✅ Récupérer l'utilisateur connecté
  Future<void> _loadCurrentUser() async {
    final user = await ApiService.getUser();
    if (user != null) {
      setState(() {
        _currentUserId = user['id'];
      });
    }
  }

  void _setupOnlineStatusListener() {
    _onlineUserIds = _webrtcService.onlineUserIds;

    _webrtcService.onOnlineUsersChanged = (Set<int> onlineIds) {
      if (mounted) {
        setState(() {
          _onlineUserIds = onlineIds;
        });
        print('👥 Mise à jour: ${_onlineUserIds.length} users en ligne');
      }
    };
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getAllUsers();
    setState(() => _isLoading = false);

    if (result['success']) {
      setState(() {
        _contacts = result['users'];
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Filtrer : exclure l'utilisateur connecté + recherche
  List<dynamic> get _filteredContacts {
    // Exclure l'utilisateur connecté
    var filtered = _contacts.where((contact) {
      return contact['id'] != _currentUserId;  // ✅ Ne pas s'afficher soi-même
    }).toList();

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((contact) {
        final numero = contact['numero'].toString().toLowerCase();
        final nom = contact['nom'].toString().toLowerCase();
        final fonction = (contact['fonction'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return numero.contains(query) ||
            nom.contains(query) ||
            fonction.contains(query);
      }).toList();
    }

    return filtered;
  }

  void _makeCall(dynamic contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          destinationUserId: contact['id'].toString(),
          destinationName:
          '${contact['nom']} ${contact['prenom'] ?? ''}'.trim(),
          isIncoming: false,
        ),
      ),
    );
  }

  bool _isUserOnline(dynamic contact) {
    final userId = contact['id'];
    return _onlineUserIds.contains(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher un contact...',
                    prefixIcon: Icon(Icons.search, color: Colors.cyan.shade600),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

                // Indicateur du nombre d'users en ligne
                if (_onlineUserIds.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${_onlineUserIds.length} utilisateur(s) en ligne',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Liste des contacts
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadContacts,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredContacts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  return _buildContactCard(_filteredContacts[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contacts,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Aucun contact' : 'Aucun résultat',
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

  Widget _buildContactCard(dynamic contact) {
    final isOnline = _isUserOnline(contact);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Stack(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.cyan.shade50,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  contact['nom'][0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan.shade700,
                  ),
                ),
              ),
            ),

            // Indicateur en ligne (point vert)
            if (isOnline)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green.shade500,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          '${contact['nom']} ${contact['prenom'] ?? ''}'.trim(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              contact['numero'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.cyan.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (contact['fonction'] != null)
              Text(
                contact['fonction'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),

            // Statut en ligne
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green.shade500 : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    isOnline ? 'Disponible' : 'Hors ligne',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOnline ? Colors.green.shade700 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green.shade50 : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.call,
              color: isOnline ? Colors.green.shade700 : Colors.grey.shade500,
            ),
            onPressed: isOnline ? () => _makeCall(contact) : null,
          ),
        ),
      ),
    );
  }
}
