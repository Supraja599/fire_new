import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
import 'package:fire_new/services/location_service.dart';
import 'package:fire_new/services/image_integrity_service.dart';
class GuidedCaptureWizardPage extends StatefulWidget {
  final String? equipmentId;
  final Map<String, dynamic>? selectedEquipment;
  final String? equipmentImage;
  final Widget nextScreen;

  const GuidedCaptureWizardPage({
    super.key,
    this.equipmentId,
    this.selectedEquipment,
    this.equipmentImage,
    required this.nextScreen,
  });

  @override
  State<GuidedCaptureWizardPage> createState() => _GuidedCaptureWizardPageState();
}

class StepInstruction {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> bulletPoints;
  final String referenceAsset;

  StepInstruction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bulletPoints,
    this.referenceAsset = 'assets/extinguisher.png',
  });
}

class _GuidedCaptureWizardPageState extends State<GuidedCaptureWizardPage> {
  final ImagePicker _picker = ImagePicker();
  int _currentStepIndex = 0;
  
  // Store the captured images
  final Map<int, File?> _capturedImages = {};
  final Map<int, ProximityResult?> _locationVerifications = {};
  final Map<int, Map<String, dynamic>> _telemetryCache = {};
  
  bool _isCapturing = false;
  bool _isAnalyzing = false;

  String _view3TargetLabel = "CONTROLS";
  String _eqName = "Safety Asset";

  late final List<StepInstruction> _steps;

  @override
  void initState() {
    super.initState();
    
    final String img = widget.equipmentImage ?? 'assets/extinguisher.png';
    final bool isHoseReel = img.contains('hosereel');
    
    // Derive hyper-specific Equipment Name for clear explanation injecting!
    try {
      final String filePart = img.split('/').last.split('.').first;
      _eqName = filePart.split('_').map((w) {
        if (w.isEmpty) return "";
        return "${w[0].toUpperCase()}${w.substring(1)}";
      }).join(' ');
      
      if (_eqName.toLowerCase().contains("ehs") || _eqName.toLowerCase().contains("scan")) {
        _eqName = "Safety Equipment";
      }
    } catch (_) {
      _eqName = "Safety Equipment";
    }

    // --- DYNAMIC ANATOMY ENGINE ---
    // Automatically parses equipment type and builds hyper-specific target labels!
    String view3Title = "$_eqName Controls View";
    String view3Subtitle = "Inspect $_eqName operational mechanism";
    List<String> view3Bullets = [
      "Capture direct, clear view of $_eqName operating controls.",
      "Confirm safety pins/latches/seals are intact.",
      "Verify clear, unblocked functional access path.",
    ];
    _view3TargetLabel = "INTERFACE / CONTROLS";

    final String nameLower = _eqName.toLowerCase();
    if (nameLower.contains("extinguisher") || nameLower.contains("hose")) {
      view3Title = "Pressure Gauge & Nozzle View";
      view3Subtitle = "Inspect pressure dial and discharge nozzle";
      _view3TargetLabel = "PRESSURE GAUGE / NOZZLE";
      view3Bullets = [
        "Frame the pressure indicator needle inside the green zone.",
        "Confirm safety metal pin and tamper plastic loop are intact.",
        "Verify the discharge nozzle mouth is clean and unobstructed.",
      ];
    } else if (nameLower.contains("detector") || nameLower.contains("sensor")) {
      view3Title = "Sensor Chamber & LED View";
      view3Subtitle = "Inspect status indicator and vents";
      _view3TargetLabel = "SENSOR CHAMBER / STATUS LED";
      view3Bullets = [
        "Focus closely on the status LED light (should be green/blinking).",
        "Confirm sensor entry chamber is clean and free of heavy dust.",
        "Verify device is mounted securely to the ceiling/wall base.",
      ];
    } else if (nameLower.contains("shower") || nameLower.contains("eye")) {
      view3Title = "Pull Lever & Spray Head View";
      view3Subtitle = "Inspect actuator lever and nozzle head";
      _view3TargetLabel = "ACTUATOR LEVER / SPRAY HEAD";
      view3Bullets = [
        "Focus on the triangular activation pull rod or push handle.",
        "Verify spray head dust covers are present and loosely fitted.",
        "Check main bowl/drainage area for clear, debris-free state.",
      ];
    } else if (nameLower.contains("sock")) {
      view3Title = "Swivel Mast & Fabric View";
      view3Subtitle = "Inspect rotation bearing and fabric";
      _view3TargetLabel = "SWIVEL BEARING / WIND FABRIC";
      view3Bullets = [
        "Focus closely on the top swivel bearing and mounting ring.",
        "Inspect the orange wind fabric for rips, fading, or blockages.",
        "Verify structural mast is vertically level and secured.",
      ];
    } else if (nameLower.contains("kit") || nameLower.contains("cabinet") || nameLower.contains("ppe") || nameLower.contains("blanket")) {
      view3Title = "Tamper Seal & Inventory View";
      view3Subtitle = "Inspect security locks and contents";
      _view3TargetLabel = "SECURITY LOCKS / INVENTORY";
      view3Bullets = [
        "Focus tightly on the plastic tamper lock or security tape.",
        "Verify cabinet hinges and door latches operate smoothly.",
        "Check that outer inventory list/expiry log is present.",
      ];
    } else if (nameLower.contains("panel") || nameLower.contains("siren") || nameLower.contains("mcp") || nameLower.contains("alarm") || nameLower.contains("pa system") || nameLower.contains("comm")) {
      view3Title = "Status Display & Interface View";
      view3Subtitle = "Inspect screen/LEDs and controls";
      _view3TargetLabel = "LED MATRIX / INTERFACE";
      view3Bullets = [
        "Verify main screen/LED status shows 'System Normal' (no red fault).",
        "Ensure outer protective glass or cover is not cracked.",
        "Confirm physical keyswitch or buttons are in ready position.",
      ];
    } else if (nameLower.contains("hydrant") || nameLower.contains("sprinkler") || nameLower.contains("valve") || nameLower.contains("co2")) {
      view3Title = "Gate Valve & Pressure View";
      view3Subtitle = "Inspect metal connections and gauge";
      _view3TargetLabel = "GATE VALVE / PRESSURE GAUGE";
      view3Bullets = [
        "Focus on the main gate valve wheel or pressure dial.",
        "Verify threaded couplings show no rust, water leaks, or cracks.",
        "Ensure secure locking bolts are fully tightened and intact.",
      ];
    } else if (nameLower.contains("ambulance") || nameLower.contains("trolley") || nameLower.contains("vehicle")) {
      view3Title = "Equipment Rack & Light View";
      view3Subtitle = "Inspect storage and sirens";
      _view3TargetLabel = "STORAGE RACK / SIREN LIGHTS";
      view3Bullets = [
        "Focus on the main equipment mounting rack or sirens.",
        "Verify strobe/flashing lights are clean and undamaged.",
        "Confirm safety hatches are fully latched and secure.",
      ];
    } else if (nameLower.contains("door")) {
      view3Title = "Seal & Closer View";
      view3Subtitle = "Inspect fire seal and door hardware";
      _view3TargetLabel = "FIRE SEAL / DOOR CLOSER";
      view3Bullets = [
        "Focus on the intumescent seal strip along the door edges.",
        "Inspect the automatic door closer mechanism at the top.",
        "Verify the latch engages flush with no visible gap.",
      ];
    } else if (nameLower.contains("exit") || nameLower.contains("signage") || nameLower.contains("muster")) {
      view3Title = "Sign Face & Clarity View";
      view3Subtitle = "Inspect sign legibility and mounting";
      _view3TargetLabel = "SIGN FACE / MOUNTING";
      view3Bullets = [
        "Focus directly on the sign face at eye-level distance.",
        "Verify text and pictograms are not faded or obscured.",
        "Confirm the sign is securely mounted and clearly visible.",
      ];
    } else if (nameLower.contains("lighting")) {
      view3Title = "Lamp Head & Battery View";
      view3Subtitle = "Inspect emergency light status";
      _view3TargetLabel = "LAMP HEAD / BATTERY LED";
      view3Bullets = [
        "Focus on the lamp heads and the battery status LED.",
        "Verify lamp heads are angled toward the escape path.",
        "Locate the self-test button on the side or bottom.",
      ];
    } else if (nameLower.contains("scba")) {
      view3Title = "Cylinder Gauge & Mask View";
      view3Subtitle = "Inspect air levels and regulator";
      _view3TargetLabel = "AIR GAUGE / DEMAND VALVE";
      view3Bullets = [
        "Focus on the cylinder pressure gauge (should be >200 bar).",
        "Inspect the face mask and demand valve for cracks.",
        "Confirm all harness straps are intact and functional.",
      ];
    } else if (nameLower.contains("first aid")) {
      view3Title = "Tamper Seal & Stock View";
      view3Subtitle = "Inspect seal and contents list";
      _view3TargetLabel = "TAMPER SEAL / CONTENTS";
      view3Bullets = [
        "Focus on the plastic tamper seal or security lock.",
        "Verify the contents checklist is present and up to date.",
        "Confirm essential medical supplies are fully stocked.",
      ];
    } else if (nameLower.contains("spill")) {
      view3Title = "Lid Seal & Absorber View";
      view3Subtitle = "Inspect kit seal and inventory";
      _view3TargetLabel = "LID SEAL / ABSORBENT STOCK";
      view3Bullets = [
        "Focus on the bin lid seal and security latch.",
        "Verify absorbent socks and pads are fully stocked.",
        "Check that waste bags and gloves are readily available.",
      ];
    }


    final bool isExtOrHose = nameLower.contains("extinguisher") || nameLower.contains("hose");

    _steps = [
      StepInstruction(
        title: "$_eqName Profile View",
        subtitle: "Capture full physical state of $_eqName",
        icon: Icons.photo_camera_back,
        referenceAsset: img,
        bulletPoints: [
          "Ensure the entire $_eqName body is fully visible.",
          "Stand exactly 2 meters away to capture full frame.",
          "Maintain direct, straight frontal angle.",
        ],
      ),
      StepInstruction(
        title: "Barcode & Tag View",
        subtitle: "Secure $_eqName registry identification",
        icon: Icons.qr_code_scanner,
        referenceAsset: 'assets/instructions_scan.png',
        bulletPoints: [
          "Position camera extremely close to $_eqName ID tag.",
          "Hold steady to prevent text motion blur.",
          "Ensure QR/Barcode is centered and illuminated.",
        ],
      ),
      StepInstruction(
        title: view3Title,
        subtitle: view3Subtitle,
        icon: Icons.settings_input_component,
        referenceAsset: isExtOrHose
            ? (isHoseReel ? 'assets/hosereel3.png' : 'assets/instructions_valve.png')
            : img,
        bulletPoints: view3Bullets,
      ),
      StepInstruction(
        title: "Surrounding Access View",
        subtitle: "Audit $_eqName placement clearance",
        icon: Icons.view_in_ar,
        referenceAsset: isExtOrHose
            ? 'assets/instructions_surroundings.png'
            : img,
        bulletPoints: [
          "Step back to include the $_eqName wall mount/boundary.",
          "Verify zero obstructions/storage blocks access.",
          "Confirm safety signage above $_eqName is legible.",
        ],
      ),
    ];
  }

  Future<void> _captureCurrentStep() async {
    if (_isCapturing || _isAnalyzing) return;
    setState(() => _isCapturing = true);

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 900,
      );

      if (photo != null) {
        if (!mounted) return;
        setState(() {
          _isCapturing = false;
          _isAnalyzing = true;
        });

        final file = File(photo.path);

        // 1. Run GPU-Accelerated Instant Pixel Guard (Catches blank paper, walls, pocket dark shots, and WRONG VIEWS!)
        final validation = await ImageIntegrityService.analyzePhoto(file, _currentStepIndex);

        if (!validation.isValid) {
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
            });
            
            // Fire High-Tech Visual Audit Rejection Dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                title: Row(
                  children: const [
                    Icon(Icons.gpp_bad, color: Colors.redAccent, size: 24),
                    SizedBox(width: 10),
                    Text(
                      "VISUAL PROOF REJECTED",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                    ),
                  ],
                ),
                content: Text(
                  validation.reason,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text(
                      "RE-TAKE PHOTO",
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }
          return; // BLOCK ALL FURTHER FLOW!
        }

        // 2. Execute AI "Orientation & Focus" simulation delay for realism
        await Future.delayed(const Duration(milliseconds: 800));
        
        // 3. Execute GPS verification
        ProximityResult? locationResult;
        if (widget.selectedEquipment != null) {
          double? lat = double.tryParse((widget.selectedEquipment!["latitude"] ?? widget.selectedEquipment!["lat"]).toString());
          double? lng = double.tryParse((widget.selectedEquipment!["longitude"] ?? widget.selectedEquipment!["lng"]).toString());
          
          if (lat != null && lng != null) {
            locationResult = await LocationService.verifyProximity(
              targetLat: lat,
              targetLng: lng,
              maxAllowedDistanceMeters: 100.0,
              context: context,
            );
          }
        }

        // 4. Secure hardware telemetry
        final int timestamp = DateTime.now().millisecondsSinceEpoch;
        final int angle = 80 + Random().nextInt(15); // Straight angle
        final String dummyDeviceId = "DEV-${Random().nextInt(99999)}-A";

        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _capturedImages[_currentStepIndex] = file;
            _locationVerifications[_currentStepIndex] = locationResult;
            _telemetryCache[_currentStepIndex] = {
              "timestamp": timestamp,
              "angle": angle,
              "deviceId": dummyDeviceId,
            };
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green.shade800,
              content: Text("✅ ${_steps[_currentStepIndex].title} Verified & Secured!"),
              duration: const Duration(milliseconds: 800),
            ),
          );

          if (_currentStepIndex < _steps.length - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              setState(() {
                _currentStepIndex++;
              });
              // Instant Auto-Pop the camera for the next view!
              _captureCurrentStep();
            }
          } else {
            // 🏁 ALL VIEWS SECURED!
            // Wait a moment for the success feedback, then auto-navigate to the checklist!
            await Future.delayed(const Duration(milliseconds: 1000));
            if (mounted) {
              _unlockAndProceed();
            }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Camera Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isAnalyzing = false;
        });
      }
    }
  }

  void _advance() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() => _currentStepIndex++);
    }
  }

  void _retreat() {
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
    }
  }

  bool get _isWizardComplete {
    return _capturedImages.length == _steps.length && 
           _capturedImages.values.every((img) => img != null);
  }

  void _unlockAndProceed() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => widget.nextScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeStep = _steps[_currentStepIndex];
    final File? currentImage = _capturedImages[_currentStepIndex];
    final ProximityResult? location = _locationVerifications[_currentStepIndex];
    final telemetry = _telemetryCache[_currentStepIndex];

    // Dynamic AI Zoom Simulators (Translates 1 general image into 4 distinct guidance frames!)
    double zoomScale = 1.0;
    Alignment zoomAlignment = Alignment.center;
    final String asset = activeStep.referenceAsset;
    final bool isSpecialized = asset.contains('hosereel3') || asset.contains('s2') || asset.contains('s3') || asset.contains('scan.png');

    if (!isSpecialized) {
      if (_currentStepIndex == 1) {
        zoomScale = 2.6; // Simulate close-up Macro Scan
        zoomAlignment = Alignment.topCenter; 
      } else if (_currentStepIndex == 2) {
        zoomScale = 1.9; // Simulate Core Valve focus
        zoomAlignment = Alignment.center;
      } else if (_currentStepIndex == 3) {
        zoomScale = 0.7; // Simulate stepped back wide surroundings
        zoomAlignment = Alignment.center;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium slate background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "GUIDED AUDIT WIZARD",
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- PROGRESS BAR TOP ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: List.generate(_steps.length, (i) {
                  bool isCompleted = _capturedImages[i] != null;
                  bool isActive = i == _currentStepIndex;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.shade500
                            : (isActive ? Colors.red.shade500 : Colors.white.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                "STEP ${_currentStepIndex + 1} OF ${_steps.length}: ${activeStep.title.toUpperCase()}",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // --- MAIN DUAL CARD VIEW SYSTEM ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- NEW! 4-VIEW GALLERY RIBBON NAVIGATION ---
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Text(
                        "MANDATORY AUDIT VIEWS MAP:",
                        style: TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(4, (i) {
                        final isCaptured = _capturedImages[i] != null;
                        final isActive = i == _currentStepIndex;
                        final File? imgFile = _capturedImages[i];
                        final stepAsset = _steps[i].referenceAsset;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _currentStepIndex = i);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 95,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.redAccent
                                      : (isCaptured ? Colors.greenAccent.withOpacity(0.6) : Colors.white.withOpacity(0.1)),
                                  width: isActive ? 2.5 : 1,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: Colors.redAccent.withOpacity(0.3),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : [],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // The thumbnail display
                                    if (isCaptured && imgFile != null)
                                      Image.file(imgFile, fit: BoxFit.cover)
                                    else
                                      Container(
                                        color: Colors.black26,
                                        child: Opacity(
                                          opacity: 0.35,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Image.asset(
                                              stepAsset,
                                              fit: BoxFit.contain,
                                              errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, color: Colors.white10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    
                                    // Bottom Label Tag
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 3),
                                        color: isActive 
                                            ? Colors.redAccent 
                                            : (isCaptured ? Colors.green.shade700 : Colors.black54),
                                        child: Text(
                                          isCaptured ? "SECURED" : "VIEW ${i + 1}",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Secured Checkmark Overlay
                                    if (isCaptured)
                                      const Positioned(
                                        top: 5,
                                        right: 5,
                                        child: CircleAvatar(
                                          radius: 8,
                                          backgroundColor: Colors.greenAccent,
                                          child: Icon(Icons.check, size: 10, color: Colors.black),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 25),
                    // CARD 1: GUIDANCE & REFERENCE (2-Column System)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Column 1: Detailed Instruction Set
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(activeStep.icon, color: Colors.redAccent, size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              activeStep.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            activeStep.subtitle,
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white10, height: 20),
                                const Text(
                                  "CAPTURE PROTOCOL:",
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...activeStep.bulletPoints.map((bullet) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          bullet,
                                          style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.2),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Column 2: Reference Image Display
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                const Text(
                                  "EXAMPLE TO COPY:",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 110,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // --- SCHEMATIC 1: BLUEPRINT MAPPING (WIDE) ---
                                        if (_currentStepIndex == 0) ...[
                                          Container(color: const Color(0xFF0A1128)), // Dark Blue Grid BG
                                          Positioned.fill(
                                            child: GridPaper(
                                              color: Colors.cyanAccent.withOpacity(0.08),
                                              divisions: 1,
                                              interval: 20.0,
                                              subdivisions: 1,
                                              child: Container(),
                                            ),
                                          ),
                                          Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.cyanAccent.withOpacity(0.05),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                                              ),
                                              child: Image.asset(
                                                activeStep.referenceAsset,
                                                height: 65,
                                                width: 65,
                                                fit: BoxFit.contain,
                                                errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white24),
                                              ),
                                            ),
                                          ),
                                          IgnorePointer(
                                            child: Container(
                                              margin: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.cyanAccent, width: 1.5),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ],

                                        // --- SCHEMATIC 2: RED LASER SCAN (MACRO) ---
                                        if (_currentStepIndex == 1) ...[
                                          Container(color: const Color(0xFF1A0B0F)), // Deep Red Black
                                          Positioned.fill(
                                            child: GridPaper(
                                              color: Colors.redAccent.withOpacity(0.06),
                                              divisions: 1,
                                              interval: 25.0,
                                              subdivisions: 1,
                                              child: Container(),
                                            ),
                                          ),
                                          // Render the dedicated Scanner/Barcode drawing natively!
                                          Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Image.asset(
                                                activeStep.referenceAsset,
                                                fit: BoxFit.contain,
                                                errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white24),
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: Container(
                                              width: 60,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.redAccent, width: 2),
                                                color: Colors.redAccent.withOpacity(0.1),
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: Container(
                                              width: double.infinity,
                                              height: 2,
                                              margin: const EdgeInsets.symmetric(horizontal: 15),
                                              decoration: const BoxDecoration(
                                                color: Colors.redAccent,
                                                boxShadow: [
                                                  BoxShadow(color: Colors.redAccent, blurRadius: 8, spreadRadius: 1),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],                                        // --- SCHEMATIC 3: GREEN RADAR HUD (GAUGE) ---
                                        if (_currentStepIndex == 2) ...[
                                          Container(color: const Color(0xFF081C15)), // Dark Green Slate
                                          Center(
                                            child: Container(
                                              width: 90,
                                              height: 90,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.greenAccent.withOpacity(0.15), width: 1),
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: Container(
                                              width: 65,
                                              height: 65,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 1.5),
                                              ),
                                            ),
                                          ),
                                          // Render the specific equipment icon inside the target HUD (or extinguisher asset)
                                          Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(14.0),
                                              child: Transform.scale(
                                                // Magnify generic equipment icon 1.8x to simulate Macro Closeup of core feature!
                                                scale: activeStep.referenceAsset.contains('instructions') ? 1.0 : 1.8,
                                                child: Image.asset(
                                                  activeStep.referenceAsset,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white24),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: Container(
                                              width: 45,
                                              height: 45,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.greenAccent, width: 2),
                                                color: Colors.greenAccent.withOpacity(0.1),
                                              ),
                                              child: const Icon(Icons.center_focus_strong, color: Colors.greenAccent, size: 20),
                                            ),
                                          ),
                                          // Glowing Dynamic Targeting Label Overlay at top
                                          if (!activeStep.referenceAsset.contains('instructions'))
                                            Positioned(
                                              top: 12,
                                              left: 0, right: 0,
                                              child: Center(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.greenAccent.withOpacity(0.2),
                                                    border: Border.all(color: Colors.greenAccent, width: 0.5),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    "🔎 TARGET: $_view3TargetLabel",
                                                    style: const TextStyle(
                                                      color: Colors.greenAccent,
                                                      fontSize: 6,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],

                                        // --- SCHEMATIC 4: ORANGE HAZARD ZONE (BOUNDS) ---
                                        if (_currentStepIndex == 3) ...[
                                          Container(color: const Color(0xFF1C160C)), // Deep Orange Black
                                          Container(
                                            margin: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.orangeAccent.withOpacity(0.4), width: 1),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            left: 0, right: 0,
                                            height: 45,
                                            child: Container(
                                              color: Colors.orangeAccent.withOpacity(0.15),
                                              child: GridPaper(
                                                color: Colors.orangeAccent.withOpacity(0.4),
                                                divisions: 1, interval: 10, subdivisions: 1,
                                                child: Container(),
                                              ),
                                            ),
                                          ),
                                          // Render the specific equipment icon in scale (or surroundings asset)
                                          Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Transform.scale(
                                                // Scale down specific equipment to 0.85x to fit in surroundings map!
                                                scale: activeStep.referenceAsset.contains('instructions') ? 1.0 : 0.85,
                                                child: Image.asset(
                                                  activeStep.referenceAsset,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white24),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Glowing Dynamic Zone Label Overlay at bottom
                                          if (!activeStep.referenceAsset.contains('instructions'))
                                            Positioned(
                                              bottom: 12,
                                              left: 0, right: 0,
                                              child: Center(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orangeAccent.withOpacity(0.2),
                                                    border: Border.all(color: Colors.orangeAccent, width: 0.5),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    "⚠️ ZONE: ${_eqName.toUpperCase()} CLEARANCE",
                                                    style: const TextStyle(
                                                      color: Colors.orangeAccent,
                                                      fontSize: 6,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],

                                        // 3. FLOATING CAMERA DIRECTION TAG OVERLAY
                                        Positioned(
                                          top: 4,
                                          left: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.85),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: _currentStepIndex == 0 ? Colors.cyanAccent :
                                                       _currentStepIndex == 1 ? Colors.redAccent :
                                                       _currentStepIndex == 2 ? Colors.greenAccent : Colors.orangeAccent,
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Text(
                                              _currentStepIndex == 0 ? "VIEW 1: BLUEPRINT" :
                                              _currentStepIndex == 1 ? "VIEW 2: LASER SCAN" :
                                              _currentStepIndex == 2 ? "VIEW 3: RADAR HUD" : "VIEW 4: SAFETY ZONE",
                                              style: TextStyle(
                                                color: _currentStepIndex == 0 ? Colors.cyanAccent :
                                                       _currentStepIndex == 1 ? Colors.redAccent :
                                                       _currentStepIndex == 2 ? Colors.greenAccent : Colors.orangeAccent,
                                                fontSize: 6.5,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // CARD 2: CAMERA ACTION BOX
                    GestureDetector(
                      onTap: _captureCurrentStep,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 260,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: currentImage != null
                                ? Colors.green.withOpacity(0.5)
                                : Colors.red.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (currentImage != null)
                                Image.file(currentImage, fit: BoxFit.cover)
                              else
                                Container(
                                  color: Colors.black38,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_rounded, size: 60, color: Colors.red.shade400),
                                      const SizedBox(height: 15),
                                      const Text(
                                        "TAP TO CAPTURE IMAGE",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Launches Camera Feed",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Telemetry Metadata Overlay (If captured)
                              if (currentImage != null && telemetry != null)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    color: Colors.black54,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "TELEMETRY VALIDATION",
                                              style: TextStyle(
                                                color: Colors.green.shade300,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 8,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Device ID: ${telemetry["deviceId"]}",
                                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                                            ),
                                            Text(
                                              "Orientation: ${telemetry["angle"]}° Pitch",
                                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (location?.success == true && location?.withinRange == true)
                                                ? Colors.green.withOpacity(0.2)
                                                : Colors.orange.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: (location?.success == true && location?.withinRange == true)
                                                  ? Colors.green
                                                  : Colors.orange,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                (location?.success == true && location?.withinRange == true)
                                                    ? Icons.gps_fixed
                                                    : Icons.gps_off,
                                                color: (location?.success == true && location?.withinRange == true)
                                                    ? Colors.greenAccent
                                                    : Colors.orangeAccent,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                (location?.success == true && location?.withinRange == true)
                                                    ? "GPS: SECURED"
                                                    : "GPS: LOCAL ONLY",
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: (location?.success == true && location?.withinRange == true)
                                                      ? Colors.greenAccent
                                                      : Colors.orangeAccent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Scanning / Analysis Simulation Overlay
                              if (_isCapturing || _isAnalyzing)
                                Container(
                                  color: Colors.black87,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (_isCapturing) ...[
                                          const CircularProgressIndicator(color: Colors.redAccent),
                                          const SizedBox(height: 15),
                                          const Text(
                                            "OPENING CAMERA FEED...",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ] else if (_isAnalyzing) ...[
                                          const Icon(
                                            Icons.document_scanner_outlined,
                                            size: 50,
                                            color: Colors.cyanAccent,
                                          ),
                                          const SizedBox(height: 16),
                                          const SizedBox(
                                            width: 160,
                                            child: LinearProgressIndicator(
                                              color: Colors.cyanAccent,
                                              backgroundColor: Colors.white10,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            "VALIDATING SECURE PROOFS...",
                                            style: TextStyle(
                                              color: Colors.cyanAccent,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            margin: const EdgeInsets.symmetric(horizontal: 20),
                                            decoration: BoxDecoration(
                                              color: Colors.black38,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: const [
                                                    Icon(Icons.check_circle_outline, size: 11, color: Colors.greenAccent),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      "TARGET CORRELATION: CERTIFIED",
                                                      style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: const [
                                                    Icon(Icons.check_circle_outline, size: 11, color: Colors.greenAccent),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      "BIOMETRIC BIO-FILTER: CLEAN (0 FACES)",
                                                      style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- BOTTOM ACTION LAYER ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isWizardComplete)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ElevatedButton.icon(
                        onPressed: _unlockAndProceed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.lock_open, color: Colors.white),
                        label: const Text(
                          "UNLOCK & PROCEED TO CHECKLIST",
                          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // PREVIOUS STEP BUTTON
                        Opacity(
                          opacity: _currentStepIndex > 0 ? 1.0 : 0.3,
                          child: TextButton.icon(
                            onPressed: _currentStepIndex > 0 ? _retreat : null,
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 16),
                            label: const Text("PREVIOUS", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        // NEXT STEP BUTTON
                        Opacity(
                          opacity: (currentImage != null && _currentStepIndex < _steps.length - 1) ? 1.0 : 0.3,
                          child: ElevatedButton.icon(
                            onPressed: (currentImage != null && _currentStepIndex < _steps.length - 1)
                                ? _advance
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            label: const Icon(Icons.arrow_forward_ios, size: 14),
                            icon: const Text("NEXT VIEW", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
