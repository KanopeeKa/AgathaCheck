import json
import re

def replace_text(text):
    if not isinstance(text, str):
        return text
    
    # Gardien -> Mes Animaux
    text = re.sub(r'\bGardien\b', 'Mes Animaux', text)
    text = re.sub(r'\bgardien\b', 'mes animaux', text)
    text = re.sub(r'\bgardiens\b', 'mes animaux', text)
    text = re.sub(r'\bGardiens\b', 'Mes Animaux', text)
    
    # Organisation -> Refuges
    text = re.sub(r'\bOrganisation\b', 'Refuge', text)
    text = re.sub(r'\borganisation\b', 'refuge', text)
    text = re.sub(r'\bOrganisations\b', 'Refuges', text)
    text = re.sub(r'\borganisations\b', 'refuges', text)
    
    return text

with open('flutter_app/lib/l10n/app_fr.arb', 'r') as f:
    data = json.load(f)
    
for k, v in data.items():
    if k.startswith('@'): continue
    new_v = replace_text(v)
    if "animal mes animaux" in new_v.lower():
        new_v = new_v.replace("animal mes animaux", "propriétaire").replace("Animal Mes Animaux", "Propriétaire")
    if "mes animaux d'animal" in new_v.lower():
        new_v = new_v.replace("mes animaux d'animal", "mes animaux").replace("Mes Animaux d'animal", "Mes Animaux")
    if "mes animaux d'animaux" in new_v.lower():
        new_v = new_v.replace("mes animaux d'animaux", "propriétaires d'animaux").replace("Mes Animaux d'animaux", "Propriétaires d'animaux")
    data[k] = new_v
    
with open('flutter_app/lib/l10n/app_fr.arb', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
