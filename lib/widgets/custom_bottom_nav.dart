import 'package:flutter/material.dart';
import '../constants/colors.dart';

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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          size: Size(MediaQuery.of(context).size.width, 80),
          painter: _CurvedBottomNavPainter(),
          child: Container(
            height: 80,
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
        ),
        Positioned(
          left: MediaQuery.of(context).size.width / 2 - 30,
          top: -15,
          child: _buildCenterButton(),
        ),
      ],
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

class _CurvedBottomNavPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final buttonRadius = 30.0;
    final notchDepth = 25.0;
    final curveRadius = 15.0;

    // Start from top left corner
    path.moveTo(0, 0);
    
    // Line to start of left curve (before the notch)
    path.lineTo(centerX - buttonRadius - curveRadius - 10, 0);
    
    // Left curve going down to the notch
    path.quadraticBezierTo(
      centerX - buttonRadius - curveRadius,
      0,
      centerX - buttonRadius - curveRadius / 2,
      notchDepth / 2,
    );
    
    path.quadraticBezierTo(
      centerX - buttonRadius,
      notchDepth,
      centerX - buttonRadius / 2,
      notchDepth,
    );
    
    // Bottom arc of the notch (semicircle)
    path.arcToPoint(
      Offset(centerX + buttonRadius / 2, notchDepth),
      radius: Radius.circular(buttonRadius / 2),
      clockwise: false,
    );
    
    // Right curve going back up
    path.quadraticBezierTo(
      centerX + buttonRadius,
      notchDepth,
      centerX + buttonRadius + curveRadius / 2,
      notchDepth / 2,
    );
    
    path.quadraticBezierTo(
      centerX + buttonRadius + curveRadius,
      0,
      centerX + buttonRadius + curveRadius + 10,
      0,
    );
    
    // Line to top right corner
    path.lineTo(size.width, 0);
    
    // Line to bottom right corner
    path.lineTo(size.width, size.height);
    
    // Line to bottom left corner
    path.lineTo(0, size.height);
    
    // Close path back to start
    path.close();

    // Create gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.gradientStart, AppColors.gradientEnd],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = gradient.createShader(rect);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

