import json
import re

def replace_text(text):
    if not isinstance(text, str):
        return text
    
    # Guardian -> My Pets
    text = re.sub(r'\bGuardian\b', 'My Pets', text)
    text = re.sub(r'\bguardian\b', 'my pets', text)
    
    # Organisations / Organizations -> Shelters
    text = re.sub(r'\bOrganisations\b', 'Shelters', text)
    text = re.sub(r'\borganisations\b', 'shelters', text)
    text = re.sub(r'\bOrganizations\b', 'Shelters', text)
    text = re.sub(r'\borganizations\b', 'shelters', text)
    
    # Organisation / Organization -> Shelter
    text = re.sub(r'\bOrganisation\b', 'Shelter', text)
    text = re.sub(r'\borganisation\b', 'shelter', text)
    text = re.sub(r'\bOrganization\b', 'Shelter', text)
    text = re.sub(r'\borganization\b', 'shelter', text)
    
    return text

for filename in ['flutter_app/lib/l10n/app_en.arb', 'flutter_app/lib/l10n/app_fr.arb']:
    with open(filename, 'r') as f:
        data = json.load(f)
        
    for k, v in data.items():
        if k.startswith('@'): continue
        # Only replace if the key is related to UI tabs or general usage
        # Actually, let's just replace all and see if there's any weirdness.
        # "You are the pet my pets" is weird.
        # Let's fix specific weird ones.
        new_v = replace_text(v)
        if "pet my pets" in new_v.lower():
            new_v = new_v.replace("pet my pets", "pet owner").replace("Pet My Pets", "Pet Owner")
        if "my pets name" in new_v.lower():
            new_v = new_v.replace("my pets name", "owner name").replace("My Pets name", "Owner name")
        data[k] = new_v
        
    with open(filename, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
