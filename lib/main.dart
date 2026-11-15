import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'adapters/workmanager/workmanager_scheduler.dart';
import 'application/providers.dart';
import 'background.dart';
import 'presentation/app.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        backgroundSchedulerProvider.overrideWithValue(
          WorkmanagerScheduler(callbackDispatcher),
        ),
      ],
      child: const MiraiCookApp(),
    ),
  );
}
