#!/bin/bash

# Path to the new changelog entry and the main changelog
ENTRY_FILE="/Users/nick/Desktop/V2/V2/BROWSERBASE_CHANGELOG_ENTRY.md"
CHANGELOG_FILE="/Users/nick/Desktop/V2/V2/CHANGELOG.md"

# Create a temporary file
TMP_FILE=$(mktemp)

# Prepend the new entry to the temporary file
cat "$ENTRY_FILE" > "$TMP_FILE"
echo "" >> "$TMP_FILE"  # Add an empty line for separation
cat "$CHANGELOG_FILE" >> "$TMP_FILE"

# Replace the original changelog with the updated one
mv "$TMP_FILE" "$CHANGELOG_FILE"

echo "Changelog updated successfully!" 