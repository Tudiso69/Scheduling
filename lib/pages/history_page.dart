import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // État de la page : 'schedules' ou 'calls'
  String _currentView = 'schedules';

  List<dynamic> _schedulesHistory = [];
  List<dynamic> _callsHistory = [];
  Map<String, dynamic>? _stats;

  bool _isLoadingSchedules = false;
  bool _isLoadingCalls = false;

  String _schedulePeriod = 'week';
  String _callPeriod = 'week';
  String _callType = 'all';

  @override
  void initState() {
    super.initState();
    _loadSchedulesHistory();
  }

  Future<void> _loadSchedulesHistory() async {
    setState(() => _isLoadingSchedules = true);
    final result = await ApiService.getSchedulesHistory(period: _schedulePeriod);
    setState(() {
      _isLoadingSchedules = false;
      if (result['success']) {
        _schedulesHistory = result['history'];
      }
    });
  }

  Future<void> _loadCallsHistory() async {
    setState(() => _isLoadingCalls = true);
    final result = await ApiService.getCallsHistory(
        period: _callPeriod,
        type: _callType
    );
    setState(() {
      _isLoadingCalls = false;
      if (result['success']) {
        _callsHistory = result['calls'];
      }
    });
  }

  Future<void> _loadStats() async {
    final result = await ApiService.getHistoryStats();
    if (result['success']) {
      setState(() {
        _stats = result['stats'];
      });
    }
  }

  void _toggleView() {
    setState(() {
      if (_currentView == 'schedules') {
        _currentView = 'calls';
        if (_callsHistory.isEmpty) {
          _loadCallsHistory();
        }
      } else {
        _currentView = 'schedules';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ✅ Header avec switch intégré
          _buildHeader(),

          // Contenu principal
          Expanded(
            child: _currentView == 'schedules'
                ? _buildSchedulesView()
                : _buildCallsView(),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HEADER AVEC SWITCH INTÉGRÉ
  // ============================================
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône et titre
          Icon(
            _currentView == 'schedules' ? Icons.event : Icons.phone,
            color: Colors.cyan.shade700,
            size: 28,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentView == 'schedules'
                  ? 'Schedules'
                  : 'Appels',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),

          // ✅ Bouton switch (même style que stats)
          Container(
            decoration: BoxDecoration(
              color: Colors.cyan.shade50,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.swap_horiz,
                color: Colors.cyan.shade700,
              ),
              onPressed: _toggleView,
              tooltip: _currentView == 'schedules'
                  ? 'Voir les appels'
                  : 'Voir les schedules',
            ),
          ),

          SizedBox(width: 8),

          // Bouton statistiques
          /*Container(
            decoration: BoxDecoration(
              color: Colors.cyan.shade50,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.bar_chart,
                color: Colors.cyan.shade700,
              ),
              onPressed: _showStatsModal,
              tooltip: 'Statistiques',
            ),
          ),*/
        ],
      ),
    );
  }

  // ============================================
  // MODAL STATISTIQUES
  // ============================================
  void _showStatsModal() async {
    if (_stats == null) {
      await _loadStats();
    }

    if (_stats == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de poignée
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),

            // Titre
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.cyan.shade700, size: 28),
                SizedBox(width: 12),
                Text(
                  'Statistiques',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Grille de stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.event_available,
                    value: (_stats!['total_schedules_archived'] ?? 0).toString(),
                    label: 'Schedules\narchivés',
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.call,
                    value: (_stats!['total_calls'] ?? 0).toString(),
                    label: 'Total\nappels',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    value: (_stats!['completed_calls'] ?? 0).toString(),
                    label: 'Appels\ncomplétés',
                    color: Colors.teal,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.call_missed,
                    value: (_stats!['missed_calls'] ?? 0).toString(),
                    label: 'Appels\nmanqués',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Durée totale des appels
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: Colors.purple.shade700),
                  SizedBox(width: 12),
                  Text(
                    'Durée totale: ${_formatDuration(_stats!['total_call_duration'] ?? 0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // VUE SCHEDULES
  // ============================================
  Widget _buildSchedulesView() {
    return Column(
      children: [
        // Filtre période
        _buildPeriodFilter(
          period: _schedulePeriod,
          onChanged: (value) {
            setState(() => _schedulePeriod = value);
            _loadSchedulesHistory();
          },
        ),

        // Liste
        Expanded(
          child: _isLoadingSchedules
              ? Center(child: CircularProgressIndicator())
              : _schedulesHistory.isEmpty
              ? _buildEmptyState(
            icon: Icons.event_note,
            message: 'Aucun schedule archivé',
          )
              : RefreshIndicator(
            onRefresh: _loadSchedulesHistory,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _schedulesHistory.length,
              itemBuilder: (context, index) {
                return _buildScheduleCard(_schedulesHistory[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // VUE APPELS
  // ============================================
  // ============================================
// VUE APPELS (VERSION COMPACTE)
// ============================================
  Widget _buildCallsView() {
    return Column(
      children: [
        // ✅ Filtres compacts sur 1 ligne
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filtre période
              Row(
                children: [
                  Text(
                    'Période:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip('Récent', 'today', _callPeriod, (value) {
                          setState(() => _callPeriod = value);
                          _loadCallsHistory();
                        }),
                        _buildFilterChip('Semaine', 'week', _callPeriod, (value) {
                          setState(() => _callPeriod = value);
                          _loadCallsHistory();
                        }),
                        _buildFilterChip('Mois', 'month', _callPeriod, (value) {
                          setState(() => _callPeriod = value);
                          _loadCallsHistory();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Filtre type (même ligne)
              Row(
                children: [
                  Text(
                    'Type:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip('Tous', 'all', _callType, (value) {
                          setState(() => _callType = value);
                          _loadCallsHistory();
                        }),
                        _buildFilterChip('Sortants', 'outgoing', _callType, (value) {
                          setState(() => _callType = value);
                          _loadCallsHistory();
                        }),
                        _buildFilterChip('Entrants', 'incoming', _callType, (value) {
                          setState(() => _callType = value);
                          _loadCallsHistory();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Liste
        Expanded(
          child: _isLoadingCalls
              ? Center(child: CircularProgressIndicator())
              : _callsHistory.isEmpty
              ? _buildEmptyState(
            icon: Icons.phone_disabled,
            message: 'Aucun appel enregistré',
          )
              : RefreshIndicator(
            onRefresh: _loadCallsHistory,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _callsHistory.length,
              itemBuilder: (context, index) {
                return _buildCallCard(_callsHistory[index]);
              },
            ),
          ),
        ),
      ],
    );
  }


  // ============================================
  // WIDGETS RÉUTILISABLES
  // ============================================

  Widget _buildPeriodFilter({
    required String period,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Période:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('Récent', 'today', period, onChanged),
                _buildFilterChip('Semaine', 'week', period, onChanged),
                _buildFilterChip('Mois', 'month', period, onChanged),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label,
      String value,
      String currentValue,
      Function(String) onSelected,
      ) {
    final isSelected = currentValue == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onSelected(value);
      },
      selectedColor: Colors.cyan.shade100,
      checkmarkColor: Colors.cyan.shade700,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.cyan.shade700 : Colors.grey.shade700,
      ),
    );
  }

  Widget _buildScheduleCard(dynamic schedule) {
    final dateFormat = DateFormat('dd/MM/yyyy');

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
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.event, color: Colors.blue.shade700, size: 28),
        ),
        title: Text(
          schedule['titre'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                SizedBox(width: 4),
                Text(
                  '${dateFormat.format(DateTime.parse(schedule['date_debut']))} - ${dateFormat.format(DateTime.parse(schedule['date_fin']))}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                SizedBox(width: 4),
                Text(
                  '${schedule['heure_debut']} - ${schedule['heure_fin']}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (schedule['lieu'] != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.place, size: 14, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      schedule['lieu'],
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                SizedBox(width: 4),
                Text(
                  '${schedule['participants_count']} participant(s)',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.archive, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildCallCard(dynamic call) {
    final isOutgoing = call['call_direction'] == 'outgoing';
    final otherPerson = isOutgoing
        ? '${call['receiver_nom']} ${call['receiver_prenom'] ?? ''}'.trim()
        : '${call['caller_nom']} ${call['caller_prenom'] ?? ''}'.trim();
    final otherNumber = isOutgoing
        ? call['receiver_numero']
        : call['caller_numero'];

    final status = call['call_status'];
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.call;
        statusText = 'Complété';
        break;
      case 'missed':
        statusColor = Colors.red;
        statusIcon = Icons.call_missed;
        statusText = 'Manqué';
        break;
      case 'rejected':
        statusColor = Colors.orange;
        statusIcon = Icons.call_end;
        statusText = 'Rejeté';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.phone_disabled;
        statusText = 'Échoué';
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final duration = call['duration_seconds'] ?? 0;
    final durationText = duration > 0
        ? '${(duration ~/ 60).toString().padLeft(2, '0')}:${(duration % 60).toString().padLeft(2, '0')}'
        : '-';

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
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isOutgoing ? Icons.call_made : Icons.call_received,
            color: statusColor,
            size: 28,
          ),
        ),
        title: Text(
          otherPerson,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              otherNumber,
              style: TextStyle(
                fontSize: 14,
                color: Colors.cyan.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(fontSize: 13, color: statusColor),
                ),
                SizedBox(width: 12),
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                SizedBox(width: 4),
                Text(
                  durationText,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              dateFormat.format(DateTime.parse(call['created_at'])),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          SizedBox(height: 16),
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
}
