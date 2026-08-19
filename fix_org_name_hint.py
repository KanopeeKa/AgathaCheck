import re

with open('flutter_app/lib/features/organization/presentation/widgets/organization_branding_section.dart', 'r') as f:
    content = f.read()

content = content.replace(
"""                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),""",
"""                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: l.organizationName,
                            ),"""
)

with open('flutter_app/lib/features/organization/presentation/widgets/organization_branding_section.dart', 'w') as f:
    f.write(content)
