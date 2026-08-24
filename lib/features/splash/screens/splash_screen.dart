import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final Duration duration;
  final bool autoNavigate;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 1800),
    this.autoNavigate = true,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    if (widget.autoNavigate) {
      Future.delayed(widget.duration, () {
        if (mounted) {
          context.go('/market');
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Logo & Moniker
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Glowing App Logo Card
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(28.0),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.25),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.show_chart_rounded,
                                    size: 56,
                                    color: AppColors.accent,
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Brand Title
                          Text(
                            'KESTREL',
                            style: AppTypography.displayLarge.copyWith(
                              letterSpacing: 4.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Brand Subtitle
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              'REAL-TIME FINANCIAL TERMINAL',
                              style: AppTypography.labelSmall.copyWith(
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Engine Status
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.gain,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'INITIALIZING 10-SYMBOL NSE FEED',
                        style: AppTypography.numericSmall.copyWith(
                          letterSpacing: 1.2,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'v1.0.0 • Technical Instrument Engine',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.subtle,
                    ),
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
