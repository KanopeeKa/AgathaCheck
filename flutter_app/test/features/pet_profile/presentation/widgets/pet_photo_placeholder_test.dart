import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_photo_placeholder.dart';

void main() {
  testWidgets('renders bundled default pet illustration', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 120, height: 120, child: PetPhotoPlaceholder()),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      PetPhotoPlaceholderAssets.defaultPhoto,
    );
  });
}
