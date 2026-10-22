import 'package:flutter_test/flutter_test.dart';
import 'package:zen_wizard/main.dart';

void main() {
  testWidgets('ZenWizard UI loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ZenWizardApp());

    // Verify that the Home Screen header and Pomodoro timer are displayed.
    expect(find.text('Workspace Status'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
  });
}