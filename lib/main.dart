import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/bootstrap/bootstrap.dart';
import 'core/config/env_config.dart';

void main() async {
  // Determine environment from build args
  final container = await Bootstrap.createContainer(
    config: EnvConfig.fromEnvironment(),
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const PlayHubApp()),
  );
}
