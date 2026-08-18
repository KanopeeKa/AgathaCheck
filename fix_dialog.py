import re

with open('flutter_app/lib/features/pet_profile/presentation/widgets/pet_form/pet_form_confirm_dialogs.dart', 'r') as f:
    content = f.read()

# We need to pass petName to confirmDeletePet and use it in l.deletePetConfirm(petName)
content = content.replace(
"""Future<void> confirmDeletePet({
  required BuildContext context,
  required WidgetRef ref,
  required String petId,""",
"""Future<void> confirmDeletePet({
  required BuildContext context,
  required WidgetRef ref,
  required String petId,
  required String petName,"""
)

content = content.replace("content: Text(l.deletePetConfirm('')),", "content: Text(l.deletePetConfirm(petName)),")

with open('flutter_app/lib/features/pet_profile/presentation/widgets/pet_form/pet_form_confirm_dialogs.dart', 'w') as f:
    f.write(content)
