import 'dart:math' as math;

import 'package:diary_garden/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: const [
            Positioned.fill(
              child: _MainScrollView(),
            ),
            _FloatingWriteButton(),
          ],
        ),
      ),
    );
  }
}

class _MainScrollView extends StatelessWidget {
  const _MainScrollView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _FrostedStatusBar(),
          SizedBox(height: 24),
          _TopActionsRow(),
          SizedBox(height: 32),
          _DayHeaderRow(),
          SizedBox(height: 10),
          _DayStatusRow(),
          SizedBox(height: 40),
          _TreeIllustration(),
        ],
      ),
    );
  }
}

class _FrostedStatusBar extends StatelessWidget {
  const _FrostedStatusBar();

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.black.withValues(alpha: 0.06);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(44),
            topRight: Radius.circular(44),
          ),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Text(
              '9:41',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Icon(Icons.signal_cellular_alt_rounded,
                color: Colors.black.withValues(alpha: 0.8), size: 18),
            const SizedBox(width: 8),
            Icon(Icons.wifi, color: Colors.black.withValues(alpha: 0.8), size: 18),
            const SizedBox(width: 8),
            Container(
              width: 26,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 2),
              child: Container(
                width: 16,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopActionsRow extends StatelessWidget {
  const _TopActionsRow();

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.black.withValues(alpha: 0.1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _IconBadge(
            icon: Icons.menu_rounded,
            borderColor: borderColor,
          ),
          const Spacer(),
          _IconBadge(
            icon: Icons.calendar_today_outlined,
            borderColor: borderColor,
          ),
          const SizedBox(width: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(
                'http://localhost:3845/assets/ee796b514594b6828175997e69d70b734e0c7e5c.png',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.borderColor,
  });

  final IconData icon;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black87),
    );
  }
}

class _DayHeaderRow extends StatelessWidget {
  const _DayHeaderRow();

  static const _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.black.withValues(alpha: 0.65);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final label in _labels)
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 1.4,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            )
        ],
      ),
    );
  }
}

class _DayStatusRow extends StatelessWidget {
  const _DayStatusRow();

  static const _status = [true, false, true, true, true, true, true];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final written in _status) _DayBubble(written: written),
        ],
      ),
    );
  }
}

class _DayBubble extends StatelessWidget {
  const _DayBubble({required this.written});

  final bool written;

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.black.withValues(alpha: 0.08);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: written
            ? const LinearGradient(
                colors: [
                  Color(0xFFFFF6D8),
                  Color(0xFFFACF8F),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: written ? null : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: written ? null : Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Icon(
        written ? Icons.eco : Icons.add,
        color: written ? const Color(0xFF5A6E2C) : Colors.black26,
        size: 20,
      ),
    );
  }
}

class _TreeIllustration extends StatelessWidget {
  const _TreeIllustration();

  static const _leafPlacements = [
    _LeafPlacement(
      alignment: Alignment(0, -0.95),
      colors: [Color(0xFFFFE08E), Color(0xFFF5C565)],
      angleDeg: 8,
      size: Size(120, 48),
    ),
    _LeafPlacement(
      alignment: Alignment(-0.65, -0.55),
      colors: [Color(0xFFAEE1C5), Color(0xFF87C6A4)],
      angleDeg: -24,
      size: Size(84, 34),
    ),
    _LeafPlacement(
      alignment: Alignment(0.7, -0.4),
      colors: [Color(0xFF9FC0F5), Color(0xFF88A8EA)],
      angleDeg: 24,
      size: Size(78, 32),
    ),
    _LeafPlacement(
      alignment: Alignment(-0.3, -0.15),
      colors: [Color(0xFFFF9F74), Color(0xFFF27C54)],
      angleDeg: -18,
      size: Size(72, 30),
    ),
    _LeafPlacement(
      alignment: Alignment(0.4, 0),
      colors: [Color(0xFFEFD35A), Color(0xFFF5E17E)],
      angleDeg: 12,
      size: Size(80, 32),
    ),
    _LeafPlacement(
      alignment: Alignment(-0.75, -0.05),
      colors: [Color(0xFFB6E7EB), Color(0xFF7BD3DF)],
      angleDeg: -38,
      size: Size(70, 26),
    ),
    _LeafPlacement(
      alignment: Alignment(0.85, -0.05),
      colors: [Color(0xFFECB0E2), Color(0xFFD176B8)],
      angleDeg: 38,
      size: Size(70, 28),
    ),
    _LeafPlacement(
      alignment: Alignment(-0.2, 0.25),
      colors: [Color(0xFF9FE8F0), Color(0xFF6AC8D4)],
      angleDeg: -10,
      size: Size(64, 26),
    ),
    _LeafPlacement(
      alignment: Alignment(0.35, 0.35),
      colors: [Color(0xFFB0E593), Color(0xFF7BC559)],
      angleDeg: 14,
      size: Size(64, 26),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: SizedBox(
        height: 320,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF8BC68B),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 16,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 70,
              child: Container(
                width: 48,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.trunk,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 18,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
              ),
            ),
            for (final placement in _leafPlacements)
              Align(
                alignment: placement.alignment,
                child: Transform.rotate(
                  angle: placement.angleRad,
                  child: Container(
                    width: placement.size.width,
                    height: placement.size.height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: placement.colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        placement.size.height,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 12,
                          offset: Offset(0, 8),
                        ),
                      ],
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

class _LeafPlacement {
  const _LeafPlacement({
    required this.alignment,
    required this.colors,
    required this.angleDeg,
    required this.size,
  });

  final Alignment alignment;
  final List<Color> colors;
  final double angleDeg;
  final Size size;

  double get angleRad => angleDeg * math.pi / 180;
}

class _FloatingWriteButton extends StatelessWidget {
  const _FloatingWriteButton();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('오늘의 일기를 써 볼까요?'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFD071),
                  Color(0xFFFF9A56),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}
