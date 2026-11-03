import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

/// Shows a DEV or STG ribbon above the application in non-production builds.
final class FlavorBanner extends StatelessWidget {
  const FlavorBanner({
    super.key,
    required this.child,
    this.flavor,
  });

  final Widget child;
  final AppFlavor? flavor;

  @override
  Widget build(BuildContext context) {
    final current = flavor;
    if (current == null || current.isProduction) {
      return child;
    }
    final isStaging = current == AppFlavor.staging;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: <Widget>[
          child,
          Positioned(
            top: 12,
            left: 12,
            child: IgnorePointer(
              child: Material(
                color: isStaging ? Colors.orange : Colors.teal,
                borderRadius: BorderRadius.circular(8),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(
                    isStaging ? 'STG' : 'DEV',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
