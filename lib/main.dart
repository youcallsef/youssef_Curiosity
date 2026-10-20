import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const CuriosityMarsGameApp());
}

class CuriosityMarsGameApp extends StatelessWidget {
  const CuriosityMarsGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curiosity Mars Simulation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF100B09), // لون المريخ الداكن
      ),
      home: const SplashScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. شاشة اللوجو (SplashScreen) - لمنع ظهور الشاشة البيضاء عند التشغيل
// -----------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // للانتقال التلقائي لشاشة الترحيب بعد ثانيتين
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepOrange.withOpacity(0.15),
                border: Border.all(color: Colors.deepOrange, width: 2),
              ),
              child: const Icon(
                Icons.precision_manufacturing_rounded,
                size: 80,
                color: Colors.deepOrangeAccent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'CURIOSITY SIMULATOR',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mars Exploration Mission',
              style: TextStyle(fontSize: 14, color: Colors.orangeAccent),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.deepOrange),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. شاشة الترحيب (WelcomeScreen) - "يلا إبدء!"
// -----------------------------------------------------------------------------
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C140E), Color(0xFF0F0806)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.public,
                  size: 100,
                  color: Colors.deepOrange,
                ),
                const SizedBox(height: 20),
                const Text(
                  'مرحباً بك في المريخ',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  'استكشف سطح كوكب المريخ بمركبة كيريوستي.\nتحكم بالفيزياء الواقعية، الليزر، وتدمير الصخور!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.horizontal(48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const MarsGameScreen()),
                    );
                  },
                  child: const Text(
                    'يلا إبدء!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. شاشة المحاكاة واللعب الرئيسية (MarsGameScreen)
// -----------------------------------------------------------------------------
class MarsGameScreen extends StatefulWidget {
  const MarsGameScreen({super.key});

  @override
  State<MarsGameScreen> createState() => _MarsGameScreenState();
}

class Rock {
  Offset position;
  double health; // الصحة ليزر
  final double size;
  bool isDestroyed = false;

  Rock({required this.position, required this.health, required this.size});
}

class Particle {
  Offset position;
  Offset velocity;
  double opacity;
  Color color;

  Particle({required this.position, required this.velocity, required this.opacity, required this.color});
}

class _MarsGameScreenState extends State<MarsGameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _gameLoopController;

  // موقع واتجاه المركبة
  Offset roverPos = const Offset(200, 300);
  double roverAngle = 0.0; // بالراديان
  double roverSpeed = 0.0;
  double angularVelocity = 0.0;

  // المدخلات والتحكم
  bool isAccelerating = false;
  bool isBraking = false;
  bool isTurningLeft = false;
  bool isTurningRight = false;
  bool isLaserActive = false;

  // فيزياء الحركة المريخية
  final double maxSpeed = 3.5;
  final double acceleration = 0.08;
  final double friction = 0.03; // احتكاك التربة المريخية
  final double turnSpeed = 0.035; // دوران محوري ذو عزم واقعي

  // قائمة الصخور والجسيمات (الغبار/الليزر)
  List<Rock> rocks = [];
  List<Particle> particles = [];
  final math.Random random = math.Random();

  int analyzedRocksCount = 0;

  @override
  void initState() {
    super.initState();

    // توليد صخور عشوائية في الخريطة
    for (int i = 0; i < 15; i++) {
      rocks.add(
        Rock(
          position: Offset(
            50 + random.nextDouble() * 300,
            100 + random.nextDouble() * 500,
          ),
          health: 100.0,
          size: 18 + random.nextDouble() * 15,
        ),
      );
    }

    // حلقة اللعبة (Game Loop) لحديث الفيزياء والأرقام في كل إطار
    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateGame);

    _gameLoopController.repeat();
  }

  @override
  void dispose() {
    _gameLoopController.dispose();
    super.dispose();
  }

  void _updateGame() {
    setState(() {
      // 1. التسارع والتباطؤ الواقعي
      if (isAccelerating) {
        roverSpeed = (roverSpeed + acceleration).clamp(-maxSpeed / 2, maxSpeed);
      } else if (isBraking) {
        roverSpeed = (roverSpeed - acceleration).clamp(-maxSpeed / 2, maxSpeed);
      } else {
        // احتكاك تدريجي
        if (roverSpeed > 0) {
          roverSpeed = math.max(0, roverSpeed - friction);
        } else if (roverSpeed < 0) {
          roverSpeed = math.min(0, roverSpeed + friction);
        }
      }

      // 2. الدوران المحوري الواقعي (Skid Steering) مع تحكم في القصور الذاتي
      if (isTurningLeft) {
        angularVelocity = -turnSpeed;
      } else if (isTurningRight) {
        angularVelocity = turnSpeed;
      } else {
        angularVelocity = 0.0;
      }

      roverAngle += angularVelocity;

      // 3. تحديث الموقع بنائاً على الزاوية والسرعة
      double dx = math.cos(roverAngle) * roverSpeed;
      double dy = math.sin(roverAngle) * roverSpeed;
      roverPos = Offset(roverPos.dx + dx, roverPos.dy + dy);

      // توليد غبار عند الحركة
      if (roverSpeed.abs() > 0.5) {
        particles.add(Particle(
          position: roverPos,
          velocity: Offset(-dx * 0.2 + (random.nextDouble() - 0.5), -dy * 0.2 + (random.nextDouble() - 0.5)),
          opacity: 0.6,
          color: Colors.deepOrangeAccent.withOpacity(0.5),
        ));
      }

      // 4. نظام الليزر وتدمير/تحليل الصخور (ChemCam)
      if (isLaserActive) {
        // إطلاق شعاع من مقدمة المركبة
        Offset laserStart = roverPos + Offset(math.cos(roverAngle) * 20, math.sin(roverAngle) * 20);
        
        for (var rock in rocks) {
          if (!rock.isDestroyed) {
            double distance = (rock.position - laserStart).distance;
            // نطاق تأثير الليزر (120 بكسل وفِي نفس الاتجاه)
            if (distance < 130) {
              rock.health -= 3.5; // نقص صحة الصخرة عند ضربها بالليزر
              
              // شرار وتفتت عند ضرب الصخرة
              particles.add(Particle(
                position: rock.position,
                velocity: Offset((random.nextDouble() - 0.5) * 3, (random.nextDouble() - 0.5) * 3),
                opacity: 0.9,
                color: Colors.yellowAccent,
              ));

              if (rock.health <= 0) {
                rock.isDestroyed = true;
                analyzedRocksCount++;
              }
            }
          }
        }
      }

      // 5. تحديث حركة الجسيمات (الغبار والشرار)
      for (int i = particles.length - 1; i >= 0; i--) {
        var p = particles[i];
        p.position += p.velocity;
        p.opacity -= 0.03;
        if (p.opacity <= 0) {
          particles.removeAt(i);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // لوحة رسم المريخ والفيزياء (CustomPainter)
          CustomPaint(
            size: Size.infinite,
            painter: MarsWorldPainter(
              roverPos: roverPos,
              roverAngle: roverAngle,
              rocks: rocks,
              particles: particles,
              isLaserActive: isLaserActive,
            ),
          ),

          // واجهة البيانات (Dashboard)
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHUDCard('السرعة', '${(roverSpeed * 3.6).toStringAsFixed(1)} km/h'),
                _buildHUDCard('العينات المحللة', '$analyzedRocksCount صخرة'),
              ],
            ),
          ),

          // أزرار التحكم الواقعية على الشاشة
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // أزرار الاتجاهات والدوران (الجانب الأيسر)
                Row(
                  children: [
                    _buildControlButton(
                      icon: Icons.rotate_left,
                      onPressedStart: () => isTurningLeft = true,
                      onPressedEnd: () => isTurningLeft = false,
                    ),
                    const SizedBox(width: 10),
                    _buildControlButton(
                      icon: Icons.rotate_right,
                      onPressedStart: () => isTurningRight = true,
                      onPressedEnd: () => isTurningRight = false,
                    ),
                  ],
                ),

                // زر إطلاق الليزر التحليلي (في المنتصف)
                _buildControlButton(
                  icon: Icons.bolt,
                  color: Colors.redAccent,
                  onPressedStart: () => isLaserActive = true,
                  onPressedEnd: () => isLaserActive = false,
                ),

                // أزرار الحركة للأمام والخلف (الجانب الأيمن)
                Row(
                  children: [
                    _buildControlButton(
                      icon: Icons.arrow_downward,
                      onPressedStart: () => isBraking = true,
                      onPressedEnd: () => isBraking = false,
                    ),
                    const SizedBox(width: 10),
                    _buildControlButton(
                      icon: Icons.arrow_upward,
                      onPressedStart: () => isAccelerating = true,
                      onPressedEnd: () => isAccelerating = false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHUDCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressedStart,
    required VoidCallback onPressedEnd,
    Color color = Colors.deepOrange,
  }) {
    return GestureDetector(
      onTapDown: (_) => onPressedStart(),
      onTapUp: (_) => onPressedEnd(),
      onTapCancel: () => onPressedEnd(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 2),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. الرسام الخاص بسطح المريخ والمركبة والفيزياء (MarsWorldPainter)
// -----------------------------------------------------------------------------
class MarsWorldPainter extends CustomPainter {
  final Offset roverPos;
  final double roverAngle;
  final List<Rock> rocks;
  final List<Particle> particles;
  final bool isLaserActive;

  MarsWorldPainter({
    required this.roverPos,
    required this.roverAngle,
    required this.rocks,
    required this.particles,
    required this.isLaserActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. خلفية سطح المريخ
    final Paint bgPaint = Paint()..color = const Color(0xFFB54D28);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // تفاصيل التضاريس (فوهات وتجاعيد في التربة)
    final Paint craterPaint = Paint()..color = const Color(0xFF963C1B);
    canvas.drawCircle(const Offset(100, 150), 40, craterPaint);
    canvas.drawCircle(const Offset(300, 450), 70, craterPaint);

    // 2. رسم الصخور وتأثرها بالدمار
    for (var rock in rocks) {
      if (!rock.isDestroyed) {
        double healthRatio = (rock.health / 100.0).clamp(0.0, 1.0);
        Paint rockPaint = Paint()
          ..color = Color.lerp(Colors.black87, const Color(0xFF523326), healthRatio)!;
        
        canvas.drawCircle(rock.position, rock.size, rockPaint);

        // شريط صحة الصخرة عند تضررها بالليزر
        if (rock.health < 100) {
          Paint healthBg = Paint()..color = Colors.black;
          Paint healthFg = Paint()..color = Colors.redAccent;
          canvas.drawRect(Rect.fromLTWH(rock.position.dx - 15, rock.position.dy - rock.size - 10, 30, 4), healthBg);
          canvas.drawRect(Rect.fromLTWH(rock.position.dx - 15, rock.position.dy - rock.size - 10, 30 * healthRatio, 4), healthFg);
        }
      }
    }

    // 3. رسم الجسيمات (الغبار والشرارات)
    for (var p in particles) {
      Paint pPaint = Paint()..color = p.color.withOpacity(p.opacity.clamp(0.0, 1.0));
      canvas.drawCircle(p.position, 3, pPaint);
    }

    // 4. رسم شعاع ليزر ChemCam من المركبة
    if (isLaserActive) {
      Offset laserStart = roverPos + Offset(math.cos(roverAngle) * 20, math.sin(roverAngle) * 20);
      Offset laserEnd = roverPos + Offset(math.cos(roverAngle) * 150, math.sin(roverAngle) * 150);

      Paint laserPaint = Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

      canvas.drawLine(laserStart, laserEnd, laserPaint);
    }

    // 5. رسم مركبة كيريوستي (Curiosity Rover) بتفاصيلها
    canvas.save();
    canvas.translate(roverPos.dx, roverPos.dy);
    canvas.rotate(roverAngle);

    // هيكل المركبة الرئيسي
    Paint bodyPaint = Paint()..color = Colors.grey.shade300;
    canvas.drawRect(const Rect.fromLTWH(-15, -12, 30, 24), bodyPaint);

    // نظام عجلات Rocker-Bogie (6 عجلات)
    Paint wheelPaint = Paint()..color = Colors.black87;
    // عجلات يسار
    canvas.drawRRect(RRect.fromLTRBR(-18, -16, -10, -12, const Radius.circular(2)), wheelPaint);
    canvas.drawRRect(RRect.fromLTRBR(-4, -16, 4, -12, const Radius.circular(2)), wheelPaint);
    canvas.drawRRect(RRect.fromLTRBR(10, -16, 18, -12, const Radius.circular(2)), wheelPaint);
    // عجلات يمين
    canvas.drawRRect(RRect.fromLTRBR(-18, 12, -10, 16, const Radius.circular(2)), wheelPaint);
    canvas.drawRRect(RRect.fromLTRBR(-4, 12, 4, 16, const Radius.circular(2)), wheelPaint);
    canvas.drawRRect(RRect.fromLTRBR(10, 12, 18, 16, const Radius.circular(2)), wheelPaint);

    // الكاميرا ورأس المركبة (Mastcam)
    Paint mastPaint = Paint()..color = Colors.blueGrey;
    canvas.drawCircle(const Offset(10, 0), 5, mastPaint);

    // مولد الطاقة النوو ي (RTG) خلف المركبة
    Paint rtgPaint = Paint()..color = Colors.black54;
    canvas.drawCircle(const Offset(-14, 0), 4, rtgPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
