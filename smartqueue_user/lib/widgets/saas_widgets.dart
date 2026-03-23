import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/app_theme.dart';
import '../services/location_service.dart';

class DistanceBadge extends StatelessWidget {
  final double? distanceMeters;
  const DistanceBadge({super.key, this.distanceMeters});

  @override
  Widget build(BuildContext context) {
    if (distanceMeters == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_rounded, size: 12, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            LocationService.formatDistance(distanceMeters!),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class QueueIndicator extends StatelessWidget {
  final String level; // 'Low', 'Medium', 'High'
  const QueueIndicator({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (level.toLowerCase()) {
      case 'high':
        color = AppTheme.danger;
        break;
      case 'medium':
        color = AppTheme.accent;
        break;
      case 'low':
      default:
        color = AppTheme.success;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(100),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ).animate(onPlay: (controller) => controller.repeat())
         .fadeIn(duration: 1.seconds)
         .fadeOut(delay: 500.ms, duration: 1.seconds),
        const SizedBox(width: 6),
        Text(
          '$level Queue',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class BranchCard extends StatelessWidget {
  final String name;
  final String address;
  final double? distanceMeters;
  final String queueLevel;
  final VoidCallback onTap;
  final VoidCallback onMapTap;
  final bool isActive;

  const BranchCard({
    super.key,
    required this.name,
    required this.address,
    this.distanceMeters,
    this.queueLevel = 'Low',
    required this.onTap,
    required this.onMapTap,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isActive ? onTap : null,
            child: Row(
              children: [
                // Gradient Accent Left Border
                Container(
                  width: 6,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: isActive 
                      ? AppTheme.primaryGradient 
                      : const LinearGradient(colors: [Colors.grey, Colors.blueGrey]),
                  ),
                ),
                const SizedBox(width: 16),
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_city_rounded,
                    color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            DistanceBadge(distanceMeters: distanceMeters),
                            if (distanceMeters != null) const SizedBox(width: 12),
                            QueueIndicator(level: queueLevel),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.map_outlined, color: AppTheme.primary),
                      onPressed: onMapTap,
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, duration: 400.ms);
  }
}

class TokenDisplayCard extends StatelessWidget {
  final String tokenNumber;
  final String branchName;
  final int peopleAhead;
  final String estimatedWait;
  final double? distanceMeters;
  final VoidCallback onDirectionTap;

  const TokenDisplayCard({
    super.key,
    required this.tokenNumber,
    required this.branchName,
    required this.peopleAhead,
    required this.estimatedWait,
    this.distanceMeters,
    required this.onDirectionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Token Number',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            tokenNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: 'People Ahead', value: '$peopleAhead'),
                Container(width: 1, height: 40, color: Colors.white24),
                _StatItem(label: 'Wait Time', value: estimatedWait),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branchName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (distanceMeters != null)
                      Text(
                        '${LocationService.formatDistance(distanceMeters!)} away',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onDirectionTap,
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: const Text('Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class MapDirectionButton extends StatelessWidget {
  final VoidCallback onTap;
  const MapDirectionButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(40),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.map_rounded),
        label: const Text('View Directions on Maps'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }
}
