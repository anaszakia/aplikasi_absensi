import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// For image picker

class ApiService {
  static const String baseUrl = 'https://absen.ardhancreative.com/api';

  // Fungsi untuk login (unchanged)
  static Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] ?? data['access_token'];

        if (token != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          return token;
        }
      } else {
        print('Login gagal: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error saat login: $e');
    }
    return null;
  }

  // Fungsi untuk mendapatkan data user (unchanged)
  static Future<Map<String, dynamic>?> getUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Get user gagal: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error saat get user: $e');
    }
    return null;
  }

  // Metode untuk check-in yang menangani web dan mobile
  static Future<Map<String, dynamic>> checkIn(
    String location,
    dynamic photo, // Can be File (mobile) or base64 string (web)
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return {'success': false, 'message': 'Token tidak ditemukan'};
    }

    try {
      if (kIsWeb) {
        // For web, photo should already be base64
        String photoBase64 = photo is String ? photo : '';
        if (!photoBase64.startsWith('data:image')) {
          photoBase64 = 'data:image/jpeg;base64,$photoBase64';
        }
        return await _checkInWeb(token, location, photoBase64);
      } else {
        // For mobile, photo should be a File
        return await _checkInMobile(token, location, photo);
      }
    } catch (e) {
      print("Error detail saat check-in: $e");
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Metode untuk check-out yang menangani web dan mobile
  static Future<Map<String, dynamic>> checkOut(
    String location,
    dynamic photo, // Can be File (mobile) or base64 string (web)
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return {'success': false, 'message': 'Token tidak ditemukan'};
    }

    try {
      if (kIsWeb) {
        // For web, photo should already be base64
        String photoBase64 = photo is String ? photo : '';
        if (!photoBase64.startsWith('data:image')) {
          photoBase64 = 'data:image/jpeg;base64,$photoBase64';
        }
        return await _checkOutWeb(token, location, photoBase64);
      } else {
        // For mobile, photo should be a File
        return await _checkOutMobile(token, location, photo);
      }
    } catch (e) {
      print("Error detail saat check-out: $e");
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Implementasi checkIn untuk mobile
  static Future<Map<String, dynamic>> _checkInMobile(
    String token,
    String location,
    dynamic photoFile, // Bisa String (path) atau File
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/attendance/check-in'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['location'] = location;

      // Add photo file - PERBAIKAN
      if (photoFile != null) {
        File file;
        if (photoFile is String) {
          // Jika yang diterima adalah path string
          file = File(photoFile);
        } else if (photoFile is File) {
          // Jika sudah berupa File
          file = photoFile;
        } else {
          throw Exception('Tipe file tidak dikenali');
        }

        final fileStream = file.openRead();
        final length = await file.length();

        request.files.add(
          http.MultipartFile(
            'photo',
            fileStream,
            length,
            filename: DateTime.now().millisecondsSinceEpoch.toString() + '.jpg',
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Check-in gagal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Implementasi checkOut untuk mobile - PERBAIKAN
  static Future<Map<String, dynamic>> _checkOutMobile(
    String token,
    String location,
    dynamic photoFile, // Bisa String (path) atau File
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/attendance/check-out'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['location'] = location;

      // Add photo file - PERBAIKAN
      if (photoFile != null) {
        File file;
        if (photoFile is String) {
          // Jika yang diterima adalah path string
          file = File(photoFile);
        } else if (photoFile is File) {
          // Jika sudah berupa File
          file = photoFile;
        } else {
          throw Exception('Tipe file tidak dikenali');
        }

        final fileStream = file.openRead();
        final length = await file.length();

        request.files.add(
          http.MultipartFile(
            'photo',
            fileStream,
            length,
            filename: DateTime.now().millisecondsSinceEpoch.toString() + '.jpg',
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Check-out gagal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Implementasi checkIn untuk web (unchanged)
  static Future<Map<String, dynamic>> _checkInWeb(
    String token,
    String location,
    String photoBase64,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/check-in'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'location': location, 'photo': photoBase64}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Check-in gagal',
      };
    }
  }

  // Implementasi checkOut untuk web (unchanged)
  static Future<Map<String, dynamic>> _checkOutWeb(
    String token,
    String location,
    String photoBase64,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/check-out'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'location': location, 'photo': photoBase64}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Check-out gagal',
      };
    }
  }

  // Fungsi untuk mendapatkan data absensi hari ini (unchanged)
  static Future<Map<String, dynamic>?> getTodayAttendance() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/attendance/today'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        print(
          'Get attendance gagal: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error saat get attendance: $e');
      return null;
    }
  }
}
