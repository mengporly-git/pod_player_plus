import 'package:example/screens/from_asset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pod_player_plus/pod_player_plus.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initializes and displays an asset video', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlayVideoFromAsset()),
    );

    for (var attempt = 0; attempt < 40; attempt++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(VideoPlayer).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(tester.takeException(), isNull);
    expect(find.byType(VideoPlayer), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
