import 'package:flutter/material.dart';

import 'modern_card.dart';

class TokenDisplayCard extends StatelessWidget {
  final String tokenNumber;
  final String status;
  final int peopleAhead;
  final int estWaitMinutes;

  const TokenDisplayCard({
    super.key,
    required this.tokenNumber,
    required this.status,
    required this.peopleAhead,
    required this.estWaitMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isServing = status.toLowerCase() == 'serving';

    return ModernCard(
      showGradient: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR TOKEN',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tokenNumber,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isServing 
                    ? Colors.white.withOpacity(0.2) 
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(12),
                  border: isServing ? Border.all(color: Colors.white.withOpacity(0.3)) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isServing) ...[
                      const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(context, 'People Ahead', peopleAhead <= 0 ? (isServing ? '0' : 'Next') : peopleAhead.toString(), Icons.people_outline),
                Container(width: 1, height: 30, color: Colors.white10),
                _buildInfoItem(context, 'Est. Wait', isServing ? 'Called' : '${estWaitMinutes}m', Icons.timer_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
