import re

with open('flutter_app/lib/features/experience/presentation/screens/experience_resolve_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("import '../../domain/services/experience_eligibility.dart';", "import '../../domain/services/experience_eligibility.dart';\nimport '../../domain/entities/app_experience.dart';")

with open('flutter_app/lib/features/experience/presentation/screens/experience_resolve_screen.dart', 'w') as f:
    f.write(content)
