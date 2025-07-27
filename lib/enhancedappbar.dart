import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_2/distanceprovider.dart';
import 'package:provider/provider.dart';

class EnhancedSmartBottleAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  @override
  _EnhancedSmartBottleAppBarState createState() =>
      _EnhancedSmartBottleAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(120);
}

class _EnhancedSmartBottleAppBarState extends State<EnhancedSmartBottleAppBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Widget _buildConnectionIndicator(bool isConnected) {
    Color primaryColor;
    Color secondaryColor;
    IconData iconData;
    String statusText;

    if (isConnected) {
      primaryColor = const Color(0xFF00D4AA);
      secondaryColor = const Color(0xFF00A085);
      iconData = Icons.check_circle_outline;
      statusText = "Connected";
      _rotationController.stop();
    } else {
      primaryColor = const Color(0xFFFF5252);
      secondaryColor = const Color(0xFFD32F2F);
      iconData = Icons.cloud_off_outlined;
      statusText = "Notconnected";
      _rotationController.stop();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.15),
            secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, secondaryColor],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isConnected)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                Icon(
                  iconData,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Smart Bottle',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Text(
                statusText,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          // if (isConnected) ...[
          //   const SizedBox(width: 8),
          //   Column(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       Container(
          //         width: 3,
          //         height: 8,
          //         decoration: BoxDecoration(
          //           color: primaryColor,
          //           borderRadius: BorderRadius.circular(1.5),
          //         ),
          //       ),
          //       const SizedBox(height: 1),
          //       Container(
          //         width: 3,
          //         height: 6,
          //         decoration: BoxDecoration(
          //           color: primaryColor.withOpacity(0.7),
          //           borderRadius: BorderRadius.circular(1.5),
          //         ),
          //       ),
          //       const SizedBox(height: 1),
          //       Container(
          //         width: 3,
          //         height: 4,
          //         decoration: BoxDecoration(
          //           color: primaryColor.withOpacity(0.4),
          //           borderRadius: BorderRadius.circular(1.5),
          //         ),
          //       ),
          //     ],
          //   ),
          // ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, child) {
        final isConnected = connectionProvider.isConnected;

        return AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: const Color(0xFF0A0E21),
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 80,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.lightBlue.withOpacity(0.2),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12), // ↓ Reduced padding
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Left side spacer to balance layout
                        const SizedBox(width: 10),

                        // Center - App Title (Expanded to take remaining space)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HydraSense',
                                style: GoogleFonts.pacifico(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Stay hydrated,stay \nhealthy!',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right side - Connection Status
                        _buildConnectionIndicator(isConnected),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
