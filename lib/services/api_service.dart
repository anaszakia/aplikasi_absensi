import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';

  // Fungsi untuk login
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

  // Fungsi untuk mendapatkan data user
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
    dynamic photo,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return {'success': false, 'message': 'Token tidak ditemukan'};
    }

    try {
      if (kIsWeb) {
        // Jika photo adalah URL blob, konversi ke base64 terlebih dahulu
        if (photo is String && photo.startsWith('blob:')) {
          try {
            final base64Photo = await _convertBlobToBase64(photo);
            if (base64Photo != null) {
              return await _checkInWeb(token, location, base64Photo);
            } else {
              return {'success': false, 'message': 'Gagal mengkonversi foto'};
            }
          } catch (e) {
            print('Error konversi blob ke base64: $e');
            return {'success': false, 'message': 'Error konversi foto: $e'};
          }
        } else {
          // Jika sudah dalam format base64
          return await _checkInWeb(token, location, photo);
        }
      } else {
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
    dynamic photo,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return {'success': false, 'message': 'Token tidak ditemukan'};
    }

    try {
      if (kIsWeb) {
        // Jika photo adalah URL blob, konversi ke base64 terlebih dahulu
        if (photo is String && photo.startsWith('blob:')) {
          try {
            final base64Photo = await _convertBlobToBase64(photo);
            if (base64Photo != null) {
              return await _checkOutWeb(token, location, base64Photo);
            } else {
              return {'success': false, 'message': 'Gagal mengkonversi foto'};
            }
          } catch (e) {
            print('Error konversi blob ke base64: $e');
            return {'success': false, 'message': 'Error konversi foto: $e'};
          }
        } else {
          // Jika sudah dalam format base64
          return await _checkOutWeb(token, location, photo);
        }
      } else {
        return await _checkOutMobile(token, location, photo);
      }
    } catch (e) {
      print("Error detail saat check-out: $e");
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Fungsi untuk mengkonversi URL blob ke base64
  static Future<String?> _convertBlobToBase64(String blobUrl) async {
    try {
      // Metode ini hanya berfungsi di lingkungan web
      if (!kIsWeb) {
        throw Exception('Konversi blob hanya tersedia di web');
      }

      // Buat XHR request untuk mengambil blob
      final request = html.HttpRequest();
      final completer = Completer<String>();

      request.open('GET', blobUrl, async: true);
      request.responseType = 'blob';

      request.onLoad.listen((e) {
        if (request.status == 200) {
          final blob = request.response as html.Blob;
          final reader = html.FileReader();

          reader.onLoad.listen((e) {
            final result = reader.result as String;
            completer.complete(result);
          });

          reader.onError.listen((e) {
            completer.completeError('Error membaca blob: ${e.toString()}');
          });

          reader.readAsDataUrl(blob);
        } else {
          completer.completeError('HTTP error: ${request.status}');
        }
      });

      request.onError.listen((e) {
        completer.completeError('Error request: ${e.toString()}');
      });

      request.send();
      return await completer.future;
    } catch (e) {
      print('Error konversi blob ke base64: $e');
      return null;
    }
  }

  // Implementasi checkIn untuk mobile
  static Future<Map<String, dynamic>> _checkInMobile(
    String token,
    String location,
    String photoPath,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/attendance/check-in'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields['location'] = location;

    // Tambahkan file foto
    try {
      request.files.add(await http.MultipartFile.fromPath('photo', photoPath));
    } catch (e) {
      print('Error saat menambahkan file foto: $e');
      return {'success': false, 'message': 'Error saat menambahkan foto: $e'};
    }

    // Kirim request
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
        'Response check-in mobile: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Check-in gagal',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Check-in gagal: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('Error saat mengirim request check-in: $e');
      return {'success': false, 'message': 'Error saat mengirim request: $e'};
    }
  }

  // Implementasi checkOut untuk mobile
  static Future<Map<String, dynamic>> _checkOutMobile(
    String token,
    String location,
    String photoPath,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/attendance/check-out'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields['location'] = location;

    // Tambahkan file foto
    try {
      request.files.add(await http.MultipartFile.fromPath('photo', photoPath));
    } catch (e) {
      print('Error saat menambahkan file foto: $e');
      return {'success': false, 'message': 'Error saat menambahkan foto: $e'};
    }

    // Kirim request
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
        'Response check-out mobile: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Check-out gagal',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Check-out gagal: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('Error saat mengirim request check-out: $e');
      return {'success': false, 'message': 'Error saat mengirim request: $e'};
    }
  }

  // Implementasi checkIn untuk web
  static Future<Map<String, dynamic>> _checkInWeb(
    String token,
    String location,
    String photoBase64,
  ) async {
    // Pastikan format base64 benar
    if (!photoBase64.startsWith('data:image')) {
      photoBase64 = 'data:image/jpeg;base64,' + photoBase64;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/attendance/check-in'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'location': location, 'photo': photoBase64}),
    );

    print('Response check-in web: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Check-in gagal',
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Check-in gagal: ${response.statusCode}',
        };
      }
    }
  }

  // Implementasi checkOut untuk web
  static Future<Map<String, dynamic>> _checkOutWeb(
    String token,
    String location,
    String photoBase64,
  ) async {
    // Pastikan format base64 benar
    if (!photoBase64.startsWith('data:image')) {
      photoBase64 = 'data:image/jpeg;base64,' + photoBase64;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/attendance/check-out'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'location': location, 'photo': photoBase64}),
    );

    print('Response check-out web: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Check-out gagal',
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Check-out gagal: ${response.statusCode}',
        };
      }
    }
  }

  // Fungsi untuk mendapatkan data absensi hari ini
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

      print(
        'Response get attendance today: ${response.statusCode} - ${response.body}',
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
