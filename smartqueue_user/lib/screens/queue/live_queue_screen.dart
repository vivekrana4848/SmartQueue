import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/queue_provider.dart';
import '../../models/token_model.dart';
import '../../app/app_theme.dart';
import '../../services/location_service.dart';
import '../../widgets/saas_widgets.dart';

class LiveQueueScreen extends StatefulWidget {
  final String tokenId;

  const LiveQueueScreen({super.key, required this.tokenId});

  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen> {
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (mounted) setState(() => _userPosition = pos);
  }

  Future<void> _openDirections(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tokenId.isEmpty) {
      return const Scaffold(body: Center(child: Text("Invalid Token")));
    }

    final queue = context.read<QueueProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Live Dashboard')),
      body: StreamBuilder<TokenModel?>(
        stream: queue.streamToken(widget.tokenId),
        builder: (context, tokenSnap) {
          if (tokenSnap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final token = tokenSnap.data;
          if (token == null) {
            return const Center(child: Text('Token not found'));
          }

          return StreamBuilder<int>(
            stream: queue.streamPeopleAhead(token.id, token.counterId),
            builder: (context, aheadSnap) {
              final peopleAhead = aheadSnap.data ?? 0;
              final waitTime = '${peopleAhead * 5} mins';

              double? dist;
              if (_userPosition != null && token.latitude != 0) {
                dist = LocationService.calculateDistance(
                  _userPosition!.latitude,
                  _userPosition!.longitude,
                  token.latitude,
                  token.longitude,
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TokenDisplayCard(
                      tokenNumber: token.tokenNumber,
                      branchName: token.branchName,
                      peopleAhead: peopleAhead,
                      estimatedWait: waitTime,
                      distanceMeters: dist,
                      onDirectionTap: () => _openDirections(token.latitude, token.longitude),
                    ),
                    const SizedBox(height: 32),
                    _StatusIndicator(status: token.statusLabel),
                    const SizedBox(height: 32),
                    MapDirectionButton(
                      onTap: () => _openDirections(token.latitude, token.longitude),
                    ),
                    const SizedBox(height: 32),
                    if (token.isActive)
                      TextButton.icon(
                        onPressed: () => _showCancelDialog(context, queue, token),
                        icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
                        label: const Text('Cancel Token', style: TextStyle(color: Colors.grey)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, QueueProvider queue, TokenModel token) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Token'),
        content: const Text('Are you sure you want to cancel this token?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          TextButton(
            onPressed: () async {
              await queue.cancelToken(token.id, token.counterId);
              if (context.mounted) {
                Navigator.pop(ctx);
                context.go('/dashboard');
              }
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String status;
  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            'Status: $status',
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}
