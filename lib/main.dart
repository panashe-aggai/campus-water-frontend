import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
      ),
      home: const LoginScreen(),
    );
  }
}

class ApiConfig {
  static const String baseUrl = 'https://campus-water-backend.onrender.com';
}

String bearingToCompass(double bearing) {
  const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final index = (((bearing + 22.5) % 360) ~/ 45).toInt();
  return directions[index];
}

double calculateBearing(
  double startLat,
  double startLng,
  double endLat,
  double endLng,
) {
  final startLatRad = startLat * math.pi / 180;
  final startLngRad = startLng * math.pi / 180;
  final endLatRad = endLat * math.pi / 180;
  final endLngRad = endLng * math.pi / 180;

  final dLng = endLngRad - startLngRad;

  final y = math.sin(dLng) * math.cos(endLatRad);
  final x = math.cos(startLatRad) * math.sin(endLatRad) -
      math.sin(startLatRad) * math.cos(endLatRad) * math.cos(dLng);

  final bearingRad = math.atan2(y, x);
  return (bearingRad * 180 / math.pi + 360) % 360;
}

double distanceMeters(
  double startLat,
  double startLng,
  double endLat,
  double endLng,
) {
  return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
}

enum MapBaseLayer { street, satellite }

class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String password;
  final String role;
  final bool isActive;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    required this.isActive,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      password: json['password'] ?? '',
      role: json['role'],
      isActive: json['is_active'],
    );
  }
}

class AssetPoint {
  final int id;
  final String assetName;
  final String assetType;
  final double latitude;
  final double longitude;
  final String conditionStatus;
  final String? notes;

  AssetPoint({
    required this.id,
    required this.assetName,
    required this.assetType,
    required this.latitude,
    required this.longitude,
    required this.conditionStatus,
    this.notes,
  });

  factory AssetPoint.fromJson(Map<String, dynamic> json) {
    return AssetPoint(
      id: json['id'],
      assetName: json['asset_name'],
      assetType: json['asset_type'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      conditionStatus: json['condition_status'],
      notes: json['notes'],
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
            .where(
              (u) =>
                  u.email.toLowerCase() ==
                      emailController.text.trim().toLowerCase() &&
                  u.password == passwordController.text.trim(),
            )
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
            const SnackBar(content: Text('Invalid email or password')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection error: $e')));
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
                    'Login with your email and password to access the field reporting system.',
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
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
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
                            label: Text(
                              isLoading ? 'Signing in...' : 'Sign In',
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

class HomeScreen extends StatefulWidget {
  final AppUser currentUser;

  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AssetPoint> assets = [];
  bool assetsLoading = true;
  Position? currentPosition;
  AssetPoint? selectedAsset;
  MapBaseLayer baseLayer = MapBaseLayer.street;

  @override
  void initState() {
    super.initState();
    loadAssets();
    loadCurrentLocation();
  }

  Future<void> loadAssets() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/assets'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          assets = data.map((e) => AssetPoint.fromJson(e)).toList();
          assetsLoading = false;
        });
      } else {
        setState(() => assetsLoading = false);
      }
    } catch (_) {
      setState(() => assetsLoading = false);
    }
  }

  Future<void> loadCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        currentPosition = position;
      });
    } catch (_) {}
  }

  String get mapUrl {
    switch (baseLayer) {
      case MapBaseLayer.street:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapBaseLayer.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }

  LatLng get initialCenter {
    if (currentPosition != null) {
      return LatLng(currentPosition!.latitude, currentPosition!.longitude);
    }
    if (assets.isNotEmpty) {
      return LatLng(assets.first.latitude, assets.first.longitude);
    }
    return const LatLng(-17.784, 31.053);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.currentUser;

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
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: Colors.white,
                  ),
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
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'logout', child: Text('Logout')),
                  ],
                ),
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
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'View Campus Map',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      DropdownButton<MapBaseLayer>(
                        value: baseLayer,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                            value: MapBaseLayer.street,
                            child: Text('Street'),
                          ),
                          DropdownMenuItem(
                            value: MapBaseLayer.satellite,
                            child: Text('Satellite'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => baseLayer = value);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap any asset point on the map, then navigate to it.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 320,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: assetsLoading
                          ? const Center(child: CircularProgressIndicator())
                          : FlutterMap(
                              options: MapOptions(
                                initialCenter: initialCenter,
                                initialZoom: 16,
                                onTap: (_, __) {
                                  setState(() {
                                    selectedAsset = null;
                                  });
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: mapUrl,
                                  userAgentPackageName: 'com.example.mobile_app',
                                ),
                                if (currentPosition != null)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          currentPosition!.latitude,
                                          currentPosition!.longitude,
                                        ),
                                        width: 60,
                                        height: 60,
                                        child: const Icon(
                                          Icons.my_location,
                                          color: Colors.blue,
                                          size: 30,
                                        ),
                                      ),
                                    ],
                                  ),
                                MarkerLayer(
                                  markers: assets.map((asset) {
                                    return Marker(
                                      point: LatLng(
                                        asset.latitude,
                                        asset.longitude,
                                      ),
                                      width: 70,
                                      height: 70,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedAsset = asset;
                                          });
                                        },
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          color: Colors.red,
                                          size: 42,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (selectedAsset != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedAsset!.assetName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${selectedAsset!.assetType} • ${selectedAsset!.conditionStatus}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${selectedAsset!.latitude}, ${selectedAsset!.longitude}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          if ((selectedAsset!.notes ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(selectedAsset!.notes!),
                          ],
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InAppNavigationScreen(
                                    destinationName: selectedAsset!.assetName,
                                    destinationLat: selectedAsset!.latitude,
                                    destinationLng: selectedAsset!.longitude,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.navigation_rounded),
                            label: const Text('Navigate to Selected Point'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _FeatureCard(
              title: 'Add Water Asset',
              subtitle:
                  'Register taps, boreholes, tanks, valves and sewer points',
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
              subtitle:
                  'Submit burst pipes, leakages, sewage blockages and damage',
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
          ],
        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('GPS error: $e')));
    }
  }

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 75);

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Photo error: $e')));
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
      "created_by": widget.currentUser.id,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void openMapPreview() {
    final lat = double.tryParse(latitudeController.text.trim());
    final lng = double.tryParse(longitudeController.text.trim());

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture or enter valid coordinates first'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPreviewScreen(
          title: assetNameController.text.trim().isEmpty
              ? 'Asset Point'
              : assetNameController.text.trim(),
          latitude: lat,
          longitude: lng,
        ),
      ),
    );
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
    return _FormScaffold(
      title: 'Add Water Asset',
      subtitle: 'Capture infrastructure details for field mapping',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: assetNameController,
              decoration: const InputDecoration(
                labelText: 'Asset Name',
                hintText: 'e.g. Admin Block Tap',
              ),
              validator: (value) => value == null || value.trim().isEmpty
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
                DropdownMenuItem(
                  value: 'water_tank',
                  child: Text('Water Tank'),
                ),
                DropdownMenuItem(value: 'valve', child: Text('Valve')),
                DropdownMenuItem(
                  value: 'pipeline_point',
                  child: Text('Pipeline Point'),
                ),
                DropdownMenuItem(value: 'manhole', child: Text('Manhole')),
                DropdownMenuItem(
                  value: 'sewer_point',
                  child: Text('Sewer Point'),
                ),
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
                DropdownMenuItem(
                  value: 'non_functional',
                  child: Text('Non Functional'),
                ),
              ],
              onChanged: (value) => setState(() => conditionStatus = value!),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: getCurrentLocation,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Use GPS'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: openMapPreview,
              icon: const Icon(Icons.map_rounded),
              label: const Text('Preview on Map'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                final lat = double.tryParse(latitudeController.text.trim());
                final lng = double.tryParse(longitudeController.text.trim());
                if (lat == null || lng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid coordinates first'),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InAppNavigationScreen(
                      destinationName: assetNameController.text.trim().isEmpty
                          ? 'Asset Point'
                          : assetNameController.text.trim(),
                      destinationLat: lat,
                      destinationLng: lng,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('Navigate'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: latitudeController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g. -17.825',
              ),
              validator: (value) => value == null || value.trim().isEmpty
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
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter longitude'
                  : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: showPhotoOptions,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Take / Choose Photo'),
            ),
            const SizedBox(height: 14),
            if (selectedImage != null) Text('Selected: ${selectedImage!.name}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Add any remarks about this asset',
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('GPS error: $e')));
    }
  }

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 75);

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Photo error: $e')));
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
      "reported_by": widget.currentUser.id,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void openMapPreview() {
    final lat = double.tryParse(latitudeController.text.trim());
    final lng = double.tryParse(longitudeController.text.trim());

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture or enter valid coordinates first'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPreviewScreen(
          title: incidentNameController.text.trim().isEmpty
              ? 'Incident Point'
              : incidentNameController.text.trim(),
          latitude: lat,
          longitude: lng,
        ),
      ),
    );
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
    return _FormScaffold(
      title: 'Report Incident',
      subtitle: 'Capture faults, damage and field emergencies',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: incidentNameController,
              decoration: const InputDecoration(
                labelText: 'Incident Name',
                hintText: 'e.g. Burst near Hostel A',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter incident name'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: incidentType,
              decoration: const InputDecoration(labelText: 'Incident Type'),
              items: const [
                DropdownMenuItem(
                  value: 'burst_pipe',
                  child: Text('Burst Pipe'),
                ),
                DropdownMenuItem(value: 'leakage', child: Text('Leakage')),
                DropdownMenuItem(
                  value: 'sewage_blockage',
                  child: Text('Sewage Blockage'),
                ),
                DropdownMenuItem(
                  value: 'damaged_asset',
                  child: Text('Damaged Asset'),
                ),
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
                DropdownMenuItem(
                  value: 'under_repair',
                  child: Text('Under Repair'),
                ),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
              ],
              onChanged: (value) => setState(() => conditionStatus = value!),
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: getCurrentLocation,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Use GPS'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: openMapPreview,
              icon: const Icon(Icons.map_rounded),
              label: const Text('Preview on Map'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                final lat = double.tryParse(latitudeController.text.trim());
                final lng = double.tryParse(longitudeController.text.trim());
                if (lat == null || lng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid coordinates first'),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InAppNavigationScreen(
                      destinationName:
                          incidentNameController.text.trim().isEmpty
                          ? 'Incident Point'
                          : incidentNameController.text.trim(),
                      destinationLat: lat,
                      destinationLng: lng,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('Navigate'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: latitudeController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g. -17.8251',
              ),
              validator: (value) => value == null || value.trim().isEmpty
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
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter longitude'
                  : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: showPhotoOptions,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Take / Choose Photo'),
            ),
            const SizedBox(height: 14),
            if (selectedImage != null) Text('Selected: ${selectedImage!.name}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Describe what was observed in the field',
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: isLoading ? null : submitIncident,
              icon: Icon(
                isLoading
                    ? Icons.hourglass_top_rounded
                    : Icons.send_rounded,
              ),
              label: Text(isLoading ? 'Submitting...' : 'Submit Incident'),
            ),
          ],
        ),
      ),
    );
  }
}

class MapPreviewScreen extends StatelessWidget {
  final String title;
  final double latitude;
  final double longitude;

  const MapPreviewScreen({
    super.key,
    required this.title,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: 17,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mobile_app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 42,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InAppNavigationScreen(
                    destinationName: title,
                    destinationLat: latitude,
                    destinationLng: longitude,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.navigation_rounded),
            label: const Text('Start In-App Navigation'),
          ),
        ),
      ),
    );
  }
}

class InAppNavigationScreen extends StatefulWidget {
  final String destinationName;
  final double destinationLat;
  final double destinationLng;

  const InAppNavigationScreen({
    super.key,
    required this.destinationName,
    required this.destinationLat,
    required this.destinationLng,
  });

  @override
  State<InAppNavigationScreen> createState() => _InAppNavigationScreenState();
}

class _InAppNavigationScreenState extends State<InAppNavigationScreen> {
  Position? currentPosition;
  StreamSubscription<Position>? positionStream;
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    startTracking();
  }

  Future<void> startTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          loading = false;
          errorMessage = 'Location service is disabled';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          loading = false;
          errorMessage = 'Location permission denied';
        });
        return;
      }

      final firstPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        currentPosition = firstPosition;
        loading = false;
      });

      positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).listen((position) {
        if (!mounted) return;
        setState(() {
          currentPosition = position;
        });
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = 'Navigation error: $e';
      });
    }
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destination = LatLng(widget.destinationLat, widget.destinationLng);

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('In-App Navigation')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('In-App Navigation')),
        body: Center(child: Text(errorMessage!)),
      );
    }

    final current = LatLng(currentPosition!.latitude, currentPosition!.longitude);

    final meters = distanceMeters(
      current.latitude,
      current.longitude,
      widget.destinationLat,
      widget.destinationLng,
    );

    final bearing = calculateBearing(
      current.latitude,
      current.longitude,
      widget.destinationLat,
      widget.destinationLng,
    );

    final direction = bearingToCompass(bearing);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destinationName),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: current,
                initialZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mobile_app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [current, destination],
                      strokeWidth: 5,
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: current,
                      width: 70,
                      height: 70,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 34,
                      ),
                    ),
                    Marker(
                      point: destination,
                      width: 70,
                      height: 70,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.red,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.destinationName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Distance remaining: ${meters.toStringAsFixed(0)} m',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  'Direction: $direction',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  'Move $direction toward the selected point',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _FormScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
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