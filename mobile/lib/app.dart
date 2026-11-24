import 'package:flutter/material.dart';

import 'api/kopsumma_api.dart';
import 'routes.dart';
import 'state/app_scope.dart';
import 'theme/app_theme.dart';

class KopsummaApp extends StatelessWidget {
  KopsummaApp({super.key, KopsummaApi? api, AppServices? services, this.initialRoute = Routes.start, this.fontFamily})
      : services = services ?? AppServices(api: api!);

  final AppServices services;
  final String initialRoute;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: MaterialApp(
        title: 'Kopsumma',
        theme: buildTheme(fontFamily: fontFamily),
        debugShowCheckedModeBanner: false,
        initialRoute: initialRoute,
        onGenerateRoute: Routes.generate,
      ),
    );
  }
}
