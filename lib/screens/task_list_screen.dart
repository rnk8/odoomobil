import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/odoo_service.dart';
import 'task_submission_screen.dart';

class TaskListScreen extends StatefulWidget {
  final OdooService odooService;

  TaskListScreen({required this.odooService});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Map<String, dynamic>> tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final fetchedTasks = await widget.odooService.fetchMyTasks();
      setState(() {
        tasks = fetchedTasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Tareas'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final dueDate = task['due_date'] != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(task['due_date']))
                      : 'Sin fecha límite';
                  
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(task['task_id'][1], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fecha límite: $dueDate'),
                          Text('Estado: ${_getStatusText(task['status'])}'),
                          if (task['grade'] != null)
                            Text('Calificación: ${task['grade']}%'),
                        ],
                      ),
                      trailing: task['status'] == 'pending'
                          ? Icon(Icons.arrow_forward_ios)
                          : null,
                      onTap: task['status'] == 'pending'
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskSubmissionScreen(
                                    odooService: widget.odooService,
                                    taskData: task,
                                  ),
                                ),
                              ).then((_) => _loadTasks())
                          : null,
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'submitted':
        return 'Entregada';
      case 'graded':
        return 'Calificada';
      default:
        return status;
    }
  }
}