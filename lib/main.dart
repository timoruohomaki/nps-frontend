import 'package:flutter/material.dart';

import 'api/feedback_client.dart';
import 'config.dart';
import 'device_context.dart';
import 'screens/nps_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig.fromEnvironment;
  final device = await DeviceContext.resolve();
  final client = FeedbackClient(config);

  runApp(NpsApp(config: config, device: device, client: client));
}

class NpsApp extends StatelessWidget {
  const NpsApp({
    super.key,
    required this.config,
    required this.device,
    required this.client,
  });

  final AppConfig config;
  final DeviceContext device;
  final FeedbackClient client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NPS Feedback',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: NpsScreen(config: config, device: device, client: client),
    );
  }
}
