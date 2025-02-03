import 'package:flutter/material.dart';
import '../services/odoo_service.dart';
import 'package:intl/intl.dart';

class TaskSubmissionScreen extends StatefulWidget {
  final OdooService odooService;
  final Map<String, dynamic> taskData;

  TaskSubmissionScreen({
    required this.odooService,
    required this.taskData,
  });

  @override
  _TaskSubmissionScreenState createState() => _TaskSubmissionScreenState();
}

class _TaskSubmissionScreenState extends State<TaskSubmissionScreen> {
  final _responseController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _responseController.text = widget.taskData['response'] ?? '';
  }

  Future<void> _submitTask() async {
    if (_responseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, escribe una respuesta')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.odooService.submitTask(
        widget.taskData['id'],
        _responseController.text,
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Entregar Tarea'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.taskData['task_id'][1],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Fecha límite: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(widget.taskData['due_date']))}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Descripción de la Tarea:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(widget.taskData['task_description'] ?? 'Sin descripción'),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Tu Respuesta:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            TextField(
              controller: _responseController,
              maxLines: 10,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Escribe tu respuesta aquí...',
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: _isSubmitting
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitTask,
                      child: Text('Entregar Tarea'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(200, 50),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }
}