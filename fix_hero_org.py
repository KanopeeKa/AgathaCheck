import re

with open('flutter_app/lib/features/organization/presentation/screens/organization_form_screen.dart', 'r') as f:
    content = f.read()

content = content.replace(
"""  Organization _heroOrg(Organization? loaded) {
    if (loaded != null) return loaded;
    return Organization(
      id: '',
      name: _nameController.text.trim().isEmpty
          ? ' '
          : _nameController.text.trim(),
      type: _selectedType,
    );
  }""",
"""  Organization _heroOrg(Organization? loaded) {
    if (loaded != null) return loaded;
    return Organization(
      id: '',
      name: _nameController.text.trim(),
      type: _selectedType,
    );
  }"""
)

with open('flutter_app/lib/features/organization/presentation/screens/organization_form_screen.dart', 'w') as f:
    f.write(content)
