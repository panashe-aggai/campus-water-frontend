import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const CampusWaterApp());
}

class CampusWaterApp extends StatelessWidget {
  const CampusWaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Water System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F62FE),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF111827),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.4),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            backgroundColor: const Color(0xFF0F62FE),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class ApiConfig {
 static const String baseUrl = 'https://campus-water-backend.onrender.com';
  // Later for Android phones on same Wi-Fi:
  // static const String baseUrl = 'http://YOUR-LAPTOP-IP:8000';
}

class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      role: json['role'],
      isActive: json['is_active'],
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/users'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final matchingUsers = data
            .map((e) => AppUser.fromJson(e))
            .where((u) =>
                u.email.toLowerCase() ==
                emailController.text.trim().toLowerCase())
            .toList();

        if (matchingUsers.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(currentUser: matchingUsers.first),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 86,
                    width: 86,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F62FE), Color(0xFF2563EB)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x330F62FE),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Campus Water System',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Premium field data collection for water assets and incident reporting.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'e.g. worker1@campuswater.local',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Enter email'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Demo only for now',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Enter password'
                                    : null,
                          ),
                          const SizedBox(height: 22),
                          ElevatedButton.icon(
                            onPressed: isLoading ? null : login,
                            icon: Icon(
                              isLoading
                                  ? Icons.hourglass_top_rounded
                                  : Icons.login_rounded,
                            ),
                            label:
                                Text(isLoading ? 'Signing in...' : 'Sign In'),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Current demo login matches users by email from the backend.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final AppUser currentUser;

  const HomeScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F62FE), Color(0xFF3B82F6)],
                    ),
                  ),
                  child: const Icon(Icons.apartment_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Campus Water System',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome, ${currentUser.fullName}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout') {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F62FE), Color(0xFF1D4ED8)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x330F62FE),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Premium Field Workflow',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Role: ${currentUser.role}',
                    style: const TextStyle(
                      color: Color(0xFFE5EDFF),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: _MiniStat(label: 'Assets', value: 'Live')),
                      SizedBox(width: 10),
                      Expanded(child: _MiniStat(label: 'Reports', value: 'Track')),
                      SizedBox(width: 10),
                      Expanded(child: _MiniStat(label: 'Sync', value: 'Ready')),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            _FeatureCard(
              title: 'Add Water Asset',
              subtitle: 'Register taps, boreholes, tanks, valves and sewer points',
              icon: Icons.water_drop_rounded,
              iconColor: const Color(0xFF0F62FE),
              backgroundTint: const Color(0xFFEAF2FF),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddAssetScreen(currentUser: currentUser),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _FeatureCard(
              title: 'Report Incident',
              subtitle: 'Submit burst pipes, leakages, sewage blockages and damage',
              icon: Icons.report_problem_rounded,
              iconColor: const Color(0xFFEF4444),
              backgroundTint: const Color(0xFFFFEEEE),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddIncidentScreen(currentUser: currentUser),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            const _ComingSoonCard(),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE5EDFF),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundTint;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundTint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: backgroundTint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.camera_alt_rounded, color: Colors.white),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPS & Photos Enabled',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Workers can capture coordinates and attach photo evidence.',
                  style: TextStyle(color: Color(0xFFD1D5DB)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class AddAssetScreen extends StatefulWidget {
  final AppUser currentUser;

  const AddAssetScreen({super.key, required this.currentUser});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final assetNameController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  final notesController = TextEditingController();

  String assetType = 'tap';
  String conditionStatus = 'working';
  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();
  XFile? selectedImage;
  Uint8List? webImageBytes;

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location service is disabled')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitudeController.text = position.latitude.toString();
      longitudeController.text = position.longitude.toString();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS location captured')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS error: $e')),
      );
    }
  }

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 75,
      );

      if (image == null) return;

      Uint8List? bytes;
      if (kIsWeb) {
        bytes = await image.readAsBytes();
      }

      setState(() {
        selectedImage = image;
        webImageBytes = bytes;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo selected successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo error: $e')),
      );
    }
  }

  Future<void> showPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> submitAsset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final body = {
      "asset_name": assetNameController.text.trim(),
      "asset_type": assetType,
      "latitude": double.parse(latitudeController.text.trim()),
      "longitude": double.parse(longitudeController.text.trim()),
      "condition_status": conditionStatus,
      "photo_path": selectedImage?.name,
      "notes": notesController.text.trim(),
      "created_by": widget.currentUser.id
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/assets'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Water asset submitted successfully')),
        );

        assetNameController.clear();
        latitudeController.clear();
        longitudeController.clear();
        notesController.clear();

        setState(() {
          selectedImage = null;
          webImageBytes = null;
          assetType = 'tap';
          conditionStatus = 'working';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    assetNameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumFormScaffold(
      title: 'Add Water Asset',
      subtitle: 'Capture infrastructure details for field mapping',
      icon: Icons.water_drop_rounded,
      iconColor: const Color(0xFF0F62FE),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _SectionCard(
              title: 'Asset Information',
              child: Column(
                children: [
                  TextFormField(
                    controller: assetNameController,
                    decoration: const InputDecoration(
                      labelText: 'Asset Name',
                      hintText: 'e.g. Admin Block Tap',
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter asset name'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: assetType,
                    decoration: const InputDecoration(labelText: 'Asset Type'),
                    items: const [
                      DropdownMenuItem(value: 'tap', child: Text('Tap')),
                      DropdownMenuItem(value: 'borehole', child: Text('Borehole')),
                      DropdownMenuItem(value: 'water_tank', child: Text('Water Tank')),
                      DropdownMenuItem(value: 'valve', child: Text('Valve')),
                      DropdownMenuItem(value: 'pipeline_point', child: Text('Pipeline Point')),
                      DropdownMenuItem(value: 'manhole', child: Text('Manhole')),
                      DropdownMenuItem(value: 'sewer_point', child: Text('Sewer Point')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) => setState(() => assetType = value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: conditionStatus,
                    decoration: const InputDecoration(labelText: 'Condition'),
                    items: const [
                      DropdownMenuItem(value: 'working', child: Text('Working')),
                      DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                      DropdownMenuItem(value: 'non_functional', child: Text('Non Functional')),
                    ],
                    onChanged: (value) =>
                        setState(() => conditionStatus = value!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Location',
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: getCurrentLocation,
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Use GPS'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: 'e.g. -17.825',
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter latitude'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: 'e.g. 31.053',
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter longitude'
                            : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Photo Evidence',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: showPhotoOptions,
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Take / Choose Photo'),
                  ),
                  const SizedBox(height: 14),
                  if (selectedImage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected: ${selectedImage!.name}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          if (kIsWeb && webImageBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                webImageBytes!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            const Text(
                              'Photo attached successfully',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Notes',
              child: TextFormField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add any remarks about this asset',
                ),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: isLoading ? null : submitAsset,
              icon: Icon(
                isLoading
                    ? Icons.hourglass_top_rounded
                    : Icons.cloud_upload_rounded,
              ),
              label: Text(isLoading ? 'Submitting...' : 'Submit Asset'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddIncidentScreen extends StatefulWidget {
  final AppUser currentUser;

  const AddIncidentScreen({super.key, required this.currentUser});

  @override
  State<AddIncidentScreen> createState() => _AddIncidentScreenState();
}

class _AddIncidentScreenState extends State<AddIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final incidentNameController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  final notesController = TextEditingController();

  String incidentType = 'burst_pipe';
  String conditionStatus = 'active';
  String severity = 'medium';
  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();
  XFile? selectedImage;
  Uint8List? webImageBytes;

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location service is disabled')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitudeController.text = position.latitude.toString();
      longitudeController.text = position.longitude.toString();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS location captured')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS error: $e')),
      );
    }
  }

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 75,
      );

      if (image == null) return;

      Uint8List? bytes;
      if (kIsWeb) {
        bytes = await image.readAsBytes();
      }

      setState(() {
        selectedImage = image;
        webImageBytes = bytes;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo selected successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo error: $e')),
      );
    }
  }

  Future<void> showPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> submitIncident() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final body = {
      "incident_name": incidentNameController.text.trim(),
      "incident_type": incidentType,
      "related_asset_id": null,
      "latitude": double.parse(latitudeController.text.trim()),
      "longitude": double.parse(longitudeController.text.trim()),
      "condition_status": conditionStatus,
      "severity": severity,
      "photo_path": selectedImage?.name,
      "notes": notesController.text.trim(),
      "reported_by": widget.currentUser.id
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/incidents'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident submitted successfully')),
        );

        incidentNameController.clear();
        latitudeController.clear();
        longitudeController.clear();
        notesController.clear();

        setState(() {
          selectedImage = null;
          webImageBytes = null;
          incidentType = 'burst_pipe';
          conditionStatus = 'active';
          severity = 'medium';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    incidentNameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumFormScaffold(
      title: 'Report Incident',
      subtitle: 'Capture faults, damage and field emergencies',
      icon: Icons.report_problem_rounded,
      iconColor: const Color(0xFFEF4444),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _SectionCard(
              title: 'Incident Information',
              child: Column(
                children: [
                  TextFormField(
                    controller: incidentNameController,
                    decoration: const InputDecoration(
                      labelText: 'Incident Name',
                      hintText: 'e.g. Burst near Hostel A',
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter incident name'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: incidentType,
                    decoration: const InputDecoration(labelText: 'Incident Type'),
                    items: const [
                      DropdownMenuItem(value: 'burst_pipe', child: Text('Burst Pipe')),
                      DropdownMenuItem(value: 'leakage', child: Text('Leakage')),
                      DropdownMenuItem(value: 'sewage_blockage', child: Text('Sewage Blockage')),
                      DropdownMenuItem(value: 'damaged_asset', child: Text('Damaged Asset')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) => setState(() => incidentType = value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: conditionStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'under_repair', child: Text('Under Repair')),
                      DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                    ],
                    onChanged: (value) =>
                        setState(() => conditionStatus = value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: severity,
                    decoration: const InputDecoration(labelText: 'Severity'),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (value) => setState(() => severity = value!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Location',
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: getCurrentLocation,
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Use GPS'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: 'e.g. -17.8251',
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter latitude'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: 'e.g. 31.0532',
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter longitude'
                            : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Photo Evidence',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: showPhotoOptions,
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Take / Choose Photo'),
                  ),
                  const SizedBox(height: 14),
                  if (selectedImage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected: ${selectedImage!.name}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          if (kIsWeb && webImageBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                webImageBytes!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            const Text(
                              'Photo attached successfully',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Notes',
              child: TextFormField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Describe what was observed in the field',
                ),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: isLoading ? null : submitIncident,
              icon: Icon(
                isLoading ? Icons.hourglass_top_rounded : Icons.send_rounded,
              ),
              label: Text(isLoading ? 'Submitting...' : 'Submit Incident'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumFormScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _PremiumFormScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}