import re

with open('flutter_app/lib/features/health_tracking/presentation/screens/health_entry_form_screen.dart', 'r') as f:
    content = f.read()

new_case = """      case HealthEntrySubmitValidationFailed():
        // Validation errors are shown in the UI via FormState.validate()
        break;"""

content = re.sub(
    r'      case HealthEntrySubmitValidationFailed\(:final reason\):\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\)\.showSnackBar\(SnackBar\(content: Text\(message\)\)\);',
    new_case,
    content,
    flags=re.DOTALL
)

with open('flutter_app/lib/features/health_tracking/presentation/screens/health_entry_form_screen.dart', 'w') as f:
    f.write(content)
