import 'package:http/http.dart' as http;
import 'dart:convert';

class OdooService {
  final String baseUrl;
  final String username;
  final String password;
  final String dbName = 'odoo';
  String? sessionId;
  int? userId; // <-- Agregar esta variable
  
  OdooService({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  Uri _getUrl(String path) {
    String normalizedUrl = baseUrl.toLowerCase();
    if (!normalizedUrl.startsWith('http://') && !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'http://$baseUrl';
    }
    normalizedUrl = normalizedUrl.replaceAll(RegExp(r'/+$'), '');
    path = path.replaceAll(RegExp(r'^/+'), '/');
    return Uri.parse('$normalizedUrl$path');
  }

  Future<Map<String, dynamic>> authenticate() async {
    try {
      final response = await http.post(
        _getUrl('/web/session/authenticate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'db': dbName,
            'login': username,
            'password': password,
          },
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey('error')) {
          throw Exception(responseData['error']['message'] ?? 'Authentication failed');
        }
        
        String? cookies = response.headers['set-cookie'];
        if (cookies != null) {
          final sessionCookie = cookies.split(';').firstWhere(
            (cookie) => cookie.trim().startsWith('session_id='),
            orElse: () => '',
          );
          if (sessionCookie.isNotEmpty) {
            sessionId = sessionCookie.split('=')[1];
          }
        }
        if(responseData['result'] != null && responseData['result']['uid'] != null) {
          userId = responseData['result']['uid'];
        }
        return responseData;
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyTasks() async {
    if (sessionId == null) {
      await authenticate();
    }
    print('Fetching tasks for user: $userId'); // <-- Log
    try {
      final response = await http.post(
        _getUrl('/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          if (sessionId != null) 'Cookie': 'session_id=$sessionId',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'school.task.submission',
            'method': 'search_read',
            'args': [],
            'kwargs': {
            'domain': [
              ['student_id.user_id', '=', userId],
              ['task_id.state', '=', 'published']
            ],
              'fields': [
                'task_id',
                'due_date',
                'status',
                'grade',
                'task_description',
                'response',
                'feedback',
                'is_late'
              ],
              'order': 'due_date asc',
            },
          },
        }),
      );
      print('Response status: ${response.statusCode}'); // <-- Log
      print('Response body: ${response.body}'); // <-- Log  
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey('error')) {
          throw Exception(responseData['error']['message'] ?? 'Failed to fetch tasks');
        }
        return List<Map<String, dynamic>>.from(responseData['result'] ?? []);
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  Future<void> submitTask(int taskSubmissionId, String response) async {
    if (sessionId == null) {
      await authenticate();
    }

    try {
      final writeResponse = await http.post(
        _getUrl('/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          if (sessionId != null) 'Cookie': 'session_id=$sessionId',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'school.task.submission',
            'method': 'write',
            'args': [
              [taskSubmissionId],
              {'response': response}
            ],
          },
        }),
      );

      if (writeResponse.statusCode != 200) {
        throw Exception('Failed to save response');
      }

      final submitResponse = await http.post(
        _getUrl('/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          if (sessionId != null) 'Cookie': 'session_id=$sessionId',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'school.task.submission',
            'method': 'action_submit',
            'args': [taskSubmissionId],
          },
        }),
      );

      if (submitResponse.statusCode != 200) {
        throw Exception('Failed to submit task');
      }

      final responseData = jsonDecode(submitResponse.body);
      if (responseData.containsKey('error')) {
        throw Exception(responseData['error']['message'] ?? 'Failed to submit task');
      }
    } catch (e) {
      throw Exception('Failed to submit task: $e');
    }
  }

  // Método que actualiza el token de FCM en el sistema Odoo
  Future<void> updateFCMToken(String token) async {
    if (sessionId == null || userId == null) {
      await authenticate();
    }

    try {
      final response = await http.post(
        _getUrl('/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          if (sessionId != null) 'Cookie': 'session_id=$sessionId',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'res.users',
            'method': 'write',
            'args': [
              [userId],
              {'fcm_token': token}
            ],
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update FCM token');
      }
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }
}
