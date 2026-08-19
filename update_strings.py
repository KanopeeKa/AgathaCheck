import json

def update_dict(d):
    for k, v in d.items():
        if isinstance(v, str):
            # Guardian -> My Pets
            # guardian -> my pets
            # Organisation -> Shelters
            # organisation -> shelters
            # Organization -> Shelters
            # organization -> shelters
            if k.startswith('@'): continue
            
            # We want to be careful not to break placeholders like {guardianName}
            # Let's just do simple replacements for the exact words or common phrases.
            
            # Actually, let's just replace the specific keys that represent the global UI tabs/sections if possible.
            # But the instruction says "Update global UI strings: Guardian ➔ My Pets, Organisation ➔ Shelters."
            pass

with open('flutter_app/lib/l10n/app_en.arb', 'r') as f:
    data = json.load(f)

print("Guardian keys:")
for k, v in data.items():
    if isinstance(v, str) and 'Guardian' in v or 'guardian' in v:
        print(f"{k}: {v}")
        
print("\nOrganisation keys:")
for k, v in data.items():
    if isinstance(v, str) and ('Organisation' in v or 'organisation' in v or 'Organization' in v or 'organization' in v):
        print(f"{k}: {v}")
