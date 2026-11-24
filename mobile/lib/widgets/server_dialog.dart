import 'package:flutter/material.dart';

import '../config.dart';
import '../state/app_scope.dart';

/// Servera adrese testēšanai: telefons lokālajā tīklā sasniedz datoru pēc IP (http://192.168.x.x:8000).
Future<void> showServerDialog(BuildContext context) async {
  final services = AppScope.of(context);
  final controller = TextEditingController(text: services.api.serverUrl);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Servera adrese'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Testēšanai telefonā ievadiet datora adresi lokālajā tīklā, piem. http://192.168.1.20:8000'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('server-url'),
            controller: controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, apiBaseUrl), child: const Text('Noklusējums')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Saglabāt')),
      ],
    ),
  );
  controller.dispose();
  if (result == null) return;
  final url = result.trim();
  if (!RegExp(r'^https?://[^\s/]+').hasMatch(url)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresei jāsākas ar http:// vai https://')));
    }
    return;
  }
  services.api.serverUrl = url;
  await services.settings.setServerUrl(url == apiBaseUrl ? null : url);
}
