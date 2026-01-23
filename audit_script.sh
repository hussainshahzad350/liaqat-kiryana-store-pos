#!/bin/bash
set -e

# Find all repository files in the entire lib directory
REPOS=$(find lib -name "*repository.dart")

# Loop through each repository file
for repo in $REPOS; do
  echo ""
  echo "================================================="
  echo "🔍 Auditing Repository: $repo"
  echo "================================================="

  # Improved regex to capture more function definitions.
  # This looks for a pattern resembling a return type followed by a function name and parentheses.
  functions=$(grep -E '^[ \t]*[a-zA-Z<>?,_\[\]]+\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\(' "$repo" | \
              sed -E 's/.* ([a-zA-Z_][a-zA-Z0-9_]+)\s*\(.*/\1/' | \
              sort -u)

  if [ -z "$functions" ]; then
    echo "No functions found in $repo. Skipping."
    continue
  fi

  # Audit each function
  for func in $functions; do
    # Use -w for whole word search to avoid partial matches
    search_results=$(grep -rw --exclude-dir={lib/l10n,build} "$func" lib 2>/dev/null || true)

    # Count total occurrences
    total_count=$(echo "$search_results" | wc -l)

    # Count unique files where it's used, excluding the definition file itself.
    usage_count=$(echo "$search_results" | cut -d: -f1 | sort -u | grep -v -c "$repo" || true)

    if [ "$total_count" -le 1 ]; then
      echo "❌ [Unused]       - $func"
    elif [ "$usage_count" -eq 0 ]; then
      echo "🔵 [Internal Use] - $func"
    else
      # Find unique file paths where the function is used (excluding the repo itself)
      usage_files=$(echo "$search_results" | cut -d: -f1 | sort -u | grep -v "$repo" | tr '\n' ',' | sed 's/,$//')
      echo "✅ [Used]         - $func (in: $usage_files)"
    fi
  done
done
