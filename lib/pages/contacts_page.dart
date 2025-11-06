import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'call_screen.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<dynamic> _contacts = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
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

  List<dynamic> get _filteredContacts {
    if (_searchQuery.isEmpty) return _contacts;
    return _contacts.where((contact) {
      final numero = contact['numero'].toString().toLowerCase();
      final nom = contact['nom'].toString().toLowerCase();
      final fonction = (contact['fonction'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return numero.contains(query) ||
          nom.contains(query) ||
          fonction.contains(query);
    }).toList();
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
            child: TextField(
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
        leading: Container(
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
          ],
        ),
        trailing: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.call, color: Colors.green.shade700),
            onPressed: () => _makeCall(contact),
          ),
        ),
      ),
    );
  }
}
