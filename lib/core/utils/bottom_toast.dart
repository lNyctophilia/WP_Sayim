import 'package:flutter/material.dart';
import 'dart:async';

class BottomToast {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;

  static void show(BuildContext context, String title, String body) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _timer?.cancel();

    // Use the root navigator overlay to ensure it's on top of everything.
    final overlayState = Navigator.of(context, rootNavigator: true).overlay;
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () {
                  _overlayEntry?.remove();
                  _overlayEntry = null;
                  _timer?.cancel();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.shade700,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_overlayEntry!);

    _timer = Timer(const Duration(seconds: 4), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }
}
