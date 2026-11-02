import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/kopsumma_api.dart';
import 'app.dart';
import 'config.dart';

void main() {
  runApp(KopsummaApp(api: HttpKopsummaApi(ApiClient(baseUrl: apiBaseUrl))));
}
