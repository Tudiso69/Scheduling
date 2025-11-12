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
  Set<int> _expandedSchedules = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    print('🚀 SchedulesPage initialisé');
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    print('\n📥 === CHARGEMENT SCHEDULES ===');
    setState(() => _isLoading = true);
    final result = await ApiService.getSchedules();
    print('📬 Résultat: $result');
    setState(() => _isLoading = false);

    if (result['success']) {
      setState(() {
        _schedules = result['schedules'];
      });
      print('✅ ${_schedules.length} schedules chargés');
    } else {
      print('❌ Erreur chargement: ${result['message']}');
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
                      onTap: () {},
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                          maxHeight: MediaQuery.of(context).size.height * 0.7,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.cyan.shade600,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.white, size: 22),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Calendrier',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: _toggleCalendar,
                                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: TableCalendar(
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
                                    daysOfWeekHeight: 40,
                                    rowHeight: 48,
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
                                      cellMargin: const EdgeInsets.all(4),
                                      defaultTextStyle: const TextStyle(fontSize: 14),
                                      weekendTextStyle: const TextStyle(fontSize: 14),
                                    ),
                                    headerStyle: HeaderStyle(
                                      formatButtonVisible: true,
                                      titleCentered: true,
                                      formatButtonTextStyle: const TextStyle(fontSize: 13),
                                      titleTextStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'calendar',
              onPressed: _toggleCalendar,
              backgroundColor: Colors.cyan.shade600,
              elevation: 6,
              child: Icon(
                _showCalendar ? Icons.close : Icons.calendar_today,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            if (_canManageSchedules())
              FloatingActionButton(
                heroTag: 'add',
                onPressed: () => _showAddScheduleDialog(),
                backgroundColor: Colors.greenAccent,
                elevation: 6,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dateDebut,
                            firstDate: DateTime.now(), // ✅ Bloque dates passées
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dateFin,
                            firstDate: dateDebut, // ✅ Date fin >= date début
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

                // ✅ LOGS AJOUTÉS
                print('\n🚀 === SOUMISSION SCHEDULE ===');
                print('📝 Titre: ${titreController.text.trim()}');
                print('📅 Date début: $dateDebut');
                print('📅 Date fin: $dateFin');
                print('🕐 Heure début: ${heureDebut.format(context)}');
                print('🕐 Heure fin: ${heureFin.format(context)}');

                final data = {
                  'titre': titreController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'lieu': lieuController.text.trim(),
                  'date_debut': dateDebut.toIso8601String().split('T')[0],
                  'date_fin': dateFin.toIso8601String().split('T')[0],
                  'heure_debut': '${heureDebut.hour.toString().padLeft(2, '0')}:${heureDebut.minute.toString().padLeft(2, '0')}',
                  'heure_fin': '${heureFin.hour.toString().padLeft(2, '0')}:${heureFin.minute.toString().padLeft(2, '0')}',
                };

                print('📦 Data envoyée: $data');

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

                print('📬 === RÉSULTAT COMPLET ===');
                print(result);
                print('Success: ${result['success']}');
                print('Message: ${result['message']}');

                if (mounted) {
                  if (result['success']) {
                    print('✅ SUCCESS: Schedule ${isEdit ? "modifié" : "créé"}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Horaire modifié' : 'Horaire créé'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    print('🔄 Rechargement de la liste...');
                    _loadSchedules();
                  } else {
                    print('❌ ERREUR: ${result['message']}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Erreur inconnue'),
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
      print('\n🗑️ === SUPPRESSION SCHEDULE ===');
      print('🆔 ID: $scheduleId');

      final result = await ApiService.deleteSchedule(scheduleId);

      print('📬 Résultat suppression: $result');

      if (mounted) {
        if (result['success']) {
          print('✅ Schedule supprimé');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Horaire supprimé'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSchedules();
        } else {
          print('❌ Erreur suppression: ${result['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
