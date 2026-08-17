import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/bootstrap/bootstrap.dart';
import 'core/config/env_config.dart';

void main() async {
  // Determine environment from build args or default to dev
  final container = await Bootstrap.createContainer(
    config: EnvConfig.dev(), // Future: load from --dart-define
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const PlayHubApp()),
  );
}
