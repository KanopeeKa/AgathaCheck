#!/bin/bash

# Script to add metadata headers to markdown files
# Usage: ./scripts/add_metadata_headers.sh [--dry-run] [--force]

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
DRY_RUN=false
FORCE=false

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    --force)
      FORCE=true
      ;;
  esac
done

# Function to generate metadata header for a file
generate_header() {
  local filepath="$1"
  local filename=$(basename "$filepath" .md)
  local dirpath=$(dirname "$filepath")
  
  # Extract title from first H1 heading
  local title=$(grep -m 1 '^# ' "$filepath" | sed 's/^# //' | sed 's/^[ \t]*//;s/[ \t]*$//')
  
  # If no H1, use filename with title case
  if [[ -z "$title" ]]; then
    title=$(echo "$filename" | sed 's/-/ /g' | sed 's/\b\w/\u&/g')
  fi
  
  # Determine owner based on directory
  local owner="Documentation Team"
  if [[ "$dirpath" =~ agent-efficiency ]]; then
    owner="Cloud Agents"
  elif [[ "$dirpath" =~ experience-program ]]; then
    owner="Experience Program Team"
  elif [[ "$dirpath" =~ architecture ]]; then
    owner="Architecture Team"
  fi
  
  # Determine audience
  local audience="both"
  if [[ "$filepath" =~ agent-efficiency ]] || [[ "$filepath" =~ AGENTS.md ]]; then
    audience="agent"
  elif [[ "$filepath" =~ CONTRIBUTING.md ]] || [[ "$filepath" =~ README.md ]]; then
    audience="human"
  fi
  
  # Determine status
  local status="active"
  
  # Get last modified date
  local last_updated=$(stat -c %y "$filepath" | cut -d' ' -f1)
  
  # Generate tags based on directory
  local tags="documentation"
  case "$dirpath" in
    */agent-efficiency*) tags="agent,workflow,efficiency" ;;
    */architecture*) tags="architecture,design,domain" ;;
    */design*) tags="design,ui,ux" ;;
    */e2e*) tags="testing,e2e,playwright" ;;
    */experience-program*) tags="experience,guardian,organisation" ;;
    */fostering-platform*) tags="fostering,organisation,adoption" ;;
    */quality*) tags="quality,testing,bdd" ;;
    */ops*) tags="operations,deployment" ;;
    */archived*) tags="archived,historical" ;;
  esac
  
  # For root-level files, determine tags by filename
  if [[ "$dirpath" == "$REPO_ROOT" ]] || [[ "$dirpath" == "." ]]; then
    case "$filename" in
      README) tags="overview,getting-started" ;;
      AGENTS) tags="agent,workflow" ;;
      CONTRIBUTING) tags="contributing,workflow" ;;
      API) tags="api,reference" ;;
      DEPLOYMENT_*) tags="deployment,operations" ;;
      replit) tags="development,environment" ;;
    esac
  fi
  
  # Build the header
  echo "---"
  echo "title: $title"
  echo "owner: $owner"
  echo "audience: $audience"
  echo "status: $status"
  echo "last_updated: $last_updated"
  echo "tags: [$tags]"
  echo "---"
  echo ""
}

# Function to add header to a file
add_header_to_file() {
  local filepath="$1"
  
  # Skip if file already has a header
  if grep -q '^---$' "$filepath"; then
    if [[ "$FORCE" == true ]]; then
      echo "✏️  Forcing update: $filepath"
      # Remove existing header (from --- to ---)
      local tmpfile=$(mktemp)
      local in_header=false
      while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
          if [[ "$in_header" == false ]]; then
            in_header=true
            continue
          else
            in_header=false
            continue
          fi
        fi
        if [[ "$in_header" == false ]]; then
          echo "$line" >> "$tmpfile"
        fi
      done < "$filepath"
      mv "$tmpfile" "$filepath"
      
      # Generate and prepend new header
      local header=$(generate_header "$filepath")
      local tmpfile2=$(mktemp)
      echo "$header" > "$tmpfile2"
      cat "$filepath" >> "$tmpfile2"
      mv "$tmpfile2" "$filepath"
      echo "✅ Updated header: $filepath"
    else
      echo "✅ Already has header: $filepath"
      return 0
    fi
  else
    # Generate header
    local header=$(generate_header "$filepath")
    
    if [[ "$DRY_RUN" == true ]]; then
      echo "📝 Would add header to: $filepath"
      echo "$header"
      return 0
    fi
    
    # Create temp file
    local tmpfile=$(mktemp)
    
    # Write header + original content
    echo "$header" > "$tmpfile"
    cat "$filepath" >> "$tmpfile"
    
    # Replace original
    mv "$tmpfile" "$filepath"
    
    echo "✅ Added header to: $filepath"
  fi
}

# Function to process a directory
handle_directory() {
  local dir="$1"
  
  find "$dir" -name "*.md" -type f | while read -r filepath; do
    # Skip certain files/directories
    if [[ "$filepath" =~ \.git/ ]] || [[ "$filepath" =~ node_modules/ ]] || \
       [[ "$filepath" =~ artifacts/ ]] || [[ "$filepath" =~ \.agents/ ]] || \
       [[ "$filepath" =~ \.cursor/ ]]; then
      continue
    fi
    
    add_header_to_file "$filepath"
  done
}

echo "🚀 Starting metadata header addition..."
echo "Repository root: $REPO_ROOT"
echo "Dry run: $DRY_RUN"
echo "Force: $FORCE"
echo ""

# Process docs/ directory
echo "📁 Processing docs/ directory..."
handle_directory "$REPO_ROOT/docs"

# Process root markdown files
echo ""
echo "📁 Processing root directory..."
for file in "$REPO_ROOT"/*.md; do
  if [[ -f "$file" ]]; then
    add_header_to_file "$file"
  fi
done

# Process e2e/ directory
echo ""
echo "📁 Processing e2e/ directory..."
handle_directory "$REPO_ROOT/e2e"

echo ""
echo "✨ Metadata header addition complete!"

if [[ "$DRY_RUN" == true ]]; then
  echo ""
  echo "💡 This was a dry run. No files were modified."
  echo "   Run without --dry-run to apply changes."
fi
