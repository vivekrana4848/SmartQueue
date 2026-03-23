import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../models/sector_model.dart';

class SectorCard extends StatelessWidget {
  final SectorModel sector;
  final int colorIndex;
  final VoidCallback onTap;

  const SectorCard({
    super.key,
    required this.sector,
    required this.colorIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Parse hex color from Firestore, fallback to primary if invalid
    Color color;
    try {
      color = Color(int.parse(sector.color.replaceAll('#', '0xFF')));
    } catch (_) {
      color = AppTheme.primary;
    }
    
    final colors = [color, color.withAlpha(200)];
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors[0].withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  sector.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            Text(
              sector.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
