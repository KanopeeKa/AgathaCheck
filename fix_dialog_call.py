import re

with open('flutter_app/lib/features/pet_profile/presentation/screens/pet_form_screen.dart', 'r') as f:
    content = f.read()

content = content.replace(
"""  Future<void> _confirmDeletePet() async {
    if (widget.petId == null) return;
    await confirmDeletePet(
      context: context,
      ref: ref,
      petId: widget.petId!,""",
"""  Future<void> _confirmDeletePet() async {
    if (widget.petId == null) return;
    await confirmDeletePet(
      context: context,
      ref: ref,
      petId: widget.petId!,
      petName: _nameController.text.trim(),"""
)

with open('flutter_app/lib/features/pet_profile/presentation/screens/pet_form_screen.dart', 'w') as f:
    f.write(content)
