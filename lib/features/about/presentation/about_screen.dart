import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String appVersion = '5.0';
  static const String releaseType = 'Stable release';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      body: Stack(
        children: [
          // Geometric Islamic Pattern Background
          Positioned.fill(
            child: CustomPaint(painter: _IslamicPatternPainter()),
          ),

          CustomScrollView(
            slivers: [
              // Header with Crescent
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: const Color(0xFF0A0F1C),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0D2137),
                          const Color(0xFF0A0F1C),
                        ],
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Decorative arcs
                        Positioned(
                          top: 40,
                          child: Container(
                            width: 300,
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(150),
                                topRight: Radius.circular(150),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 50),
                            // App Logo
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1B5E20,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ).animate().scale(
                              duration: 700.ms,
                              curve: Curves.easeOutBack,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Prevention',
                              style: GoogleFonts.amiri(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFD4AF37,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'v$appVersion $releaseType',
                                style: TextStyle(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Bismillah Header
                    Center(
                      child: Text(
                        'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
                        style: GoogleFonts.amiri(
                          fontSize: 24,
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'In the name of Allah, the Most Gracious, the Most Merciful',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Purpose Section
                    _buildSection(
                      title: 'Our Purpose',
                      icon: Icons.favorite_outline,
                      iconColor: const Color(0xFF1B5E20),
                      child: Column(
                        children: [
                          Text(
                            'Prevention was born from a deeply personal understanding of how addiction can silently erode one\'s spiritual and mental well-being.\n\n'
                            'In a world where explicit content is just a tap away, I wanted to create more than just a blocker, a companion for the journey of self-purification (تزكية النفس).\n\n'
                            'This app combines Islamic guidance with modern accountability because lasting change requires both spiritual grounding and practical tools.\n\n'
                            'Every feature from the panic mode that grants you 4 minutes of reflection, to the streak system rewarding consistency—was designed with empathy for the struggle and hope for recovery.',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 15,
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'وَلَا تَقْرَبُوا الْفَوَاحِشَ مَا ظَهَرَ مِنْهَا وَمَا بَطَنَ',
                                  style: GoogleFonts.amiri(
                                    fontSize: 18,
                                    color: const Color(0xFFD4AF37),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '"And do not approach immoralities, what is apparent of them and what is concealed."',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '— Surah Al-An\'am 6:151',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Developer Section
                    _buildSection(
                      title: 'Developer',
                      icon: Icons.person_outline,
                      iconColor: const Color(0xFFD4AF37),
                      child: Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Azwad Abrar',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'App Developer & Product Designer',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _launchUrl(
                              'https://neuralabsagency.vercel.app/',
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1B2A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFD4AF37,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.rocket_launch_outlined,
                                      color: Color(0xFFD4AF37),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Neura Labs',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Co-Founder • SaaS Agency',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.open_in_new,
                                    color: Colors.grey[600],
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Tech Stack
                    _buildSection(
                      title: 'Built With',
                      icon: Icons.code_outlined,
                      iconColor: const Color(0xFF4FC3F7),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTechChip('Flutter'),
                          _buildTechChip('Dart'),
                          _buildTechChip('Kotlin'),
                          _buildTechChip('Supabase'),
                          _buildTechChip('PostgreSQL'),
                          _buildTechChip('Riverpod'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Legal
                    _buildSection(
                      title: 'Legal',
                      icon: Icons.gavel_outlined,
                      iconColor: Colors.grey,
                      child: Column(
                        children: [
                          _buildLegalTile(
                            'Privacy Policy',
                            Icons.privacy_tip_outlined,
                            () {},
                          ),
                          _buildLegalTile(
                            'Terms of Service',
                            Icons.description_outlined,
                            () {},
                          ),
                          _buildLegalTile(
                            'Open Source Licenses',
                            Icons.folder_open_outlined,
                            () => showLicensePage(
                              context: context,
                              applicationName: 'Prevention',
                              applicationVersion: appVersion,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Footer with Dua
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'جَزَاكُمُ اللّٰهُ خَيْرًا',
                            style: GoogleFonts.amiri(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'May Allah reward you with goodness',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '© 2026 Neura Labs',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTechChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey[300],
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLegalTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey[600], size: 22),
      title: Text(
        title,
        style: TextStyle(color: Colors.grey[300], fontSize: 15),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[700]),
      onTap: onTap,
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Custom painter for modern Islamic geometric + graffiti vector background
class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Layer 1: Flowing graffiti-style curves
    _drawGraffitiSwirls(canvas, size);

    // Layer 2: Islamic geometric grid
    _drawIslamicGrid(canvas, size);

    // Layer 3: Star accents
    _drawStarAccents(canvas, size);

    // Layer 4: Vector brush strokes
    _drawVectorStrokes(canvas, size);
  }

  void _drawGraffitiSwirls(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Large flowing curve from top-left
    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.1,
        size.width * 0.5,
        size.height * 0.4,
        size.width * 0.8,
        size.height * 0.2,
      );
    canvas.drawPath(path1, paint);

    // Second wave from bottom
    final path2 = Path()
      ..moveTo(size.width * 0.1, size.height)
      ..cubicTo(
        size.width * 0.4,
        size.height * 0.7,
        size.width * 0.6,
        size.height * 0.9,
        size.width,
        size.height * 0.6,
      );
    canvas.drawPath(
      path2,
      paint..color = const Color(0xFFD4AF37).withValues(alpha: 0.04),
    );

    // Spiral accent
    final spiralPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final spiralPath = Path();
    double cx = size.width * 0.85;
    double cy = size.height * 0.15;
    for (double t = 0; t < 4 * math.pi; t += 0.1) {
      double r = 10 + t * 3;
      double x = cx + r * math.cos(t);
      double y = cy + r * math.sin(t);
      if (t == 0) {
        spiralPath.moveTo(x, y);
      } else {
        spiralPath.lineTo(x, y);
      }
    }
    canvas.drawPath(spiralPath, spiralPaint);
  }

  void _drawIslamicGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const spacing = 70.0;

    for (double x = -spacing; x < size.width + spacing * 2; x += spacing) {
      for (double y = -spacing; y < size.height + spacing * 2; y += spacing) {
        // Offset every other row for tessellation
        double offsetX = ((y ~/ spacing) % 2 == 0) ? 0 : spacing / 2;
        _drawOctagon(canvas, Offset(x + offsetX, y), spacing * 0.35, paint);
      }
    }
  }

  void _drawStarAccents(Canvas canvas, Size size) {
    final starPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw 8-pointed Islamic stars at key positions
    _drawIslamicStar(
      canvas,
      Offset(size.width * 0.15, size.height * 0.12),
      25,
      starPaint,
    );
    _drawIslamicStar(
      canvas,
      Offset(size.width * 0.9, size.height * 0.45),
      35,
      starPaint,
    );
    _drawIslamicStar(
      canvas,
      Offset(size.width * 0.1, size.height * 0.75),
      30,
      starPaint,
    );
    _drawIslamicStar(
      canvas,
      Offset(size.width * 0.7, size.height * 0.85),
      20,
      starPaint,
    );
    _drawIslamicStar(
      canvas,
      Offset(size.width * 0.5, size.height * 0.55),
      40,
      starPaint..color = const Color(0xFF1B5E20).withValues(alpha: 0.06),
    );
  }

  void _drawVectorStrokes(Canvas canvas, Size size) {
    // Graffiti-style angular strokes
    final strokePaint = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Angular slash marks (graffiti style)
    final slash1 = Path()
      ..moveTo(size.width * 0.05, size.height * 0.5)
      ..lineTo(size.width * 0.12, size.height * 0.45)
      ..lineTo(size.width * 0.08, size.height * 0.48);
    canvas.drawPath(slash1, strokePaint);

    final slash2 = Path()
      ..moveTo(size.width * 0.92, size.height * 0.7)
      ..lineTo(size.width * 0.98, size.height * 0.65)
      ..lineTo(size.width * 0.95, size.height * 0.72);
    canvas.drawPath(slash2, strokePaint);

    // Geometric vector lines
    final linePaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Diagonal crossing lines
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width * 0.2, size.height * 0.35),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.6),
      Offset(size.width, size.height * 0.55),
      linePaint,
    );

    // Dotted accent line
    final dotPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    for (double i = 0; i < 8; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.3 + i * 8, size.height * 0.92),
        1.5,
        dotPaint,
      );
    }
  }

  void _drawOctagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - (math.pi / 8);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawIslamicStar(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final path = Path();
    // 8-pointed star
    for (int i = 0; i < 16; i++) {
      final r = (i % 2 == 0) ? radius : radius * 0.5;
      final angle = (i * math.pi / 8) - (math.pi / 2);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
