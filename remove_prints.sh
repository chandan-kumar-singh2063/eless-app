#!/bin/bash

# Script to remove debug print statements from Dart files

# Find all Dart files and remove print/debugPrint statements
find lib -name "*.dart" -type f | while read -r file; do
    # Create backup
    cp "$file" "$file.bak"
    
    # Remove lines with print( or debugPrint(
    sed -i '' '/^\s*print(/d' "$file"
    sed -i '' '/^\s*debugPrint(/d' "$file"
    
    # Remove lines that are just closing parentheses/semicolons from multiline prints
    # This is tricky, so we'll handle it carefully
    
    echo "Processed: $file"
done

echo "Done! Backups created with .bak extension"
