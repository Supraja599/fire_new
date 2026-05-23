import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'signup.dart';
import 'icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/apiservice.dart';
import 'sync_service.dart';
import 'local_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  final box = await Hive.openBox('inspectionBox');

  // ✅ Removed Auto-Login for main page as requested

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());

  // ✅ Sync service start
  SyncService.init();
  SyncService.syncData();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SOS Emergency Platform',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: const Color(0xFFD50000),
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.1),
          ),
          child: child!,
        );
      },
      home: const LoginPage(),
    );
  }
}

////////////////////////////////////////////////////////////
/// 🔐 LOGIN PAGE (FIXED INPUT UI – NO FLOATING LABEL)
////////////////////////////////////////////////////////////

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passController = TextEditingController();

  bool isPasswordVisible = false;
  bool isLoading = false;

  late AnimationController _controller;
  late Animation<double> fadeAnim;
  late Animation<Offset> slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final username = emailController.text.trim();
    final password = passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter credentials")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await ApiService.login(username, password);
      
      if (result != null && result["token"] != null) {
        final box = Hive.box('inspectionBox');
        box.put('token', result["token"]);
        box.put('username', username);
        box.put('role', result["user"]["role"] ?? "User");
        box.put('modules', result["user"]["modules"] ?? []);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const IconsPage()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login failed. Invalid credentials.")),
          );
        }
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      final isNetworkError = errStr.contains('socket') ||
          errStr.contains('handshake') ||
          errStr.contains('timeout') ||
          errStr.contains('clientexception') ||
          errStr.contains('network') ||
          errStr.contains('failed host lookup');

      if (mounted) {
        if (isNetworkError) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 10),
                  Text("No Connection", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                "Could not connect to the server. Please check your internet connection and try again.",
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("OK", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${e.toString()}")),
          );
        }
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  InputDecoration boxStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint, // ✅ IMPORTANT: NO LABEL TEXT
      prefixIcon: Icon(icon, color: const Color(0xFFD50000)),
      filled: true,
      fillColor: Colors.grey.shade100,

      // FIX: no floating label issue
      floatingLabelBehavior: FloatingLabelBehavior.never,

      contentPadding: const EdgeInsets.symmetric(vertical: 18),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      body: SingleChildScrollView(
        child: Column(
          children: [

            /// HEADER
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD50000), Color(0xFF8E0000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center, // Force center
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        size: 90, color: Colors.white),
                    const SizedBox(height: 10),
                    Text(
                      "SOS EMERGENCY PLATFORM",
                      textAlign: TextAlign.center, // Center text
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Inspection • Safety • Monitoring System",
                      textAlign: TextAlign.center, // Center text
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// LOGIN CARD
            FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(
                position: slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [

                        const Text(
                          "SYSTEM LOGIN",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD50000),
                          ),
                        ),

                        const SizedBox(height: 25),

                        /// USERNAME (FIXED)
                        TextField(
                          controller: emailController,
                          selectAllOnFocus: false,
                          decoration: boxStyle("Enter Username", Icons.person_outline),
                        ),

                        const SizedBox(height: 15),

                        /// PASSWORD (FIXED)
                        TextField(
                          controller: passController,
                          obscureText: !isPasswordVisible,
                          selectAllOnFocus: false,
                          decoration: boxStyle("Enter Password", Icons.key_outlined).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        /// LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.login, color: Colors.white),
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD50000),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            label: isLoading
                                ? const CircularProgressIndicator(
                                color: Colors.white)
                                : const Text(
                                    "LOGIN TO SYSTEM",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          "Authorized Access Only",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
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
}

////////////////////////////////////////////////////////////
/// WAVE CLIPPER
////////////////////////////////////////////////////////////

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, size.height - 60);

    path.quadraticBezierTo(
      size.width / 2,
      size.height + 40,
      size.width,
      size.height - 60,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}