import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/webrtc_service.dart';
import 'call_screen.dart';

class ContactsPage extends StatefulWidget {
  final WebRTCService webrtcService;

  const ContactsPage({Key? key, required this.webrtcService}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<dynamic> _contacts = [];
  Set<int> _onlineUserIds = {};
  bool _isLoading = false;
  String _searchQuery = '';
  int? _currentUserId;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    print('🚀 === ContactsPage InitState ===');
    _loadCurrentUser();
    _loadContacts();
    _setupOnlineStatusRefresh();
  }

  Future<void> _loadCurrentUser() async {
    final user = await ApiService.getUser();
    if (user != null) {
      setState(() {
        _currentUserId = user['id'];
      });
      print('👤 User chargé: ${user['id']} - ${user['nom']}');
    }
  }

  void _setupOnlineStatusRefresh() {
    print('🎧 === Configuration UI Refresh ContactsPage ===');

    _onlineUserIds = widget.webrtcService.onlineUserIds;
    print('👥 État initial ContactsPage: ${_onlineUserIds.length} users');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _onlineUserIds = widget.webrtcService.onlineUserIds;
        });
        print('🔄 État initial appliqué après frame: $_onlineUserIds');
      }
    });

    _refreshTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) {
        final currentIds = widget.webrtcService.onlineUserIds;
        if (currentIds != _onlineUserIds) {
          setState(() {
            _onlineUserIds = currentIds;
          });
          print('🔄 Refresh périodique: $_onlineUserIds');
        }
      } else {
        timer.cancel();
      }
    });

    print('✅ UI Refresh configuré');
  }

  @override
  void dispose() {
    print('🗑️ ContactsPage dispose');
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    print('📥 Chargement des contacts...');
    setState(() => _isLoading = true);
    final result = await ApiService.getAllUsers();
    setState(() => _isLoading = false);

    if (result['success']) {
      setState(() {
        _contacts = result['users'];
      });
      print('✅ ${_contacts.length} contacts chargés');
    } else {
      print('❌ Erreur chargement contacts: ${result['message']}');
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

  List<dynamic> get _filteredContacts {
    var filtered = _contacts.where((contact) {
      return contact['id'] != _currentUserId;
    }).toList();

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
    print('📞 Appel vers ${contact['nom']}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          webrtcService: widget.webrtcService,
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
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _onlineUserIds.isEmpty
                              ? Colors.grey.shade400
                              : Colors.green.shade500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        _onlineUserIds.isEmpty
                            ? 'Aucun utilisateur en ligne'
                            : '${_onlineUserIds.length} utilisateur(s) en ligne',
                        style: TextStyle(
                          fontSize: 13,
                          color: _onlineUserIds.isEmpty
                              ? Colors.grey.shade600
                              : Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? Colors.green.shade500
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    isOnline ? 'Disponible' : 'Hors ligne',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOnline
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
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
              color: isOnline
                  ? Colors.green.shade700
                  : Colors.grey.shade500,
            ),
            onPressed: isOnline ? () => _makeCall(contact) : null,
          ),
        ),
      ),
    );
  }
}
