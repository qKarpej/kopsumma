import 'package:flutter/material.dart';

import 'api/kopsumma_api.dart';
import 'routes.dart';
import 'state/app_scope.dart';
import 'theme/app_theme.dart';

class KopsummaApp extends StatelessWidget {
  const KopsummaApp({super.key, required this.api, this.initialRoute = Routes.start, this.fontFamily});

  final KopsummaApi api;
  final String initialRoute;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      api: api,
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
