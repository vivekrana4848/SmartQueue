import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/queue_provider.dart';
import '../../providers/token_provider.dart';
import '../../providers/auth_provider.dart';

class TokenFormScreen extends StatelessWidget {
  const TokenFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = Provider.of<QueueProvider>(context);
    final tokenProvider = Provider.of<TokenProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final s = queue.selectedSector;
    final b = queue.selectedBranch;
    final ser = queue.selectedService;

    if (s == null || b == null || ser == null) return const Scaffold(body: Center(child: Text('Incomplete selection')));

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Token')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildInfo('Sector', s.name),
            _buildInfo('Branch', b.name),
            _buildInfo('Service', ser.name),
            const Divider(height: 48),
            const Text('Estimated Wait Time', style: TextStyle(color: Colors.grey)),
            Text('${ser.avgWaitMinutes} mins', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            tokenProvider.isGenerating 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () async {
                    final token = await tokenProvider.generateToken(
                      userId: auth.user!.uid,
                      userName: auth.user!.email ?? 'User',
                      sector: s,
                      branch: b,
                      service: ser,
                    );
                    if (token != null && context.mounted) {
                      context.pushReplacement('/dashboard/queue/${token.id}');
                    }
                  }, 
                  child: const Text('Generate Token')
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
