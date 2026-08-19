import re

with open('flutter_app/lib/features/experience/presentation/screens/experience_resolve_screen.dart', 'r') as f:
    content = f.read()

# Implement Deterministic Landing Rules in experience_resolve_screen.dart
# Has >0 pets ➔ Land on My Pets.
# Has 0 pets AND >0 shelters ➔ Land on Shelters.
# Has 0 pets AND 0 shelters ➔ Land on My Pets (Empty State).

new_navigate = """
  void _navigate(
    BuildContext context,
    WidgetRef ref,
    ExperienceEligibility eligibility,
  ) {
    final pets = ref.read(petListProvider).valueOrNull ?? [];
    final orgs = ref.read(organizationListProvider).valueOrNull ?? [];
    
    // Deterministic Landing Rules:
    // Has >0 pets -> Land on My Pets (/g/home)
    // Has 0 pets AND >0 shelters -> Land on Shelters (/o/home)
    // Has 0 pets AND 0 shelters -> Land on My Pets (/g/home)
    
    String path = '/g/home';
    if (pets.isNotEmpty) {
      path = '/g/home';
    } else if (pets.isEmpty && orgs.isNotEmpty) {
      path = '/o/home';
    } else {
      path = '/g/home';
    }
    
    // Set the active experience based on the path
    import '../../domain/entities/app_experience.dart';
    if (path.startsWith('/o/')) {
      ref.read(activeExperienceProvider.notifier).state = AppExperience.organization;
    } else {
      ref.read(activeExperienceProvider.notifier).state = AppExperience.guardian;
    }

    context.go(path);
  }
"""

# We need to add the import for AppExperience
content = content.replace("import '../../domain/services/experience_eligibility.dart';", "import '../../domain/services/experience_eligibility.dart';\nimport '../../domain/entities/app_experience.dart';")

content = re.sub(r'void _navigate\([^}]+\) \{.*?(?=  @override)', new_navigate, content, flags=re.DOTALL)

with open('flutter_app/lib/features/experience/presentation/screens/experience_resolve_screen.dart', 'w') as f:
    f.write(content)
