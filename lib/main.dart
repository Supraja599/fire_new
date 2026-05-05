import 'package:flutter/material.dart';
import 'signup.dart';
import 'icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/apiservice.dart';
import 'sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('inspectionBox');

  runApp(const MyApp());

  // ✅ Sync service start
  SyncService.init();
  SyncService.syncData();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
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
    _controller.dispose();
    super.dispose();
  }

  void login() async {
    String username = emailController.text.trim();
    String password = passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter username and password")),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await ApiService.login(username, password);

    setState(() => isLoading = false);

    if (result != null && result["token"] != null) {
      String token = result["token"];
      String role = result["user"]["role"];

      final box = Hive.box('inspectionBox');
      box.put('token', token);
      box.put('role', role);
      box.put('username', username);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const IconsPage()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid username or password")),
      );
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
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_rounded,
                        size: 90, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      "SOS EMERGENCY PLATFORM",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Inspection • Safety • Monitoring System",
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
                          decoration: boxStyle("Enter Username", Icons.person_outline),
                        ),

                        const SizedBox(height: 15),

                        /// PASSWORD (FIXED)
                        TextField(
                          controller: passController,
                          obscureText: !isPasswordVisible,
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
                            icon: const Icon(Icons.login),
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD50000),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            label: isLoading
                                ? const CircularProgressIndicator(
                                color: Colors.white)
                                : const Text("LOGIN TO SYSTEM"),
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