import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import '../models/token_model.dart';

class TokenStatusCard extends StatelessWidget {
  final TokenModel token;
  final VoidCallback? onTap;
  final bool highlight;

  const TokenStatusCard({
    super.key,
    required this.token,
    this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(token.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: highlight
              ? Border.all(color: AppTheme.primary, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: highlight
                  ? AppTheme.primary.withAlpha(30)
                  : Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Token number circle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: _getGradient(token.status),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  token.tokenNumber,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(token.serviceName,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(token.branchName,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    token.statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppTheme.textSecondary),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TokenStatus status) {
    switch (status) {
      case TokenStatus.serving:
        return AppTheme.secondary;
      case TokenStatus.completed:
        return const Color(0xFF6B7280);
      case TokenStatus.skipped:
        return AppTheme.accent;
      case TokenStatus.recalled:
        return AppTheme.warning;
      default:
        return AppTheme.primary;
    }
  }

  LinearGradient _getGradient(TokenStatus status) {
    switch (status) {
      case TokenStatus.serving:
        return AppTheme.greenGradient;
      case TokenStatus.completed:
        return const LinearGradient(
            colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)]);
      default:
        return AppTheme.cardGradient;
    }
  }
}
