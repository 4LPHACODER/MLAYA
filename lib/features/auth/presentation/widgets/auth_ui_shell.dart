import 'package:flutter/material.dart';
import 'package:windify_v2/core/widgets/app_brand_logo.dart';

class AuthNatureScaffold extends StatelessWidget {
  const AuthNatureScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _NatureBackground()),
          const _DecorativeCircle(
            top: -100,
            left: -70,
            size: 220,
            color: Color(0xFFBFDCC8),
            alpha: 0.28,
          ),
          const _DecorativeCircle(
            top: -40,
            right: -80,
            size: 250,
            color: Color(0xFFB8D7EE),
            alpha: 0.26,
          ),
          const _DecorativeCircle(
            bottom: -120,
            left: -70,
            size: 300,
            color: Color(0xFFDCC8A6),
            alpha: 0.2,
          ),
          const _DecorativeCircle(
            bottom: 120,
            right: -120,
            size: 280,
            color: Color(0xFFB5CFAA),
            alpha: 0.2,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final media = MediaQuery.of(context);
                final compactWidth = media.size.width < 360;
                final compactHeight = media.size.height < 700;
                final horizontalPadding = compactWidth ? 16.0 : 24.0;
                final topPadding = compactHeight ? 16.0 : 28.0;
                final bottomPadding = 24.0 + media.viewInsets.bottom;
                final minHeight =
                    (constraints.maxHeight - topPadding - 24).clamp(0.0, double.infinity);

                return SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 460, minHeight: minHeight),
                      child: child,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 360;
    final titleStyle = Theme.of(context).textTheme.displayMedium?.copyWith(
      fontSize: compact ? 34 : 40,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: const Color(0xFF2B3B2D),
      height: 1.05,
    );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF5E7264),
      fontSize: compact ? 14 : 15,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    );

    return AppBrandLogo(
      logoSize: compact ? 106 : 122,
      borderRadius: compact ? 26 : 30,
      subtitle: subtitle,
      spacing: compact ? 14 : 18,
      titleStyle: titleStyle,
      subtitleStyle: subtitleStyle,
    );
  }
}

class AuthGlassCard extends StatelessWidget {
  const AuthGlassCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 360;

    return Container(
      padding: EdgeInsets.all(compact ? 20 : 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.8),
            const Color(0xFFFFFAF1).withValues(alpha: 0.68),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3B32).withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthSectionDivider extends StatelessWidget {
  const AuthSectionDivider({super.key, this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF8FA08F).withValues(alpha: 0.25),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF6E7D70).withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF8FA08F).withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}

class _NatureBackground extends StatelessWidget {
  const _NatureBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFDF6EA),
            Color(0xFFE8F4EC),
            Color(0xFFEAF3FA),
            Color(0xFFFFFCF7),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({
    required this.size,
    required this.color,
    required this.alpha,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final double size;
  final Color color;
  final double alpha;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: alpha),
          ),
        ),
      ),
    );
  }
}
