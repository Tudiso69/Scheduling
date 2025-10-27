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
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<dynamic> _schedules = [];
  bool _isLoading = false;

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

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
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
              markerDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
              child: Text(
                'Aucun horaire pour ce jour',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: selectedEvents.length,
              itemBuilder: (context, index) {
                final schedule = selectedEvents[index];
                return _buildScheduleCard(schedule);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _canManageSchedules()
          ? FloatingActionButton(
        onPressed: () => _showScheduleDialog(),
        backgroundColor: Colors.cyan.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildScheduleCard(dynamic schedule) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.cyan.shade600,
          child: const Icon(Icons.event, color: Colors.white, size: 20),
        ),
        title: Text(
          schedule['titre'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${schedule['heure_debut']} - ${schedule['heure_fin']}'),
            if (schedule['lieu'] != null)
              Text('📍 ${schedule['lieu']}'),
            Text('Par: ${schedule['createur']}'),
          ],
        ),
        trailing: _canManageSchedules()
            ? PopupMenuButton(
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
              _showScheduleDialog(schedule: schedule);
            } else if (value == 'delete') {
              _deleteSchedule(schedule['id']);
            }
          },
        )
            : null,
        onTap: () => _showScheduleDetails(schedule),
      ),
    );
  }

  void _showScheduleDialog({dynamic schedule}) {
    final isEdit = schedule != null;
    final titreController = TextEditingController(text: schedule?['titre']);
    final descriptionController = TextEditingController(text: schedule?['description']);
    final lieuController = TextEditingController(text: schedule?['lieu']);

    DateTime dateDebut = isEdit
        ? DateTime.parse(schedule['date_debut'])
        : _selectedDay ?? DateTime.now();
    DateTime dateFin = isEdit
        ? DateTime.parse(schedule['date_fin'])
        : _selectedDay ?? DateTime.now();
    TimeOfDay heureDebut = isEdit
        ? _parseTime(schedule['heure_debut'])
        : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay heureFin = isEdit
        ? _parseTime(schedule['heure_fin'])
        : const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Modifier l\'horaire' : 'Nouvel horaire'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lieuController,
                decoration: const InputDecoration(
                  labelText: 'Lieu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
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
                          setState(() => dateDebut = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('dd/MM/yyyy').format(dateDebut)),
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
                          setState(() => heureDebut = picked);
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(heureDebut.format(context)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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

              Navigator.pop(context);

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
            child: Text(isEdit ? 'Modifier' : 'Créer'),
          ),
        ],
      ),
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  void _showScheduleDetails(dynamic schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule['titre']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (schedule['description'] != null && schedule['description'].isNotEmpty)
              Text(schedule['description']),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text('${schedule['date_debut']} → ${schedule['date_fin']}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text('${schedule['heure_debut']} - ${schedule['heure_fin']}'),
              ],
            ),
            if (schedule['lieu'] != null && schedule['lieu'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(schedule['lieu'])),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 8),
                Text('Créé par: ${schedule['createur']}'),
              ],
            ),
            if (schedule['nombre_participants'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.group, size: 16),
                  const SizedBox(width: 8),
                  Text('${schedule['nombre_participants']} participant(s)'),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSchedule(int scheduleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer cet horaire ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
