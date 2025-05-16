import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:absensi_app/services/api_service.dart';
import 'attendance_history_page.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import untuk inisialisasi locale

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool loading = false;
  String? message;
  String? messageType;
  DateTime now = DateTime.now();
  bool isDateInitialized = false;

  // Warna tema aplikasi
  final Color primaryColor = Color(0xFFE53935); // Merah
  final Color accentColor = Color(0xFF1E88E5); // Biru
  final Color backgroundColor = Color(0xFFF5F5F5); // Abu-abu muda
  final Color cardColor = Colors.white;
  final Color successColor = Color(0xFF43A047); // Hijau

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();

    // Timer untuk update waktu setiap detik
    _startClock();
  }

  // Metode untuk menginisialisasi locale data
  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('id_ID', null);
    setState(() {
      isDateInitialized = true;
      now = DateTime.now();
    });
  }

  // Metode untuk memulai clock update
  void _startClock() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          now = DateTime.now();
        });
        _startClock(); // Memanggil kembali untuk update setiap detik
      }
    });
  }

  Future<String?> _getLocation() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return null;
    }
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return null;
    }
    LocationData locationData = await location.getLocation();
    return '${locationData.latitude},${locationData.longitude}';
  }

  Future<void> _checkIn() async {
    setState(() {
      loading = true;
      message = null;
    });
    final location = await _getLocation();
    if (location == null) {
      setState(() {
        loading = false;
        message = 'Gagal mendapatkan lokasi';
        messageType = 'error';
      });
      return;
    }
    final success = await ApiService.checkIn(location);
    setState(() {
      loading = false;
      message = success ? 'Absen Masuk berhasil' : 'Absen Masuk gagal';
      messageType = success ? 'success' : 'error';
    });
  }

  Future<void> _checkOut() async {
    setState(() {
      loading = true;
      message = null;
    });
    final location = await _getLocation();
    if (location == null) {
      setState(() {
        loading = false;
        message = 'Gagal mendapatkan lokasi';
        messageType = 'error';
      });
      return;
    }
    final success = await ApiService.checkOut(location);
    setState(() {
      loading = false;
      message = success ? 'Absen Pulang berhasil' : 'Absen Pulang gagal';
      messageType = success ? 'success' : 'error';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Hanya format tanggal jika locale sudah diinisialisasi
    String formattedDate =
        isDateInitialized
            ? DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now)
            : "Memuat...";
    String formattedTime = DateFormat('HH:mm:ss').format(now);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: Text(
          'Sistem Absensi',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AttendanceHistoryPage()),
              );
            },
            tooltip: 'Riwayat Absensi',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Top curved section
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and time card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tanggal',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    formattedTime,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 30),

                    // Attendance actions
                    Text(
                      'Pencatatan Kehadiran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 16),

                    // Message display
                    if (message != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color:
                              messageType == 'success'
                                  ? successColor.withOpacity(0.2)
                                  : primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                messageType == 'success'
                                    ? successColor
                                    : primaryColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              messageType == 'success'
                                  ? Icons.check_circle
                                  : Icons.error,
                              color:
                                  messageType == 'success'
                                      ? successColor
                                      : primaryColor,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                message!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      messageType == 'success'
                                          ? successColor
                                          : primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Check-in and Check-out buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildAttendanceCard(
                            title: 'Absen Masuk',
                            icon: Icons.login,
                            color: primaryColor,
                            onPressed: loading ? null : _checkIn,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildAttendanceCard(
                            title: 'Absen Pulang',
                            icon: Icons.logout,
                            color: accentColor,
                            onPressed: loading ? null : _checkOut,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 30),

                    // Information
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: primaryColor),
                                SizedBox(width: 8),
                                Text(
                                  'Informasi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Divider(),
                            SizedBox(height: 8),
                            _buildInfoItem(
                              'Pastikan lokasi Anda aktif ketika melakukan absensi',
                              Icons.location_on,
                            ),
                            SizedBox(height: 12),
                            _buildInfoItem(
                              'Periksa riwayat absensi di menu sebelah kanan atas',
                              Icons.history,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading indicator
            if (loading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('Memproses...', style: TextStyle()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }
}
