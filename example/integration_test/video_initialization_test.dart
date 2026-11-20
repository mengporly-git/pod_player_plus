import 'package:example/screens/from_asset.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pod_player_plus/pod_player_plus.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initializes an asset video and opens player settings', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PlayVideoFromAsset()));

    for (var attempt = 0; attempt < 40; attempt++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(VideoPlayer).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(tester.takeException(), isNull);
    expect(find.byType(VideoPlayer), findsOneWidget);

    final settings = find.byIcon(Icons.more_vert_rounded);
    expect(settings, findsOneWidget);
    await tester.tap(settings);
    await tester.pumpAndSettle();
    expect(find.text('PLAYBACK SPEED'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
