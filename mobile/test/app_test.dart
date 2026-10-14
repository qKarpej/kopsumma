import 'package:flutter_test/flutter_test.dart';
import 'package:kopsumma/main.dart';

void main() {
  testWidgets('lietotne startē', (tester) async {
    await tester.pumpWidget(const KopsummaApp());
    expect(find.text('Kopsumma'), findsOneWidget);
  });
}
