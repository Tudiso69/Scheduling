import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class SchedulesPage extends StatefulWidget {
  final String? userRole;

  const SchedulesPage({super.key, this.userRole});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  List<dynamic> _schedules = [];
  bool _isLoading = false;
  bool _showCalendar = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<int> _expandedSchedules = {}; // Pour tracker les descriptions expandées

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getSchedules();
    setState(() => _isLoading = false);

    if (result['success']) {
      setState(() {
        _schedules = result['schedules'];
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _schedules.where((schedule) {
      final dateDebut = DateTime.parse(schedule['date_debut']);
      final dateFin = DateTime.parse(schedule['date_fin']);
      return day.isAfter(dateDebut.subtract(const Duration(days: 1))) &&
          day.isBefore(dateFin.add(const Duration(days: 1)));
    }).toList();
  }

  bool _canManageSchedules() {
    return widget.userRole == 'secretaire' || widget.userRole == 'admin';
  }

  void _toggleCalendar() {
    setState(() {
      _showCalendar = !_showCalendar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Liste des schedules
          RefreshIndicator(
            onRefresh: _loadSchedules,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _schedules.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _schedules.length,
              itemBuilder: (context, index) {
                return _buildScheduleCard(_schedules[index]);
              },
            ),
          ),

          // Calendrier overlay
          if (_showCalendar)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleCalendar,
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {}, // Empêche la fermeture au clic sur le calendrier
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header du calendrier
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.cyan.shade600,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.white),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Calendrier',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: _toggleCalendar,
                                    icon: const Icon(Icons.close, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            // Calendrier
                            TableCalendar(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: _focusedDay,
                              calendarFormat: _calendarFormat,
                              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                              },
                              onFormatChanged: (format) {
                                setState(() {
                                  _calendarFormat = format;
                                });
                              },
                              eventLoader: _getEventsForDay,
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color: Colors.cyan.shade300,
                                  shape: BoxShape.circle,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: Colors.cyan.shade600,
                                  shape: BoxShape.circle,
                                ),
                                markerDecoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: true,
                                titleCentered: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),floatingActionButton: Stack(
      children: [
        // Bouton Calendrier - En haut à droite
        Positioned(
          bottom: 80,
          left: 30,
          child: FloatingActionButton(
            heroTag: 'calendar',
            onPressed: _toggleCalendar,
            backgroundColor: Colors.cyan.shade400,
            child: Icon(
              _showCalendar ? Icons.close : Icons.calendar_today,
              color: Colors.white,
            ),
          ),
        ),

        // Bouton Ajouter - En bas à GAUCHE
        if (_canManageSchedules())
          Positioned(
            bottom: 0,
            left: 30,
            child: FloatingActionButton(
              heroTag: 'add',
              onPressed: () => _showAddScheduleDialog(),
              backgroundColor: Colors.greenAccent.shade200.withOpacity(1),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
      ],
    ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun horaire',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (_canManageSchedules())
            Text(
              'Appuyez sur + pour créer',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(dynamic schedule) {
    final isExpanded = _expandedSchedules.contains(schedule['id']);
    final dateDebut = DateTime.parse(schedule['date_debut']);
    final dateFormatted = DateFormat('dd/MM/yyyy').format(dateDebut);
    final heureDebut = schedule['heure_debut'];
    final heureFin = schedule['heure_fin'];

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedSchedules.remove(schedule['id']);
          } else {
            _expandedSchedules.add(schedule['id']);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec date/heure et titre
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date et heure (à gauche)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.cyan.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dateFormatted,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.cyan.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$heureDebut - $heureFin',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.cyan.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Titre (au milieu)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule['titre'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Par ${schedule['createur']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Menu actions (pour secrétaire/admin)
                    if (_canManageSchedules())
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showAddScheduleDialog(schedule: schedule);
                          } else if (value == 'delete') {
                            _deleteSchedule(schedule['id']);
                          }
                        },
                      ),
                  ],
                ),
              ),

              // Description (expandable)
              if (schedule['description'] != null && schedule['description'].isNotEmpty)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: isExpanded ? 12 : 0,
                  ),
                  height: isExpanded ? null : 0,
                  child: isExpanded
                      ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.description, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            schedule['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      : const SizedBox.shrink(),
                ),

              // Footer avec lieu
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Indicateur expandable
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isExpanded ? 'Réduire' : 'Détails',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Lieu (à droite)
                    if (schedule['lieu'] != null && schedule['lieu'].isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              schedule['lieu'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddScheduleDialog({dynamic schedule}) {
    final isEdit = schedule != null;
    final titreController = TextEditingController(text: schedule?['titre']);
    final descriptionController = TextEditingController(text: schedule?['description']);
    final lieuController = TextEditingController(text: schedule?['lieu']);

    DateTime dateDebut = isEdit
        ? DateTime.parse(schedule['date_debut'])
        : DateTime.now();
    DateTime dateFin = isEdit
        ? DateTime.parse(schedule['date_fin'])
        : DateTime.now();
    TimeOfDay heureDebut = isEdit
        ? _parseTime(schedule['heure_debut'])
        : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay heureFin = isEdit
        ? _parseTime(schedule['heure_fin'])
        : const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit : Icons.add_circle,
                color: Colors.cyan.shade600,
              ),
              const SizedBox(width: 12),
              Text(isEdit ? 'Modifier l\'horaire' : 'Nouvel horaire'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                TextField(
                  controller: titreController,
                  decoration: InputDecoration(
                    labelText: 'Titre *',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date et Heure de début
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dateDebut,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => dateDebut = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          DateFormat('dd/MM/yyyy').format(dateDebut),
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: heureDebut,
                          );
                          if (picked != null) {
                            setDialogState(() => heureDebut = picked);
                          }
                        },
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(
                          heureDebut.format(context),
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date et Heure de fin
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dateFin,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => dateFin = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          DateFormat('dd/MM/yyyy').format(dateFin),
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: heureFin,
                          );
                          if (picked != null) {
                            setDialogState(() => heureFin = picked);
                          }
                        },
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(
                          heureFin.format(context),
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Lieu
                TextField(
                  controller: lieuController,
                  decoration: InputDecoration(
                    labelText: 'Lieu',
                    prefixIcon: const Icon(Icons.location_on),
                    hintText: 'Ex: Salle 009',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titreController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le titre est requis'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                final data = {
                  'titre': titreController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'lieu': lieuController.text.trim(),
                  'date_debut': dateDebut.toIso8601String().split('T')[0],
                  'date_fin': dateFin.toIso8601String().split('T')[0],
                  'heure_debut': '${heureDebut.hour.toString().padLeft(2, '0')}:${heureDebut.minute.toString().padLeft(2, '0')}',
                  'heure_fin': '${heureFin.hour.toString().padLeft(2, '0')}:${heureFin.minute.toString().padLeft(2, '0')}',
                };

                final result = isEdit
                    ? await ApiService.updateSchedule(schedule['id'], data)
                    : await ApiService.createSchedule(
                  titre: data['titre']!,
                  description: data['description'],
                  dateDebut: dateDebut,
                  dateFin: dateFin,
                  heureDebut: data['heure_debut']!,
                  heureFin: data['heure_fin']!,
                  lieu: data['lieu'],
                );

                if (mounted) {
                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Horaire modifié' : 'Horaire créé'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadSchedules();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade600,
              ),
              child: Text(isEdit ? 'Modifier' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _deleteSchedule(int scheduleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Confirmation'),
          ],
        ),
        content: const Text('Voulez-vous vraiment supprimer cet horaire ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await ApiService.deleteSchedule(scheduleId);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Horaire supprimé'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSchedules();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
