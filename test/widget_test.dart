import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kboom/main.dart';
import 'package:kboom/models/avatar_model.dart';
import 'package:kboom/widgets/avatar_widget.dart';

void main() {
  testWidgets('launches the splash screen with the app title', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('KBOOM'), findsOneWidget);
  });

  testWidgets('renders a background image when a background asset is selected', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvatarWidget(
            avatarData: const AvatarData(backgroundId: 'deer_background'),
            size: 160,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
