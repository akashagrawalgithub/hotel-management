import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../l10n/app_localizations.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Curved background with CustomPaint
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 80),
            painter: _CurvedNavBarPainter(),
            child: Container(
              height: 80,
            ),
          ),
          // Navigation items
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(Icons.home, 'HOME', 0),
                _buildNavItem(Icons.search, 'FIND', 1),
                const SizedBox(width: 60), // Space for center button
                _buildNavItem(Icons.history, 'HISTORY', 3),
                _buildNavItem(Icons.settings, 'SETTINGS', 4),
              ],
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 30,
            top: -15,
            child: _buildCenterButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.red : Colors.black,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.red : Colors.black,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterButton() {
    final isSelected = currentIndex == 2;
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isSelected ? Icons.favorite : Icons.favorite_border,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class _CurvedNavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Create gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.gradientStart, AppColors.gradientEnd],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = gradient.createShader(rect);

    final path = Path();

    // Start from bottom left
    path.moveTo(0, size.height);

    // Line to bottom right
    path.lineTo(size.width, size.height);

    // Line to top right
    path.lineTo(size.width, 0);

    // Create smooth concave wave curve at the top
    // Starts at top (y=0) at right edge, dips down in center, returns to top at left edge
    final waveDepth = 20.0; // Depth of the concave curve
    final centerX = size.width / 2;
    
    // Create smooth concave wave using cubic Bezier curves
    // From top right (y=0) to center (dips down to waveDepth)
    path.cubicTo(
      size.width * 0.85, 0, // Control point 1 (right side, stays at top)
      size.width * 0.65, waveDepth * 0.6, // Control point 2 (starts curving down)
      centerX, waveDepth, // End point (center, at maximum dip)
    );

    // From center to top left (rises back up to y=0)
    path.cubicTo(
      size.width * 0.35, waveDepth * 0.6, // Control point 1 (starts rising from dip)
      size.width * 0.15, 0, // Control point 2 (left side, back to top)
      0, 0, // End point (top left, at top y=0)
    );

    // Close the path
    path.close();

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    final shadowPath = Path.from(path);
    shadowPath.shift(const Offset(0, -2));
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw the main shape
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


